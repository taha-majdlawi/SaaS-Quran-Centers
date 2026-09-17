import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { startCheckout } from './actions';

interface PlanRow {
  id: string;
  code: string;
  name: string;
  price_cents: number;
  currency: string;
}

interface SubscriptionRow {
  status: string;
  current_period_end: string | null;
  plans: { name: string } | null;
}

const STATUS_LABELS: Record<string, string> = {
  trialing: 'تجريبي',
  active: 'نشط',
  past_due: 'متأخر السداد',
  cancelled: 'ملغى',
};

export default async function BillingPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string; success?: string; canceled?: string }>;
}) {
  const { org: slug } = await params;
  const { error, success, canceled } = await searchParams;
  const org = await getOrgContext(slug);
  const isAdmin = org.myRole === 'admin';
  const supabase = await createClient();

  const [{ data: plans }, { data: subscription }] = await Promise.all([
    supabase.from('plans').select('id, code, name, price_cents, currency').eq('is_active', true).order('price_cents'),
    supabase
      .from('subscriptions')
      .select('status, current_period_end, plans(name)')
      .eq('organization_id', org.id)
      .maybeSingle<SubscriptionRow>(),
  ]);

  return (
    <div className="max-w-lg">
      <h1 className="mb-1 text-2xl font-bold">الفوترة والاشتراك</h1>
      <p className="mb-6 text-sm text-gray-500">خطة مركزك الحالية وترقيتها.</p>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {success && (
        <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">
          تم الدفع بنجاح - قد يستغرق تفعيل الاشتراك بضع لحظات.
        </p>
      )}
      {canceled && <p className="mb-4 rounded bg-yellow-50 px-3 py-2 text-sm text-yellow-700">تم إلغاء عملية الدفع.</p>}

      <div className="mb-6 rounded-lg border bg-white p-6">
        <h2 className="mb-2 text-sm font-semibold text-gray-600">الاشتراك الحالي</h2>
        {subscription ? (
          <div className="text-sm">
            <p className="font-medium">{subscription.plans?.name ?? '—'}</p>
            <p className="text-gray-500">
              الحالة: {STATUS_LABELS[subscription.status] ?? subscription.status}
              {subscription.current_period_end &&
                ` - ينتهي ${new Date(subscription.current_period_end).toLocaleDateString('ar')}`}
            </p>
          </div>
        ) : (
          <p className="text-sm text-gray-400">لا يوجد اشتراك فعّال حاليًا.</p>
        )}
      </div>

      {isAdmin ? (
        <div className="flex flex-col gap-3">
          {(plans ?? []).map((plan: PlanRow) => (
            <form
              key={plan.id}
              action={startCheckout}
              className="flex items-center justify-between rounded-lg border bg-white p-4"
            >
              <input type="hidden" name="orgId" value={org.id} />
              <input type="hidden" name="planId" value={plan.id} />
              <div>
                <p className="font-semibold">{plan.name}</p>
                <p className="text-sm text-gray-500" dir="ltr">
                  {(plan.price_cents / 100).toFixed(2)} {plan.currency}/شهريًا
                </p>
              </div>
              <SubmitButton
                className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
                pendingText="جاري التحويل..."
              >
                {subscription?.plans?.name === plan.name ? 'تجديد' : 'اشترك'}
              </SubmitButton>
            </form>
          ))}
          {!plans?.length && (
            <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا توجد خطط متاحة بعد.</p>
          )}
        </div>
      ) : (
        <p className="text-xs text-gray-400">بس المدير يقدر يدير اشتراك المركز.</p>
      )}
    </div>
  );
}
