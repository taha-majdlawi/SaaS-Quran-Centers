import { getI18n } from '@/lib/i18n/server';
import { feeMoney, type FeeBalance } from '@/lib/fees/types';

/** The four numbers of a student's fees account (admin page and family page). */
export async function FeeAccountSummary({ balance, currency }: { balance: FeeBalance; currency: string }) {
  const { t } = await getI18n();
  const F = t.staff.fees;
  const lang = t.labels.dateLocale;
  const owes = Number(balance.balance);
  const money = (v: number) => feeMoney(v, currency, lang);
  return (
    <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
      <div className={`rounded-lg border p-4 ${owes > 0 ? 'border-red-200 bg-red-50' : 'border-green-200 bg-green-50'}`}>
        <p className="text-xs text-gray-500">{owes > 0 ? F.owes : owes < 0 ? F.credit : F.colBalance}</p>
        <p className={`mt-1 text-xl font-bold ${owes > 0 ? 'text-red-700' : 'text-green-700'}`}>{owes === 0 ? F.settled : money(Math.abs(owes))}</p>
      </div>
      {[
        [F.dueSoFar, money(balance.due)],
        [F.paidTotal, money(balance.paid)],
        [F.upcoming, money(balance.upcoming)],
      ].map(([k, v]) => (
        <div key={k} className="rounded-lg border bg-white p-4">
          <p className="text-xs text-gray-500">{k}</p>
          <p className="mt-1 text-lg font-semibold">{v}</p>
        </div>
      ))}
    </div>
  );
}
