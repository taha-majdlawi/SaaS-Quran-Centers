import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';
import { fmtDay } from '@/lib/reports/format';
import { FEE_METHODS, feeMoney, type FeesOverview, type FeesReport } from '@/lib/fees/types';
import {
  assignFeePlan,
  deleteFeePlan,
  disableFees,
  enableFees,
  issueFeeCharges,
  saveFeePlan,
  saveFeeSettings,
} from '@/lib/fees/actions';

const field = 'mt-1 rounded border px-3 py-2 text-sm';
const TABS = ['students', 'plans', 'report', 'settings'] as const;

const monthStart = (today: string) => `${today.slice(0, 8)}01`;

export default async function FeesPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ tab?: string; ok?: string; error?: string; f?: string; from?: string; to?: string }>;
}) {
  const { org: slug } = await params;
  const q = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const F = T.staff.fees;
  const lang = T.labels.dateLocale;

  if (org.myRole !== 'admin') {
    return <p className="rounded-lg border bg-white p-6 text-sm text-gray-500">{F.adminOnly}</p>;
  }

  const supabase = await createClient();
  const { data } = await supabase.rpc('fees_overview', { p_org: org.id });
  const o = data as FeesOverview | null;
  if (!o) return <p className="text-sm text-red-600">{q.error ?? T.staff.common.loadFailed}</p>;
  const cur = o.currency;
  const money = (v: number) => feeMoney(v, cur, lang);

  const banners = (
    <>
      {q.ok && F.ok[q.ok] && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{F.ok[q.ok]}</p>}
      {q.error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{q.error}</p>}
    </>
  );

  // switched off: what it is, and the one button to turn it on
  if (!o.enabled) {
    return (
      <div className="max-w-2xl">
        <h1 className="mb-4 text-2xl font-bold">{F.title}</h1>
        {banners}
        <div className="rounded-xl border bg-white p-6">
          <h2 className="mb-2 font-semibold">{F.offTitle}</h2>
          <p className="mb-4 text-sm leading-6 text-gray-600">{F.offHint}</p>
          {o.platform_allowed ? (
            <form action={enableFees}>
              <input type="hidden" name="orgId" value={org.id} />
              <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText="...">
                {F.enable}
              </SubmitButton>
            </form>
          ) : (
            <p className="rounded bg-amber-50 px-3 py-2 text-sm text-amber-800">{F.platformOff}</p>
          )}
        </div>
      </div>
    );
  }

  const tab = (TABS as readonly string[]).includes(q.tab ?? '') ? (q.tab as (typeof TABS)[number]) : 'students';
  const owing = o.students.filter((x) => Number(x.balance) > 0);
  const outstanding = owing.reduce((sum, x) => sum + Number(x.balance), 0);

  return (
    <div className="max-w-5xl">
      <h1 className="mb-4 text-2xl font-bold">{F.title}</h1>
      {banners}

      <div className="mb-4 grid grid-cols-3 gap-3">
        {[
          [F.collectedMonth, money(o.collected_month)],
          [F.outstanding, money(outstanding)],
          [F.owingN, String(owing.length)],
        ].map(([k, v]) => (
          <div key={k} className="rounded-lg border bg-white p-4">
            <p className="text-xs text-gray-500">{k}</p>
            <p className="mt-1 text-xl font-bold text-brand">{v}</p>
          </div>
        ))}
      </div>

      <div className="mb-4 flex flex-wrap gap-2 text-sm">
        {TABS.map((v) => (
          <a key={v} href={`/fees${v === 'students' ? '' : `?tab=${v}`}` as never} className={`rounded-full border px-3 py-1 ${tab === v ? 'bg-brand text-white' : 'bg-white'}`}>
            {F.tabs[v]}
          </a>
        ))}
      </div>

      {tab === 'students' && (await studentsTab(o, org.id, q.f))}
      {tab === 'plans' && plansTab(o, org.id)}
      {tab === 'report' && (await reportTab(org.id, q.from || monthStart(o.today), q.to || o.today))}
      {tab === 'settings' && (
        <div className="flex max-w-xl flex-col gap-4">
          <form action={saveFeeSettings} className="flex flex-col gap-3 rounded-lg border bg-white p-4">
            <input type="hidden" name="orgId" value={org.id} />
            <label className="text-xs text-gray-600">
              {F.currency}
              <input name="currency" maxLength={8} defaultValue={cur} className={`block w-28 ${field}`} />
            </label>
            <label className="text-xs text-gray-600">
              {F.dueDay}
              <input type="number" name="dueDay" min={1} max={28} defaultValue={o.due_day} className={`block w-28 ${field}`} />
            </label>
            <label className="text-xs text-gray-600">
              {F.reminderDays}
              <input type="number" name="reminderDays" min={0} max={60} defaultValue={o.reminder_days} className={`block w-28 ${field}`} />
            </label>
            <p className="text-xs text-gray-500">{F.reminderHint}</p>
            <SubmitButton className="self-start rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText="...">
              {F.saveSettings}
            </SubmitButton>
          </form>
          <form action={disableFees}>
            <input type="hidden" name="orgId" value={org.id} />
            <ConfirmSubmitButton confirmMessage={F.disableConfirm} pendingText="..." className="rounded border border-red-200 px-4 py-2 text-sm text-red-600">
              {F.disable}
            </ConfirmSubmitButton>
          </form>
        </div>
      )}
    </div>
  );

  async function studentsTab(o: FeesOverview, orgId: string, filter?: string) {
    const rows = o.students.filter((x) => (filter === 'owing' ? Number(x.balance) > 0 : filter === 'noPlan' ? !x.plan_id && !x.exempt : true));
    const activePlans = o.plans.filter((p) => p.active);
    return (
      <form action={assignFeePlan}>
        <input type="hidden" name="orgId" value={orgId} />
        <input type="hidden" name="back" value={`/fees${filter ? `?f=${filter}` : ''}`} />
        <div className="mb-3 flex gap-2 text-xs">
          {(['all', 'owing', 'noPlan'] as const).map((v) => (
            <a key={v} href={`/fees${v === 'all' ? '' : `?f=${v}`}` as never} className={`rounded border px-2 py-1 ${(filter ?? 'all') === v ? 'border-brand text-brand' : 'bg-white'}`}>
              {F.filter[v]}
            </a>
          ))}
        </div>
        <div className="overflow-x-auto rounded-lg border bg-white">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-start text-xs text-gray-500">
              <tr>
                <th className="w-8 px-3 py-2" />
                <th className="px-3 py-2 text-start">{F.colStudent}</th>
                <th className="px-3 py-2 text-start">{F.colCircle}</th>
                <th className="px-3 py-2 text-start">{F.colPlan}</th>
                <th className="px-3 py-2 text-start">{F.colDue}</th>
                <th className="px-3 py-2 text-start">{F.colPaid}</th>
                <th className="px-3 py-2 text-start">{F.colBalance}</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((x) => (
                <tr key={x.id} className="border-t">
                  <td className="px-3 py-2">
                    <input type="checkbox" name="students" value={x.id} aria-label={x.name} />
                  </td>
                  <td className="px-3 py-2">
                    <a href={`/fees/${x.id}` as never} className="font-medium text-brand hover:underline">
                      {x.name}
                    </a>{' '}
                    {x.code && <span className="text-xs text-gray-400">{x.code}</span>}
                  </td>
                  <td className="px-3 py-2 text-gray-600">{x.circle ?? '—'}</td>
                  <td className="px-3 py-2">
                    {x.exempt ? (
                      <span className="rounded bg-green-50 px-1.5 py-0.5 text-xs text-green-700">{F.exempt}</span>
                    ) : x.plan ? (
                      <>
                        {x.plan}
                        {Number(x.discount) > 0 && <span className="ms-1 text-xs text-gray-500">({fmt(F.discountV, { n: Number(x.discount) })})</span>}
                      </>
                    ) : (
                      <span className="text-xs text-gray-400">{F.noPlan}</span>
                    )}
                  </td>
                  <td className="px-3 py-2">{money(x.due)}</td>
                  <td className="px-3 py-2">{money(x.paid)}</td>
                  <td className={`px-3 py-2 font-semibold ${Number(x.balance) > 0 ? 'text-red-600' : 'text-green-700'}`}>
                    {Number(x.balance) > 0 ? money(x.balance) : Number(x.balance) < 0 ? `${F.credit} ${money(-x.balance)}` : '✓'}
                  </td>
                </tr>
              ))}
              {!rows.length && (
                <tr>
                  <td colSpan={7} className="p-6 text-center text-gray-400">
                    {F.none}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        <div className="mt-4 flex flex-wrap items-end gap-3 rounded-lg border bg-white p-4">
          <p className="w-full text-sm font-semibold">{F.assignTitle}</p>
          <label className="text-xs text-gray-600">
            {F.colPlan}
            <select name="planId" className={`block ${field}`}>
              <option value="">{F.noPlan}</option>
              {activePlans.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name} — {money(p.amount)} ({F.periods[p.period]})
                </option>
              ))}
            </select>
          </label>
          <label className="text-xs text-gray-600">
            {F.discount}
            <input type="number" name="discount" min={0} max={100} step="0.5" defaultValue={0} className={`block w-24 ${field}`} />
          </label>
          <label className="flex items-center gap-2 pb-2 text-sm text-gray-700">
            <input type="checkbox" name="exempt" /> {F.exemptLabel}
          </label>
          <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText="...">
            {F.assign}
          </SubmitButton>
          <p className="w-full text-xs text-gray-500">{F.assignHint}</p>
        </div>
      </form>
    );
  }

  function plansTab(o: FeesOverview, orgId: string) {
    const planForm = (p?: FeesOverview['plans'][number]) => (
      <form action={saveFeePlan} className="flex flex-wrap items-end gap-3">
        <input type="hidden" name="orgId" value={orgId} />
        {p && <input type="hidden" name="id" value={p.id} />}
        <label className="text-xs text-gray-600">
          {F.name}
          <input name="name" required maxLength={80} defaultValue={p?.name} className={`block w-48 ${field}`} />
        </label>
        <label className="text-xs text-gray-600">
          {F.amount}
          <input type="number" name="amount" required min={0} step="0.01" defaultValue={p?.amount} className={`block w-28 ${field}`} />
        </label>
        <label className="text-xs text-gray-600">
          {F.period}
          <select name="period" defaultValue={p?.period ?? 'monthly'} className={`block ${field}`}>
            {(['monthly', 'term', 'once'] as const).map((v) => (
              <option key={v} value={v}>
                {F.periods[v]}
              </option>
            ))}
          </select>
        </label>
        <label className="flex items-center gap-2 pb-2 text-sm text-gray-700">
          <input type="checkbox" name="active" defaultChecked={p?.active ?? true} /> {F.active}
        </label>
        <SubmitButton className="rounded border px-4 py-2 text-sm text-brand" pendingText="...">
          {F.save}
        </SubmitButton>
      </form>
    );
    return (
      <div className="flex flex-col gap-4">
        <p className="text-xs text-gray-500">{F.monthlyHint}</p>
        {o.plans.map((p) => (
          <div key={p.id} className={`rounded-lg border bg-white p-4 ${p.active ? '' : 'opacity-60'}`}>
            <div className="mb-3 flex items-center justify-between text-sm">
              <b>
                {p.name} · {money(p.amount)} · {F.periods[p.period]}
                {!p.active && <span className="ms-2 text-xs text-gray-500">({F.inactive})</span>}
              </b>
              <span className="text-xs text-gray-500">{fmt(F.studentsN, { n: p.students })}</span>
            </div>
            {planForm(p)}
            {p.period !== 'monthly' && p.active && (
              <form action={issueFeeCharges} className="mt-3 flex flex-wrap items-end gap-3 border-t pt-3">
                <input type="hidden" name="orgId" value={orgId} />
                <input type="hidden" name="planId" value={p.id} />
                <p className="w-full text-xs font-semibold text-gray-600">{F.issueTitle}</p>
                <label className="text-xs text-gray-600">
                  {F.chargeTitle}
                  <input name="title" required maxLength={120} placeholder={F.chargeTitlePh} className={`block w-48 ${field}`} />
                </label>
                <label className="text-xs text-gray-600">
                  {F.dueDate}
                  <input type="date" name="dueDate" defaultValue={o.today} className={`block ${field}`} />
                </label>
                <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText="...">
                  {F.issue}
                </SubmitButton>
              </form>
            )}
            <form action={deleteFeePlan} className="mt-2">
              <input type="hidden" name="orgId" value={orgId} />
              <input type="hidden" name="id" value={p.id} />
              <ConfirmSubmitButton confirmMessage={F.deletePlanConfirm} pendingText="..." className="text-xs text-red-600 hover:underline">
                {F.delete}
              </ConfirmSubmitButton>
            </form>
          </div>
        ))}
        {!o.plans.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">{F.noPlans}</p>}
        <div className="rounded-lg border border-dashed bg-white p-4">
          <p className="mb-3 text-sm font-semibold">{F.newPlan}</p>
          {planForm()}
        </div>
      </div>
    );
  }

  async function reportTab(orgId: string, from: string, to: string) {
    const { data: rep } = await supabase.rpc('fees_report', { p_org: orgId, p_from: from, p_to: to });
    const r = rep as FeesReport | null;
    return (
      <div className="flex flex-col gap-4">
        <form className="flex flex-wrap items-end gap-3 rounded-lg border bg-white p-4">
          <input type="hidden" name="tab" value="report" />
          <label className="text-xs text-gray-600">
            {F.from}
            <input type="date" name="from" defaultValue={from} className={`block ${field}`} />
          </label>
          <label className="text-xs text-gray-600">
            {F.to}
            <input type="date" name="to" defaultValue={to} className={`block ${field}`} />
          </label>
          <button className="rounded border px-4 py-2 text-sm text-brand">{F.show}</button>
        </form>
        {r && (
          <>
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
              {[
                [F.total, money(r.total)],
                [F.count, String(r.count)],
                [F.charged, money(r.charged)],
                [F.outstanding, money(r.outstanding)],
              ].map(([k, v]) => (
                <div key={k} className="rounded-lg border bg-white p-4">
                  <p className="text-xs text-gray-500">{k}</p>
                  <p className="mt-1 text-lg font-bold">{v}</p>
                </div>
              ))}
            </div>
            <div className="rounded-lg border bg-white p-4 text-sm">
              <p className="mb-2 font-semibold">{F.byMethod}</p>
              <div className="flex flex-wrap gap-4">
                {FEE_METHODS.filter((m) => r.by_method[m]).map((m) => (
                  <span key={m}>
                    {F.methods[m]}: <b>{money(r.by_method[m] ?? 0)}</b>
                  </span>
                ))}
                {!Object.keys(r.by_method).length && <span className="text-gray-400">—</span>}
              </div>
            </div>
            <div className="overflow-x-auto rounded-lg border bg-white">
              <table className="w-full text-sm">
                <tbody>
                  {r.payments.map((p) => (
                    <tr key={p.id} className={`border-t first:border-t-0 ${p.voided ? 'text-gray-400 line-through' : ''}`}>
                      <td className="px-3 py-2">
                        <a href={`/fees/receipt/${p.id}` as never} className="text-brand hover:underline">
                          {fmt(F.receiptNo, { n: p.receipt_no })}
                        </a>
                      </td>
                      <td className="px-3 py-2">{fmtDay(p.paid_on, lang)}</td>
                      <td className="px-3 py-2">{p.student}</td>
                      <td className="px-3 py-2">{F.methods[p.method]}</td>
                      <td className="px-3 py-2 font-semibold">{money(p.amount)}</td>
                    </tr>
                  ))}
                  {!r.payments.length && (
                    <tr>
                      <td className="p-6 text-center text-gray-400">{F.noPayments}</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </>
        )}
      </div>
    );
  }
}
