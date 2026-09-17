'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { createStripeClient } from '@/lib/stripe/client';

// Same re-derivation pattern as teachers/actions.ts's updateTeacherAccount:
// the only thing this form proves is that the caller is signed in and
// clicked a button - the admin check and the plan's real price both need to
// come from a server-side, RLS-protected read, never trusted from the form,
// since this ultimately decides what a real card gets charged.
export async function startCheckout(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const planId = formData.get('planId') as string;

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: membership } = await supabase
    .from('organization_members')
    .select('role')
    .eq('organization_id', orgId)
    .eq('user_id', user?.id ?? '')
    .eq('status', 'active')
    .maybeSingle();

  if (membership?.role !== 'admin') {
    redirect(`/billing?error=${encodeURIComponent('غير مصرح لك بهذا الإجراء')}` as never);
  }

  // The slug drives success_url/cancel_url below - re-derived from orgId
  // (already proven to be an org the caller admins, above) rather than
  // trusted from a hidden form field, so it can't be tampered with to
  // point the post-checkout redirect at a different subdomain.
  const { data: orgRow } = await supabase.from('organizations').select('slug').eq('id', orgId).maybeSingle();
  const orgSlug = orgRow?.slug;
  if (!orgSlug) {
    redirect(`/billing?error=${encodeURIComponent('مركز غير موجود')}` as never);
  }

  const { data: plan } = await supabase
    .from('plans')
    .select('id, name, price_cents, currency, is_active')
    .eq('id', planId)
    .eq('is_active', true)
    .maybeSingle();

  if (!plan) {
    redirect(`/billing?error=${encodeURIComponent('خطة غير متاحة')}` as never);
  }

  const rootDomain = process.env.NEXT_PUBLIC_ROOT_DOMAIN;
  const baseUrl = `https://${orgSlug}.${rootDomain}`;

  const stripe = createStripeClient();
  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    client_reference_id: orgId,
    metadata: { organization_id: orgId, plan_id: plan.id },
    subscription_data: { metadata: { organization_id: orgId, plan_id: plan.id } },
    line_items: [
      {
        price_data: {
          currency: plan.currency.toLowerCase(),
          product_data: { name: `${plan.name} - بستان القرآن` },
          unit_amount: plan.price_cents,
          recurring: { interval: 'month' },
        },
        quantity: 1,
      },
    ],
    success_url: `${baseUrl}/billing?success=1`,
    cancel_url: `${baseUrl}/billing?canceled=1`,
  });

  if (!session.url) {
    redirect(`/billing?error=${encodeURIComponent('تعذر بدء عملية الدفع')}` as never);
  }

  redirect(session.url as never);
}
