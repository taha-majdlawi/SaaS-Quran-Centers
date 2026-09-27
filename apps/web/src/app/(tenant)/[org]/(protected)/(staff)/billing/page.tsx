import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { cancelPayment, submitPayment } from '@/lib/billing/actions';
import {
  METHOD_LABELS,
  PERIOD_LABELS,
  REQUEST_STATUS,
  REQUEST_STYLES,
  STATE_LABELS,
  UPGRADE_CTA,
  countText,
  gardenStage,
  fmtDay,
  money,
  type BillingPlan,
  type BillingRequest,
  type BillingState,
  type Usage,
} from '@/lib/billing/format';

interface Overview {
  billing: BillingState;
  usage: Usage;
  org_status: string;
  current_plan: { id: string; name: string } | null;
  plans: BillingPlan[];
  instructions: string | null;
  requests: BillingRequest[];
}

const OK: Record<string, string> = {
  submitted: 'وصل إشعار الدفع ✓ — سيُسقى بستانك ويُفعَّل الاشتراك فور تأكيد إدارة المنصة استلام المبلغ 💧',
  cancelled: 'أُلغي إشعار الدفع',
};
const input = 'mt-1 w-full rounded border px-3 py-2 text-sm';

// Billing phase 1: the center pays by transfer / wallet / cash and reports it
// here; the platform owner confirms it (migration 0066). Works even while the
// center is locked for non-payment - that is how it gets unlocked.
export default async function BillingPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ ok?: string; error?: string }>;
}) {
  const { org: slug } = await params;
  const { ok, error } = await searchParams;
  const org = await getOrgContext(slug);
  if (org.myRole !== 'admin') redirect('/dashboard' as never);
  const supabase = await createClient();
  const { data, error: loadError } = await supabase.rpc('billing_overview', { p_org: org.id });
  const o = data as Overview | null;

  if (!o) return <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{loadError?.message ?? 'تعذّر تحميل الاشتراك'}</p>;
  const b = o.billing;
  const pending = o.requests.find((r) => r.status === 'pending');
  const payable = o.plans.filter((p) => !p.is_free);

  return (
    <div className="flex max-w-3xl flex-col gap-5">
      <h1 className="text-2xl font-bold">الاشتراك والدفع</h1>
      {ok && OK[ok] && <p className="rounded bg-green-50 px-3 py-2 text-sm text-green-700">{OK[ok]}</p>}
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <section className={`rounded-lg border p-5 ${b.locked ? 'border-red-200 bg-red-50' : 'bg-white'}`}>
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <p className="text-sm text-gray-500">الخطة الحالية</p>
            <p className="text-xl font-bold">{o.current_plan?.name ?? 'بدون خطة'}</p>
          </div>
          <span
            className={`rounded-full px-3 py-1 text-sm font-semibold ${
              b.locked || b.state === 'grace' ? 'bg-red-100 text-red-700' : b.state === 'trial' ? 'bg-amber-100 text-amber-800' : 'bg-green-100 text-green-700'
            }`}
          >
            {STATE_LABELS[b.state] ?? b.state}
          </span>
        </div>
        {b.until && (
          <p className="mt-3 text-sm">
            {b.state === 'trial' ? 'تنتهي الفترة التجريبية' : b.state === 'active' ? 'الاشتراك ساري حتى' : 'انتهى في'} <b>{fmtDay(b.until)}</b>
            {b.days_left != null && b.days_left > 0 && <span className="text-gray-500"> (باقي {countText(b.days_left, 'يوم', 'يومان', 'أيام')})</span>}
          </p>
        )}
        {b.state === 'grace' && b.enforced && (
          <p className="mt-2 text-sm text-red-700">يتحول المركز للقراءة فقط في {fmtDay(b.grace_ends)} إن لم يُجدَّد الاشتراك.</p>
        )}
        {b.state === 'free' && (
          <p className="mt-3 text-sm text-gray-600">🌱 بذرتك مغروسة على الخطة المجانية بحدودها — اسقِها بخطة أكبر لتتسع لمزيد من الطلاب والمعلمين.</p>
        )}
        {b.locked && (
          <p className="mt-2 text-sm font-semibold text-red-700">
            المركز الآن للقراءة فقط: كل البيانات ظاهرة، لكن لا يمكن إضافة أو تعديل شيء حتى يُؤكَّد الدفع.
          </p>
        )}
      </section>

      <section className="grid gap-3 sm:grid-cols-2">
        <UsageMeter label="الطلاب" used={o.usage.students} max={o.usage.max_students} left={o.usage.students_left} unit={['طالب', 'طالبان', 'طلاب']} warnAt={5} />
        <UsageMeter label="المعلمون" used={o.usage.teachers} max={o.usage.max_teachers} left={o.usage.teachers_left} unit={['معلم', 'معلمان', 'معلمين']} warnAt={1} />
      </section>

      {pending && (
        <section className="rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm">
          <p className="font-bold">إشعار دفع بانتظار التأكيد</p>
          <p className="mt-1">
            {pending.plan} · {PERIOD_LABELS[pending.period]} · {money(pending.amount_cents, pending.currency)} · {METHOD_LABELS[pending.method] ?? pending.method}
            {pending.reference && <span dir="ltr"> · {pending.reference}</span>}
          </p>
          <p className="mt-1 text-gray-600">أُرسل {fmtDay(pending.created_at)} — سيُفعَّل الاشتراك تلقائيًا فور تأكيد استلام المبلغ.</p>
          <form action={cancelPayment} className="mt-2">
            <input type="hidden" name="id" value={pending.id} />
            <SubmitButton className="text-xs text-red-600 hover:underline" pendingText="...">
              إلغاء هذا الإشعار
            </SubmitButton>
          </form>
        </section>
      )}

      <section>
        <h2 className="mb-1 font-semibold">مراحل البستان</h2>
        <p className="mb-3 text-xs text-gray-500">من البذرة إلى البستان — اختر المرحلة التي تناسب مركزك، وانتقل للأكبر متى كبر.</p>
        {o.plans.length ? (
          <div className="grid gap-3 sm:grid-cols-2">
            {o.plans.map((p, i) => (
              <div key={p.id} className={`rounded-lg border bg-white p-4 text-sm ${o.current_plan?.id === p.id ? 'border-brand' : ''}`}>
                <p className="text-base font-bold">
                  {gardenStage(i).icon} {p.name}
                  {o.current_plan?.id === p.id && <span className="ms-2 rounded-full bg-brand/10 px-2 py-0.5 text-xs text-brand">خطتك الحالية</span>}
                </p>
                <p className="mt-0.5 text-xs text-gray-500">{gardenStage(i).tagline}</p>
                {p.is_free ? (
                  <p className="mt-1 font-bold text-green-700">مجانًا</p>
                ) : (
                <p className="mt-1">
                  <b>{money(p.price_cents, p.currency)}</b> <span className="text-gray-500">/ شهر</span>
                </p>
                )}
                {!p.is_free && p.yearly_price_cents != null && (
                  <p>
                    <b>{money(p.yearly_price_cents, p.currency)}</b> <span className="text-gray-500">/ سنة</span>
                    {p.yearly_price_cents < p.price_cents * 12 && (
                      <span className="ms-2 rounded bg-green-50 px-1.5 py-0.5 text-xs text-green-700">
                        وفّر {Math.round((1 - p.yearly_price_cents / (p.price_cents * 12)) * 100)}%
                      </span>
                    )}
                  </p>
                )}
                <p className="mt-2 text-xs text-gray-500">
                  {p.limits?.max_students != null ? `حتى ${p.limits.max_students} طالب` : 'طلاب بلا حد'} ·{' '}
                  {p.limits?.max_teachers != null ? `حتى ${p.limits.max_teachers} معلم` : 'معلمون بلا حد'}
                </p>
              </div>
            ))}
          </div>
        ) : (
          <p className="rounded-lg border bg-white p-4 text-sm text-gray-500">لم تُنشَر خطط بعد — تواصل مع إدارة المنصة.</p>
        )}
      </section>

      {o.instructions && (
        <section className="rounded-lg border bg-white p-4 text-sm">
          <h2 className="mb-2 font-semibold">طريقة الدفع</h2>
          <p className="whitespace-pre-line leading-7">{o.instructions}</p>
        </section>
      )}

      {!pending && payable.length > 0 && (
        <section className="rounded-lg border bg-white p-4">
          <h2 className="mb-1 font-semibold">💧 سقيتَ بستانك؟ أبلغنا بدفعتك</h2>
          <p className="mb-3 text-xs text-gray-500">بعد التحويل أو الدفع، املأ هذا النموذج ليُفعَّل الاشتراك فور تأكيد الاستلام.</p>
          <form action={submitPayment} className="grid gap-3 sm:grid-cols-2">
            <input type="hidden" name="orgId" value={org.id} />
            <label className="text-sm">
              الخطة
              <select name="plan" required defaultValue={payable.some((p) => p.id === o.current_plan?.id) ? o.current_plan?.id : payable[0].id} className={input}>
                {payable.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="text-sm">
              المدة
              <select name="period" defaultValue="yearly" className={input}>
                <option value="yearly">سنوي</option>
                <option value="monthly">شهري</option>
              </select>
            </label>
            <label className="text-sm">
              طريقة الدفع
              <select name="method" defaultValue="bank_transfer" className={input}>
                {Object.entries(METHOD_LABELS).map(([k, l]) => (
                  <option key={k} value={k}>
                    {l}
                  </option>
                ))}
              </select>
            </label>
            <label className="text-sm">
              رقم الحوالة / المرجع (اختياري)
              <input name="reference" maxLength={120} dir="ltr" className={input} />
            </label>
            <label className="text-sm sm:col-span-2">
              ملاحظة (اختياري)
              <textarea name="note" maxLength={500} rows={2} className={input} />
            </label>
            <div className="sm:col-span-2">
              <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText="جاري الإرسال...">
                إرسال إشعار الدفع
              </SubmitButton>
            </div>
          </form>
        </section>
      )}

      {o.requests.length > 0 && (
        <section>
          <h2 className="mb-2 font-semibold">سجل الدفعات</h2>
          <ul className="flex flex-col gap-2 text-sm">
            {o.requests.map((r) => (
              <li key={r.id} className="rounded-lg border bg-white px-4 py-3">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <span>
                    <b>{r.plan}</b> · {PERIOD_LABELS[r.period]} · {money(r.amount_cents, r.currency)}
                  </span>
                  <span className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${REQUEST_STYLES[r.status]}`}>{REQUEST_STATUS[r.status] ?? r.status}</span>
                </div>
                <p className="mt-1 text-xs text-gray-500">
                  {fmtDay(r.created_at)} · {METHOD_LABELS[r.method] ?? r.method}
                  {r.period_end && ` · مفعّل حتى ${fmtDay(r.period_end)}`}
                </p>
                {r.review_note && <p className="mt-1 text-xs text-gray-700">{r.review_note}</p>}
              </li>
            ))}
          </ul>
        </section>
      )}
    </div>
  );
}

function UsageMeter({ label, used, max, left, unit, warnAt }: { label: string; used: number; max: number | null; left: number | null; unit: [string, string, string]; warnAt: number }) {
  const pct = max ? Math.min(100, Math.round((used / max) * 100)) : 0;
  const tone = left === 0 ? 'bg-red-500' : left != null && left <= warnAt ? 'bg-amber-500' : 'bg-brand';
  return (
    <div className="rounded-lg border bg-white p-4 text-sm">
      <div className="mb-2 flex items-center justify-between">
        <span className="font-semibold">{label}</span>
        <span dir="ltr" className="font-bold">
          {used} / {max ?? '∞'}
        </span>
      </div>
      {max != null && (
        <div className="h-2 overflow-hidden rounded bg-gray-100">
          <div className={`h-full ${tone}`} style={{ width: `${pct}%` }} />
        </div>
      )}
      <p className={`mt-2 text-xs ${left === 0 ? 'font-semibold text-red-700' : left != null && left <= warnAt ? 'font-semibold text-amber-700' : 'text-gray-500'}`}>
        {max == null ? 'بلا حد في خطتك' : left === 0 ? `امتلأ البستان — ${UPGRADE_CTA}` : `تبقى ${countText(left ?? 0, unit[0], unit[1], unit[2])} يمكن إضافتهم`}
      </p>
    </div>
  );
}
