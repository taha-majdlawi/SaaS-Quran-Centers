import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { cancelPayment, submitPayment } from '@/lib/billing/actions';
import {
  REQUEST_STYLES,
  plural,
  fmtDay,
  money,
  type BillingLabels,
  type BillingPlan,
  type BillingRequest,
  type BillingState,
  type Usage,
} from '@/lib/billing/format';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

interface Overview {
  billing: BillingState;
  usage: Usage;
  org_status: string;
  current_plan: { id: string; name: string } | null;
  plans: BillingPlan[];
  instructions: string | null;
  requests: BillingRequest[];
}

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
  const { t: T } = await getI18n();
  const L = T.staff.billing;
  const day = (iso: string | null) => fmtDay(iso, T.labels.dateLocale);
  const stages = T.marketing.stages;
  const gardenStage = (i: number) => stages[Math.max(0, Math.min(i, stages.length - 1))];
  const supabase = await createClient();
  const { data, error: loadError } = await supabase.rpc('billing_overview', { p_org: org.id });
  const o = data as Overview | null;

  if (!o) return <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{loadError?.message ?? L.loadFailed}</p>;
  const b = o.billing;
  const pending = o.requests.find((r) => r.status === 'pending');
  const payable = o.plans.filter((p) => !p.is_free);

  return (
    <div className="flex max-w-3xl flex-col gap-5">
      <h1 className="text-2xl font-bold">{L.heading}</h1>
      {ok && L.ok[ok] && <p className="rounded bg-green-50 px-3 py-2 text-sm text-green-700">{L.ok[ok]}</p>}
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <section className={`rounded-lg border p-5 ${b.locked ? 'border-red-200 bg-red-50' : 'bg-white'}`}>
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <p className="text-sm text-gray-500">{L.currentPlan}</p>
            <p className="text-xl font-bold">{o.current_plan?.name ?? L.noPlan}</p>
          </div>
          <span
            className={`rounded-full px-3 py-1 text-sm font-semibold ${
              b.locked || b.state === 'grace' ? 'bg-red-100 text-red-700' : b.state === 'trial' ? 'bg-amber-100 text-amber-800' : 'bg-green-100 text-green-700'
            }`}
          >
            {L.state[b.state] ?? b.state}
          </span>
        </div>
        {b.until && (
          <p className="mt-3 text-sm">
            {b.state === 'trial' ? L.trialEnds : b.state === 'active' ? L.activeUntil : L.endedOn} <b>{day(b.until)}</b>
            {b.days_left != null && b.days_left > 0 && <span className="text-gray-500"> {fmt(L.remaining, { days: plural(b.days_left, L.days) })}</span>}
          </p>
        )}
        {b.state === 'grace' && b.enforced && (
          <p className="mt-2 text-sm text-red-700">{fmt(L.graceNote, { date: day(b.grace_ends) })}</p>
        )}
        {b.state === 'free' && (
          <p className="mt-3 text-sm text-gray-600">{L.freeNote}</p>
        )}
        {b.locked && (
          <p className="mt-2 text-sm font-semibold text-red-700">
            {L.lockedNote}
          </p>
        )}
      </section>

      <section className="grid gap-3 sm:grid-cols-2">
        <UsageMeter label={L.studentsLabel} used={o.usage.students} max={o.usage.max_students} left={o.usage.students_left} unit={L.students} L={L} warnAt={5} />
        <UsageMeter label={L.teachersLabel} used={o.usage.teachers} max={o.usage.max_teachers} left={o.usage.teachers_left} unit={L.teachers} L={L} warnAt={1} />
      </section>

      {pending && (
        <section className="rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm">
          <p className="font-bold">{L.pendingTitle}</p>
          <p className="mt-1">
            {pending.plan} · {L.period[pending.period]} · {money(pending.amount_cents, pending.currency)} · {L.method[pending.method] ?? pending.method}
            {pending.reference && <span dir="ltr"> · {pending.reference}</span>}
          </p>
          <p className="mt-1 text-gray-600">{fmt(L.pendingSent, { date: day(pending.created_at) })}</p>
          <form action={cancelPayment} className="mt-2">
            <input type="hidden" name="id" value={pending.id} />
            <SubmitButton className="text-xs text-red-600 hover:underline" pendingText="...">
              {L.cancelPending}
            </SubmitButton>
          </form>
        </section>
      )}

      <section>
        <h2 className="mb-1 font-semibold">{L.stagesTitle}</h2>
        <p className="mb-3 text-xs text-gray-500">{L.stagesHint}</p>
        {o.plans.length ? (
          <div className="grid gap-3 sm:grid-cols-2">
            {o.plans.map((p, i) => (
              <div key={p.id} className={`rounded-lg border bg-white p-4 text-sm ${o.current_plan?.id === p.id ? 'border-brand' : ''}`}>
                <p className="text-base font-bold">
                  {gardenStage(i).icon} {p.name}
                  {o.current_plan?.id === p.id && <span className="ms-2 rounded-full bg-brand/10 px-2 py-0.5 text-xs text-brand">{L.yourPlan}</span>}
                </p>
                <p className="mt-0.5 text-xs text-gray-500">{gardenStage(i).tagline}</p>
                {p.is_free ? (
                  <p className="mt-1 font-bold text-green-700">{L.free}</p>
                ) : (
                <p className="mt-1">
                  <b>{money(p.price_cents, p.currency)}</b> <span className="text-gray-500">{L.perMonth}</span>
                </p>
                )}
                {!p.is_free && p.yearly_price_cents != null && (
                  <p>
                    <b>{money(p.yearly_price_cents, p.currency)}</b> <span className="text-gray-500">{L.perYear}</span>
                    {p.yearly_price_cents < p.price_cents * 12 && (
                      <span className="ms-2 rounded bg-green-50 px-1.5 py-0.5 text-xs text-green-700">
                        {fmt(L.save, { pct: Math.round((1 - p.yearly_price_cents / (p.price_cents * 12)) * 100) })}
                      </span>
                    )}
                  </p>
                )}
                <p className="mt-2 text-xs text-gray-500">
                  {p.limits?.max_students != null ? fmt(L.upToStudents, { n: p.limits.max_students }) : L.unlimitedStudents} ·{' '}
                  {p.limits?.max_teachers != null ? fmt(L.upToTeachers, { n: p.limits.max_teachers }) : L.unlimitedTeachers}
                </p>
              </div>
            ))}
          </div>
        ) : (
          <p className="rounded-lg border bg-white p-4 text-sm text-gray-500">{L.noPlans}</p>
        )}
      </section>

      {o.instructions && (
        <section className="rounded-lg border bg-white p-4 text-sm">
          <h2 className="mb-2 font-semibold">{L.howToPay}</h2>
          <p className="whitespace-pre-line leading-7">{o.instructions}</p>
        </section>
      )}

      {!pending && payable.length > 0 && (
        <section className="rounded-lg border bg-white p-4">
          <h2 className="mb-1 font-semibold">{L.reportTitle}</h2>
          <p className="mb-3 text-xs text-gray-500">{L.reportHint}</p>
          <form action={submitPayment} className="grid gap-3 sm:grid-cols-2">
            <input type="hidden" name="orgId" value={org.id} />
            <label className="text-sm">
              {L.plan}
              <select name="plan" required defaultValue={payable.some((p) => p.id === o.current_plan?.id) ? o.current_plan?.id : payable[0].id} className={input}>
                {payable.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </select>
            </label>
            <label className="text-sm">
              {L.duration}
              <select name="period" defaultValue="yearly" className={input}>
                <option value="yearly">{L.period.yearly}</option>
                <option value="monthly">{L.period.monthly}</option>
              </select>
            </label>
            <label className="text-sm">
              {L.methodLabel}
              <select name="method" defaultValue="bank_transfer" className={input}>
                {Object.entries(L.method).map(([k, l]) => (
                  <option key={k} value={k}>
                    {l}
                  </option>
                ))}
              </select>
            </label>
            <label className="text-sm">
              {L.reference}
              <input name="reference" maxLength={120} dir="ltr" className={input} />
            </label>
            <label className="text-sm sm:col-span-2">
              {L.note}
              <textarea name="note" maxLength={500} rows={2} className={input} />
            </label>
            <div className="sm:col-span-2">
              <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText={L.sending}>
                {L.submit}
              </SubmitButton>
            </div>
          </form>
        </section>
      )}

      {o.requests.length > 0 && (
        <section>
          <h2 className="mb-2 font-semibold">{L.history}</h2>
          <ul className="flex flex-col gap-2 text-sm">
            {o.requests.map((r) => (
              <li key={r.id} className="rounded-lg border bg-white px-4 py-3">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <span>
                    <b>{r.plan}</b> · {L.period[r.period]} · {money(r.amount_cents, r.currency)}
                  </span>
                  <span className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${REQUEST_STYLES[r.status]}`}>{L.requestStatus[r.status] ?? r.status}</span>
                </div>
                <p className="mt-1 text-xs text-gray-500">
                  {day(r.created_at)} · {L.method[r.method] ?? r.method}
                  {r.period_end && ` · ${fmt(L.activeTill, { date: day(r.period_end) })}`}
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

function UsageMeter({ label, used, max, left, unit, warnAt, L }: { label: string; used: number; max: number | null; left: number | null; unit: Record<string, string>; warnAt: number; L: BillingLabels }) {
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
        {max == null ? L.unlimited : left === 0 ? fmt(L.gardenFull, { cta: L.upgrade }) : fmt(L.leftToAdd, { n: plural(left ?? 0, unit) })}
      </p>
    </div>
  );
}
