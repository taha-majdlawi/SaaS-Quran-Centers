import { randomUUID } from 'crypto';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { FeeAccountSummary } from '@/components/fee-account';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';
import { fmtDay } from '@/lib/reports/format';
import { FEE_METHODS, feeMoney, type FeePlan, type StudentFees } from '@/lib/fees/types';
import { addFeeCharge, assignFeePlan, recordFeePayment, setFeeChargeStatus, voidFeePayment } from '@/lib/fees/actions';

const field = 'mt-1 rounded border px-3 py-2 text-sm';

/** One student's fees account: plan, charges, payments, and recording a payment. */
export default async function StudentFeesPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ ok?: string; error?: string; receipt?: string }>;
}) {
  const { org: slug, id } = await params;
  const q = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const F = T.staff.fees;
  const lang = T.labels.dateLocale;
  if (org.myRole !== 'admin') return <p className="rounded-lg border bg-white p-6 text-sm text-gray-500">{F.adminOnly}</p>;

  const supabase = await createClient();
  const [{ data }, { data: ov }] = await Promise.all([
    supabase.rpc('student_fees', { p_org: org.id, p_student: id }),
    supabase.rpc('fees_overview', { p_org: org.id }),
  ]);
  const a = data as StudentFees | null;
  if (!a?.enabled || !a.student || !a.balance) {
    return <p className="text-sm text-red-600">{q.error ?? F.offTitle}</p>;
  }
  const cur = a.currency ?? '';
  const money = (v: number) => feeMoney(v, cur, lang);
  const plans = (((ov as { plans?: FeePlan[] } | null)?.plans ?? []) as FeePlan[]).filter((p) => p.active || p.id === a.plan?.id);
  const back = `/fees/${id}`;
  const owes = Number(a.balance.balance);

  return (
    <div className="max-w-4xl">
      <a href="/fees" className="text-sm text-brand hover:underline">
        {F.back}
      </a>
      <div className="mb-4 mt-2 flex flex-wrap items-baseline gap-2">
        <h1 className="text-2xl font-bold">{a.student.name}</h1>
        {a.student.code && <span className="text-sm text-gray-500">{a.student.code}</span>}
        <a href={`/students/${id}` as never} className="text-xs text-brand hover:underline">
          ↗
        </a>
      </div>
      {q.ok && F.ok[q.ok] && (
        <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">
          {F.ok[q.ok]}
          {q.receipt && (
            <a href={`/fees/receipt/${q.receipt}` as never} className="ms-2 font-semibold underline">
              {F.receipt}
            </a>
          )}
        </p>
      )}
      {q.error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{q.error}</p>}

      <FeeAccountSummary balance={a.balance} currency={cur} />

      <div className="mt-4 grid gap-4 md:grid-cols-2">
        <form action={recordFeePayment} className="flex flex-col gap-3 rounded-lg border bg-white p-4">
          <h2 className="font-semibold">{F.recordTitle}</h2>
          <input type="hidden" name="orgId" value={org.id} />
          <input type="hidden" name="studentId" value={id} />
          <input type="hidden" name="clientRef" value={randomUUID()} />
          <div className="flex flex-wrap gap-3">
            <label className="text-xs text-gray-600">
              {F.amount}
              <input type="number" name="amount" required min={0.01} step="0.01" defaultValue={owes > 0 ? owes : undefined} className={`block w-32 ${field}`} />
            </label>
            <label className="text-xs text-gray-600">
              {F.method}
              <select name="method" className={`block ${field}`}>
                {FEE_METHODS.map((m) => (
                  <option key={m} value={m}>
                    {F.methods[m]}
                  </option>
                ))}
              </select>
            </label>
            <label className="text-xs text-gray-600">
              {F.paidOn}
              <input type="date" name="paidOn" defaultValue={a.today} max={a.today} className={`block ${field}`} />
            </label>
          </div>
          <label className="text-xs text-gray-600">
            {F.note}
            <input name="note" maxLength={300} className={`block w-full ${field}`} />
          </label>
          <SubmitButton className="self-start rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText="...">
            {F.record}
          </SubmitButton>
        </form>

        <div className="flex flex-col gap-4">
          <form action={assignFeePlan} className="flex flex-col gap-3 rounded-lg border bg-white p-4">
            <h2 className="font-semibold">{F.planSection}</h2>
            <input type="hidden" name="orgId" value={org.id} />
            <input type="hidden" name="students" value={id} />
            <input type="hidden" name="back" value={back} />
            <div className="flex flex-wrap items-end gap-3">
              <label className="text-xs text-gray-600">
                {F.colPlan}
                <select name="planId" defaultValue={a.plan?.id ?? ''} className={`block ${field}`}>
                  <option value="">{F.noPlan}</option>
                  {plans.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.name} — {money(p.amount)} ({F.periods[p.period]})
                    </option>
                  ))}
                </select>
              </label>
              <label className="text-xs text-gray-600">
                {F.discount}
                <input type="number" name="discount" min={0} max={100} step="0.5" defaultValue={a.plan?.discount ?? 0} className={`block w-24 ${field}`} />
              </label>
              <label className="flex items-center gap-2 pb-2 text-sm text-gray-700">
                <input type="checkbox" name="exempt" defaultChecked={a.plan?.exempt ?? false} /> {F.exemptLabel}
              </label>
            </div>
            <label className="text-xs text-gray-600">
              {F.note}
              <input name="note" maxLength={300} defaultValue={a.plan?.note ?? ''} className={`block w-full ${field}`} />
            </label>
            <SubmitButton className="self-start rounded border px-4 py-2 text-sm text-brand" pendingText="...">
              {F.save}
            </SubmitButton>
          </form>

          <form action={addFeeCharge} className="flex flex-wrap items-end gap-3 rounded-lg border bg-white p-4">
            <h2 className="w-full font-semibold">{F.addChargeTitle}</h2>
            <input type="hidden" name="orgId" value={org.id} />
            <input type="hidden" name="studentId" value={id} />
            <label className="text-xs text-gray-600">
              {F.chargeTitle}
              <input name="title" required maxLength={120} className={`block w-40 ${field}`} />
            </label>
            <label className="text-xs text-gray-600">
              {F.amount}
              <input type="number" name="amount" required min={0.01} step="0.01" className={`block w-24 ${field}`} />
            </label>
            <label className="text-xs text-gray-600">
              {F.dueDate}
              <input type="date" name="dueDate" defaultValue={a.today} className={`block ${field}`} />
            </label>
            <SubmitButton className="rounded border px-4 py-2 text-sm text-brand" pendingText="...">
              {F.addCharge}
            </SubmitButton>
          </form>
        </div>
      </div>

      <h2 className="mb-2 mt-6 font-semibold">{F.payments}</h2>
      <div className="overflow-x-auto rounded-lg border bg-white">
        <table className="w-full text-sm">
          <tbody>
            {(a.payments ?? []).map((p) => (
              <tr key={p.id} className="border-t first:border-t-0">
                <td className="px-3 py-2">
                  <a href={`/fees/receipt/${p.id}` as never} className="text-brand hover:underline">
                    {fmt(F.receiptNo, { n: p.receipt_no })}
                  </a>
                </td>
                <td className={`px-3 py-2 font-semibold ${p.voided ? 'text-gray-400 line-through' : ''}`}>{money(p.amount)}</td>
                <td className="px-3 py-2">{fmtDay(p.paid_on, lang)}</td>
                <td className="px-3 py-2">{F.methods[p.method]}</td>
                <td className="px-3 py-2 text-xs text-gray-500">{p.voided ? `${F.voided}${p.void_reason ? ` — ${p.void_reason}` : ''}` : (p.note ?? '')}</td>
                <td className="px-3 py-2 text-end">
                  {!p.voided && (
                    <form action={voidFeePayment} className="flex items-center justify-end gap-2">
                      <input type="hidden" name="orgId" value={org.id} />
                      <input type="hidden" name="studentId" value={id} />
                      <input type="hidden" name="id" value={p.id} />
                      <input name="reason" placeholder={F.voidReason} maxLength={300} className="w-28 rounded border px-2 py-1 text-xs" />
                      <ConfirmSubmitButton confirmMessage={F.voidConfirm} pendingText="..." className="text-xs text-red-600 hover:underline">
                        {F.voidPayment}
                      </ConfirmSubmitButton>
                    </form>
                  )}
                </td>
              </tr>
            ))}
            {!a.payments?.length && (
              <tr>
                <td className="p-6 text-center text-gray-400">{F.noPayments}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <h2 className="mb-2 mt-6 font-semibold">{F.charges}</h2>
      <div className="overflow-x-auto rounded-lg border bg-white">
        <table className="w-full text-sm">
          <tbody>
            {(a.charges ?? []).map((c) => (
              <tr key={c.id} className={`border-t first:border-t-0 ${c.status !== 'open' ? 'text-gray-400' : ''}`}>
                <td className="px-3 py-2">{c.title}</td>
                <td className={`px-3 py-2 font-semibold ${c.status !== 'open' ? 'line-through' : ''}`}>{money(c.amount)}</td>
                <td className="px-3 py-2">{fmtDay(c.due_date, lang)}</td>
                <td className="px-3 py-2 text-xs">{c.status === 'open' && a.today && c.due_date > a.today ? F.notYetDue : F.status[c.status]}</td>
                <td className="px-3 py-2 text-end">
                  <div className="flex justify-end gap-3">
                    {(c.status === 'open' ? (['waived', 'cancelled'] as const) : (['open'] as const)).map((st) => (
                      <form key={st} action={setFeeChargeStatus}>
                        <input type="hidden" name="orgId" value={org.id} />
                        <input type="hidden" name="studentId" value={id} />
                        <input type="hidden" name="id" value={c.id} />
                        <input type="hidden" name="status" value={st} />
                        {st === 'cancelled' ? (
                          <ConfirmSubmitButton confirmMessage={F.cancelChargeConfirm} pendingText="..." className="text-xs text-red-600 hover:underline">
                            {F.cancelCharge}
                          </ConfirmSubmitButton>
                        ) : (
                          <SubmitButton className="text-xs text-brand hover:underline" pendingText="...">
                            {st === 'waived' ? F.waive : F.reopen}
                          </SubmitButton>
                        )}
                      </form>
                    ))}
                  </div>
                </td>
              </tr>
            ))}
            {!a.charges?.length && (
              <tr>
                <td className="p-6 text-center text-gray-400">{F.noCharges}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
