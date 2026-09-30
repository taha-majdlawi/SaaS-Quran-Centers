import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { btn, field } from '@/components/platform-flash';
import { recordPayment, reviewPayment, saveBillingSettings } from '@/lib/billing/actions';
import { METHOD_LABELS, PERIOD_LABELS, REQUEST_STATUS, REQUEST_STYLES, STATE_LABELS, fmtDay, money, type BillingState } from '@/lib/billing/format';

interface Row {
  id: string;
  org_id: string;
  org_name: string;
  org_slug: string;
  plan: string;
  period: string;
  amount_cents: number;
  currency: string;
  method: string;
  reference: string | null;
  note: string | null;
  status: string;
  created_at: string;
  requested_by: string | null;
  review_note: string | null;
  period_end: string | null;
  billing: BillingState;
}

interface Settings {
  enforce: boolean;
  grace_days: number;
  instructions: string;
  would_lock: { id: string; name: string; slug: string; status: string; trial_ends_at: string | null }[];
  would_move_to_free?: { id: string; name: string; slug: string; status: string; trial_ends_at: string | null }[];
  free_plan?: { id: string; name: string } | null;
}

const OK: Record<string, string> = {
  approved: 'تم تأكيد الدفع وتفعيل الاشتراك ✓',
  rejected: 'رُفض الطلب وأُبلغ المركز',
  recorded: 'سُجّلت الدفعة وفُعّل الاشتراك ✓',
  saved: 'تم الحفظ',
};

