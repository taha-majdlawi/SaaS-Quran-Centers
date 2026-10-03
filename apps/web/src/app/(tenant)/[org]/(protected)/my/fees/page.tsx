import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { FeeAccountSummary } from '@/components/fee-account';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';
import { fmtDay } from '@/lib/reports/format';
import { feeMoney, type StudentFees } from '@/lib/fees/types';

/** The family's fees: balance, what was charged and every payment with its receipt. */
export default async function MyFeesPage({ params, searchParams }: { params: Promise<{ org: string }>; searchParams: Promise<{ s?: string }> }) {
  const { org: slug } = await params;
  const { s } = await searchParams;
  const org = await getOrgContext(slug);
  if (!org.feesEnabled) notFound();
  const supabase = await createClient();
  const { t } = await getI18n();
  const F = t.staff.fees;
  const lang = t.labels.dateLocale;

  const { data: students } = await supabase.from('students_profile').select('id, full_name').eq('organization_id', org.id).order('full_name');
  const list = (students ?? []) as { id: string; full_name: string }[];
  const current = list.find((x) => x.id === s) ?? list[0];
  const { data } = current ? await supabase.rpc('student_fees', { p_org: org.id, p_student: current.id }) : { data: null };
  const a = data as StudentFees | null;
  const cur = a?.currency ?? '';
  const money = (v: number) => feeMoney(v, cur, lang);

  return (
    <div className="mx-auto max-w-3xl p-6">
      <a href={`/my${current ? `?s=${current.id}` : ''}` as never} className="text-sm text-brand hover:underline">
        {t.portal.backToProfile}
      </a>
      <h1 className="mt-2 text-2xl font-bold">{F.title}</h1>
      <p className="mb-4 text-sm text-gray-500">{F.myIntro}</p>
      {list.length > 1 && (
        <div className="mb-4 flex flex-wrap gap-2 text-sm">
          {list.map((x) => (
            <a key={x.id} href={`/my/fees?s=${x.id}` as never} className={`rounded-full border px-3 py-1 ${x.id === current?.id ? 'bg-brand text-white' : 'bg-white'}`}>
              {x.full_name}
            </a>
          ))}
        </div>
      )}
      {!a?.enabled || !a.balance ? (
        <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">{F.myNone}</p>
      ) : (
        <div className="flex flex-col gap-4">
          <FeeAccountSummary balance={a.balance} currency={cur} />
          {a.plan?.name && !a.plan.exempt && (
            <p className="text-sm text-gray-600">
              {F.colPlan}: <b>{a.plan.name}</b> — {money(a.plan.amount ?? 0)} ({a.plan.period ? F.periods[a.plan.period] : ''})
              {Number(a.plan.discount) > 0 && ` · ${fmt(F.discountV, { n: Number(a.plan.discount) })}`}
            </p>
          )}
          {a.plan?.exempt && <p className="text-sm text-green-700">{F.exemptLabel}</p>}

          <section>
            <h2 className="mb-2 font-semibold">{F.payments}</h2>
            <div className="divide-y rounded-lg border bg-white text-sm">
              {(a.payments ?? []).map((p) => (
                <a key={p.id} href={`/my/fees/receipt/${p.id}` as never} className="flex items-center justify-between gap-2 px-4 py-3 hover:bg-gray-50">
                  <span>
                    <b>{money(p.amount)}</b> · {fmtDay(p.paid_on, lang)} · {F.methods[p.method]}
                  </span>
                  <span className="text-xs text-brand">{fmt(F.receiptNo, { n: p.receipt_no })}</span>
                </a>
              ))}
              {!a.payments?.length && <p className="p-4 text-center text-gray-400">{F.noPayments}</p>}
            </div>
          </section>

          <section>
            <h2 className="mb-2 font-semibold">{F.charges}</h2>
            <div className="divide-y rounded-lg border bg-white text-sm">
              {(a.charges ?? []).map((c) => (
                <div key={c.id} className={`flex items-center justify-between gap-2 px-4 py-3 ${c.status !== 'open' ? 'text-gray-400' : ''}`}>
                  <span>
                    {c.title} · {fmtDay(c.due_date, lang)}
                  </span>
                  <span className="flex items-center gap-2">
                    <b className={c.status !== 'open' ? 'line-through' : ''}>{money(c.amount)}</b>
                    {c.status !== 'open' && <span className="text-xs">{F.status[c.status]}</span>}
                    {c.status === 'open' && a.today && c.due_date > a.today && <span className="text-xs text-gray-400">{F.notYetDue}</span>}
                  </span>
                </div>
              ))}
              {!a.charges?.length && <p className="p-4 text-center text-gray-400">{F.noCharges}</p>}
            </div>
          </section>
        </div>
      )}
    </div>
  );
}
