import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';
import { fmtDay } from '@/lib/reports/format';
import { OrgLogo } from '@/components/org-logo';
import { PrintButton } from '@/components/print-button';
import { feeMoney, type FeeReceipt } from '@/lib/fees/types';

/** A printable payment receipt - the admin's copy and the family's are the same page. */
export async function FeeReceiptView({ r, back, backLabel }: { r: FeeReceipt; back: string; backLabel: string }) {
  const { t } = await getI18n();
  const F = t.staff.fees;
  const lang = t.labels.dateLocale;
  const owes = Number(r.balance.balance);
  const rows: [string, string][] = [
    [F.receivedFrom, `${r.student}${r.student_code ? ` (${r.student_code})` : ''}`],
    [F.dateLabel, fmtDay(r.paid_on, lang)],
    [F.method, F.methods[r.method] ?? r.method],
    ...(r.recorded_by ? ([[F.byLabel, r.recorded_by]] as [string, string][]) : []),
    ...(r.note ? ([[F.note, r.note]] as [string, string][]) : []),
    [F.balanceAfter, owes > 0 ? feeMoney(owes, r.currency, lang) : F.settled],
  ];

  return (
    <div className="mx-auto max-w-xl p-6">
      <div className="mb-4 flex items-center justify-between print:hidden">
        <a href={back as never} className="text-sm text-brand hover:underline">
          {backLabel}
        </a>
        <PrintButton label={F.print} />
      </div>
      <div className="relative overflow-hidden rounded-xl border bg-white p-6">
        {r.voided && (
          <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
            <span className="-rotate-12 rounded border-4 border-red-500 px-6 py-2 text-4xl font-black text-red-500/70">{F.voidStamp}</span>
          </div>
        )}
        <div className="mb-4 flex items-center justify-between border-b pb-4">
          <div className="flex items-center gap-3">
            <OrgLogo name={r.center} logoUrl={r.logo_url} size={40} />
            <div>
              <p className="font-bold">{r.center}</p>
              <p className="text-sm text-gray-500">{F.receiptTitle}</p>
            </div>
          </div>
          <p className="text-sm font-semibold">{fmt(F.receiptNo, { n: r.receipt_no })}</p>
        </div>
        <p className="mb-4 text-center text-3xl font-black text-brand">{feeMoney(r.amount, r.currency, lang)}</p>
        <dl className="grid grid-cols-[auto,1fr] gap-x-6 gap-y-2 text-sm">
          {rows.map(([k, v]) => (
            <div key={k} className="contents">
              <dt className="text-gray-500">{k}</dt>
              <dd className="font-medium">{v}</dd>
            </div>
          ))}
        </dl>
        {r.voided && r.void_reason && <p className="mt-4 rounded bg-red-50 p-2 text-xs text-red-700">{`${F.voidReason}: ${r.void_reason}`}</p>}
      </div>
    </div>
  );
}