// Billing phase 1 (0066): confirm the payments centers report, record ones
// received directly, and control enforcement of the read-only lock.
export default async function PlatformBillingPage({ searchParams }: { searchParams: Promise<{ ok?: string; error?: string }> }) {
  const { ok, error } = await searchParams;
  const supabase = await createClient();
  const [{ data: pendingData }, { data: allData }, { data: settingsData }, { data: orgs }, { data: plans }] = await Promise.all([
    supabase.rpc('platform_billing_requests', { p_status: 'pending', p_limit: 200 }),
    supabase.rpc('platform_billing_requests', { p_status: 'history', p_limit: 50 }),
    supabase.rpc('platform_get_billing_settings'),
    supabase.from('organizations').select('id, name').order('name'),
    supabase.from('plans').select('id, name, price_cents, yearly_price_cents, currency').order('price_cents'),
  ]);
  const pending = (pendingData ?? []) as Row[];
  const history = (allData ?? []) as Row[];
  const st = (settingsData ?? { enforce: false, grace_days: 7, instructions: '', would_lock: [] }) as Settings;
  // nobody pays for the free plan (billing_submit_request / platform_record_payment refuse it)
  const payablePlans = (plans ?? []).filter((p) => p.id !== st.free_plan?.id);

  return (
    <div className="flex max-w-5xl flex-col gap-8">
      <div>
        <h1 className="mb-1 text-2xl font-bold">المدفوعات والاشتراكات</h1>
        <p className="text-sm text-gray-500">الدفع يدوي حاليًا (تحويل / محفظة / نقدًا): المركز يُبلغ عن دفعته من صفحة «الاشتراك والدفع»، وأنت تؤكدها هنا.</p>
      </div>
      {ok && OK[ok] && <p className="rounded bg-green-50 px-3 py-2 text-sm text-green-700">{OK[ok]}</p>}
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <section>
        <h2 className="mb-3 text-lg font-semibold">بانتظار التأكيد ({pending.length})</h2>
        {pending.length === 0 && <p className="rounded-lg border bg-white p-4 text-sm text-gray-400">لا توجد إشعارات دفع جديدة</p>}
        <div className="flex flex-col gap-3">
          {pending.map((r) => (
            <div key={r.id} className="rounded-lg border bg-white p-4 text-sm">
              <div className="flex flex-wrap items-start justify-between gap-2">
                <div>
                  <a href={`/organizations/${r.org_id}` as never} className="text-base font-bold hover:underline">
                    {r.org_name}
                  </a>{' '}
                  <span className="text-xs text-gray-400" dir="ltr">
                    {r.org_slug}
                  </span>
                  <p className="mt-1">
                    {r.plan} · {PERIOD_LABELS[r.period]} · <b>{money(r.amount_cents, r.currency)}</b> · {METHOD_LABELS[r.method] ?? r.method}
                    {r.reference && (
                      <span dir="ltr" className="ms-1 rounded bg-gray-100 px-1.5 font-mono text-xs">
                        {r.reference}
                      </span>
                    )}
                  </p>
                  {r.note && <p className="mt-1 text-gray-600">«{r.note}»</p>}
                  <p className="mt-1 text-xs text-gray-400">
                    {r.requested_by ?? '—'} · {new Date(r.created_at).toLocaleString('ar')} · حالة المركز: {STATE_LABELS[r.billing?.state] ?? '—'}
                  </p>
                </div>
              </div>
              <div className="mt-3 flex flex-wrap items-end gap-2 border-t pt-3">
                <form action={reviewPayment}>
                  <input type="hidden" name="id" value={r.id} />
                  <input type="hidden" name="decision" value="approve" />
                  <ConfirmSubmitButton
                    confirmMessage={`تأكيد استلام ${money(r.amount_cents, r.currency)} من ${r.org_name}؟`}
                    className="rounded bg-green-700 px-4 py-2 text-sm font-semibold text-white"
                    pendingText="..."
                  >
                    ✓ وصل المبلغ — فعّل الاشتراك
                  </ConfirmSubmitButton>
                </form>
                <form action={reviewPayment} className="flex flex-1 items-end gap-2">
                  <input type="hidden" name="id" value={r.id} />
                  <input type="hidden" name="decision" value="reject" />
                  <input name="note" required placeholder="سبب الرفض (يظهر للمركز)" className="min-w-0 flex-1 rounded border px-3 py-2 text-sm" />
                  <SubmitButton className="rounded border border-red-300 px-3 py-2 text-sm text-red-700" pendingText="...">
                    رفض
                  </SubmitButton>
                </form>
              </div>
            </div>
          ))}
        </div>
      </section>

      <section>
        <h2 className="mb-3 text-lg font-semibold">تسجيل دفعة وصلت مباشرة</h2>
        <form action={recordPayment} className="grid gap-3 rounded-lg border bg-white p-4 sm:grid-cols-3">
          <label className="text-sm">
            المركز
            <select name="org" required className={field}>
              {(orgs ?? []).map((o) => (
                <option key={o.id} value={o.id}>
                  {o.name}
                </option>
              ))}
            </select>
          </label>
          <label className="text-sm">
            الخطة
            <select name="plan" required className={field}>
              {payablePlans.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name}
                </option>
              ))}
            </select>
          </label>
          <label className="text-sm">
            المدة
            <select name="period" defaultValue="yearly" className={field}>
              <option value="yearly">سنة</option>
              <option value="monthly">شهر</option>
            </select>
          </label>
          <label className="text-sm">
            المبلغ المستلم
            <input name="amount" type="number" min="0" step="0.01" required className={field} />
          </label>
          <label className="text-sm">
            الطريقة
            <select name="method" defaultValue="cash" className={field}>
              {Object.entries(METHOD_LABELS).map(([k, l]) => (
                <option key={k} value={k}>
                  {l}
                </option>
              ))}
            </select>
          </label>
          <label className="text-sm">
            ملاحظة
            <input name="note" className={field} />
          </label>
          <div className="sm:col-span-3">
            <SubmitButton className={btn} pendingText="جاري التسجيل...">
              سجّل الدفعة وفعّل الاشتراك
            </SubmitButton>
            <p className="mt-2 text-xs text-gray-500">تُضاف المدة بعد نهاية الاشتراك الحالي إن كان ساريًا، وإلا من اليوم.</p>
          </div>
        </form>
      </section>

      <section>
        <h2 className="mb-3 text-lg font-semibold">الإعدادات</h2>
        <form action={saveBillingSettings} className="flex flex-col gap-4 rounded-lg border bg-white p-4">
          <label className="text-sm">
            تعليمات الدفع التي تظهر للمراكز (رقم الحساب / IBAN، المحفظة، اسم المستفيد...)
            <textarea name="instructions" rows={6} defaultValue={st.instructions} className={field} />
          </label>
          <label className="text-sm">
            مهلة السماح بعد انتهاء الاشتراك قبل التحويل للقراءة فقط (أيام)
            <input name="graceDays" type="number" min="0" max="60" defaultValue={st.grace_days} className={field} />
          </label>
          <div className={`rounded border p-3 ${st.enforce ? 'border-green-200 bg-green-50' : 'border-amber-200 bg-amber-50'}`}>
            <label className="flex items-center gap-2 text-sm font-semibold">
              <input type="checkbox" name="enforce" defaultChecked={st.enforce} /> تفعيل القفل: المركز المنتهي اشتراكه (بعد المهلة) يصبح للقراءة فقط
            </label>
            {!st.enforce && (
              <div className="mt-2 text-xs text-amber-900">
                <p>القفل معطّل حاليًا: لا يُقفل أي مركز ولا تُرسل تذكيرات.</p>
                {st.would_lock.length > 0 ? (
                  <>
                    <p className="mt-1 font-semibold">لو فعّلته الآن ستُقفل هذه المراكز ({st.would_lock.length}) — راجع حالتها من صفحة المركز أولًا (اجعلها «مفعّل» أو مدّد تجربتها):</p>
                    <ul className="mt-1 list-inside list-disc">
                      {st.would_lock.map((o) => (
                        <li key={o.id}>
                          <a href={`/organizations/${o.id}` as never} className="underline">
                            {o.name}
                          </a>{' '}
                          — {o.status === 'trial' ? `تجربة انتهت ${fmtDay(o.trial_ends_at)}` : o.status}
                        </li>
                      ))}
                    </ul>
                  </>
                ) : (
                  <p className="mt-1">لن يُقفل أي مركز لو فعّلته الآن.</p>
                )}
                {(st.would_move_to_free ?? []).length > 0 && (
                  <>
                    <p className="mt-2 font-semibold">
                      وستنتقل هذه المراكز ({(st.would_move_to_free ?? []).length}) إلى الخطة المجانية «{st.free_plan?.name}» لأن حجمها يناسبها:
                    </p>
                    <ul className="mt-1 list-inside list-disc">
                      {(st.would_move_to_free ?? []).map((o) => (
                        <li key={o.id}>
                          <a href={`/organizations/${o.id}` as never} className="underline">
                            {o.name}
                          </a>
                        </li>
                      ))}
                    </ul>
                  </>
                )}
              </div>
            )}
          </div>
          <div>
            <SubmitButton className={btn} pendingText="جاري الحفظ...">
              حفظ الإعدادات
            </SubmitButton>
          </div>
        </form>
      </section>

      {history.length > 0 && (
        <section>
          <h2 className="mb-3 text-lg font-semibold">آخر العمليات</h2>
          <div className="overflow-x-auto rounded-lg border bg-white">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 text-right text-xs text-gray-500">
                <tr>
                  <th className="p-2">المركز</th>
                  <th className="p-2">الخطة</th>
                  <th className="p-2">المبلغ</th>
                  <th className="p-2">الحالة</th>
                  <th className="p-2">حتى</th>
                  <th className="p-2">التاريخ</th>
                </tr>
              </thead>
              <tbody>
                {history.map((r) => (
                  <tr key={r.id} className="border-t">
                    <td className="p-2">{r.org_name}</td>
                    <td className="p-2">
                      {r.plan} · {PERIOD_LABELS[r.period]}
                    </td>
                    <td className="p-2">{money(r.amount_cents, r.currency)}</td>
                    <td className="p-2">
                      <span className={`rounded-full px-2 py-0.5 text-xs ${REQUEST_STYLES[r.status]}`}>{REQUEST_STATUS[r.status] ?? r.status}</span>
                    </td>
                    <td className="p-2">{fmtDay(r.period_end)}</td>
                    <td className="p-2 text-xs text-gray-500">{fmtDay(r.created_at)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}
    </div>
  );
}
