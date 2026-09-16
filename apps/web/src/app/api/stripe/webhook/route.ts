import { NextRequest, NextResponse } from 'next/server';
import Stripe from 'stripe';
import { createStripeClient } from '@/lib/stripe/client';
import { createAdminClient } from '@/lib/supabase/admin';

// Not under (marketing)/(tenant)/(platform) - reached directly at
// bustan-alquran.com/api/stripe/webhook regardless of subdomain, and
// middleware.ts's matcher excludes /api entirely, so this never goes
// through the tenant-rewrite or session-backstop logic. Authenticated
// purely by the Stripe-Signature header below, not a Supabase session -
// Stripe itself is the caller, not a logged-in user.
//
// Writes to `subscriptions` through the service-role client because its
// only RLS write policy is is_platform_owner() (migration 0001) - correct,
// since an org admin must never be able to set their own subscription
// status directly. This is the one place that's supposed to bypass it.
export async function POST(req: NextRequest) {
  const signature = req.headers.get('stripe-signature');
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  if (!signature || !webhookSecret) {
    return NextResponse.json({ error: 'missing signature or webhook secret' }, { status: 400 });
  }

  const body = await req.text();
  const stripe = createStripeClient();

  let event: Stripe.Event;
  try {
    // Async variant - uses SubtleCrypto rather than Node's `crypto` module,
    // which is what actually works reliably under the Workers runtime.
    event = await stripe.webhooks.constructEventAsync(body, signature, webhookSecret);
  } catch (err) {
    return NextResponse.json({ error: `invalid signature: ${(err as Error).message}` }, { status: 400 });
  }

  const admin = createAdminClient();

  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session;
      const organizationId = session.client_reference_id ?? session.metadata?.organization_id;
      const planId = session.metadata?.plan_id;
      const customerId = typeof session.customer === 'string' ? session.customer : session.customer?.id;
      const subscriptionId =
        typeof session.subscription === 'string' ? session.subscription : session.subscription?.id;

      if (!organizationId || !planId || !subscriptionId) break;

      await admin.from('subscriptions').upsert(
        {
          organization_id: organizationId,
          plan_id: planId,
          billing_provider: 'stripe',
          external_customer_id: customerId,
          external_subscription_id: subscriptionId,
          status: 'active',
        },
        { onConflict: 'organization_id' },
      );
      break;
    }

    // Recurring renewals, plan changes, payment failures, and cancellations
    // all land here - status/current_period_end tracks Stripe's own state
    // exactly rather than us re-deriving it. Looked up by subscription id
    // (set above), not metadata, since Stripe doesn't guarantee metadata
    // is still attached by the time a later event fires.
    case 'customer.subscription.updated':
    case 'customer.subscription.deleted': {
      const subscription = event.data.object as Stripe.Subscription;
      const status = mapStripeStatus(subscription.status);
      const currentPeriodEnd = subscription.items.data[0]?.current_period_end;

      await admin
        .from('subscriptions')
        .update({
          status,
          current_period_end: currentPeriodEnd ? new Date(currentPeriodEnd * 1000).toISOString() : null,
        })
        .eq('external_subscription_id', subscription.id);
      break;
    }

    default:
      break;
  }

  return NextResponse.json({ received: true });
}

function mapStripeStatus(stripeStatus: Stripe.Subscription.Status): 'trialing' | 'active' | 'past_due' | 'cancelled' {
  switch (stripeStatus) {
    case 'trialing':
      return 'trialing';
    case 'active':
      return 'active';
    case 'past_due':
    case 'unpaid':
    case 'incomplete':
      return 'past_due';
    default:
      // canceled, incomplete_expired, paused
      return 'cancelled';
  }
}
