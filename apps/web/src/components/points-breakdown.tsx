import { SubmitButton } from '@/components/submit-button';
import { awardPoints, saveOpeningBalance, undoPointEntry } from '@/lib/points/actions';
import { fmt } from '@/lib/i18n/config';
import { fmtDay } from '@/lib/reports/format';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';

/** get_student_points_breakdown (0096) */
export interface PointsBreakdown {
  mode: 'per_recitation' | 'per_page';
  total_points: number;
  rows_sum: number;
  summary: { recitations: number; memorized_pages: number; revision_pages: number; attended_days: number; absent_days: number; serd_sessions: number };
  rows: { kind: 'opening' | 'recitation' | 'serd' | 'attendance' | 'bonus' | 'penalty'; type?: string; grade?: string; label?: string; count: number; pages?: number; points: number; note?: string | null }[];
  recent: { id: string; source: 'bonus' | 'penalty' | 'opening'; points: number; label: string | null; note: string | null; occurred_on: string; by: string | null; can_delete: boolean }[];
}

export interface PointReason {
  id: string;
  name: string;
  points: number;
  kind: 'bonus' | 'penalty';
}

const signed = (n: number) => (n > 0 ? `+${n}` : `${n}`);
const num = (n: number) => (Number.isInteger(n) ? `${n}` : n.toFixed(2).replace(/\.?0+$/, ''));

/**
 * "How did I earn my points": every source of the total, grouped (recitations by type x grade,
 * bonus / penalty by reason), always adding up to the total. On the staff profile it also holds
 * the teacher's add / deduct form, the latest entries (with undo) and, for the admin, the
 * opening balance.
 */
export function PointsBreakdownCard({
  data,
  T,
  lang,
  mine = false,
  staff,
}: {
  data: PointsBreakdown;
  T: Dictionary;
  lang: string;
  mine?: boolean;
  staff?: { orgId: string; studentId: string; back: string; reasons: PointReason[]; canAward: boolean; isAdmin: boolean };
}) {
  const P = T.staff.points;
  const kindLabel = (r: PointsBreakdown['rows'][number]) => {
    if (r.kind === 'recitation') return `${T.labels.recitationType[r.type ?? ''] ?? r.type} — ${r.label ?? r.grade ?? ''}`;
    if (r.kind === 'bonus' || r.kind === 'penalty') return `${P.kinds[r.kind]}: ${r.label || '—'}`;
    return P.kinds[r.kind] ?? r.kind;
  };
  const opening = data.rows.find((r) => r.kind === 'opening');
  const entries = data.recent.filter((e) => e.source !== 'opening');
  const sm = data.summary;
  const facts: [string, string][] = [
    [P.sumRecitations, `${sm.recitations}`],
    [P.sumMemPages, num(sm.memorized_pages)],
    [P.sumRevPages, num(sm.revision_pages)],
    [P.sumAttended, `${sm.attended_days}`],
    [P.sumAbsent, `${sm.absent_days}`],
  ];

  return (
    <section className="overflow-hidden rounded-xl border bg-white">
      <h2 className="flex items-center justify-between border-b px-4 py-2.5 text-sm font-semibold">
        <span>{mine ? P.bdMine : P.bdStaff}</span>
        <span dir="ltr" className="rounded-full bg-brand/10 px-2.5 py-0.5 text-brand">{data.total_points}</span>
      </h2>

      <div className="flex flex-wrap gap-x-5 gap-y-1 border-b bg-gray-50/60 px-4 py-2 text-xs text-gray-500">
        {facts.map(([k, v]) => (
          <span key={k}>
            {k}: <b className="text-gray-800">{v}</b>
          </span>
        ))}
      </div>

      {data.rows.length === 0 ? (
        <p className="px-4 py-6 text-center text-sm text-gray-400">{P.noPoints}</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-xs text-gray-500">
              <tr className="border-b">
                <th className="px-4 py-2 text-start font-medium">{P.colSource}</th>
                <th className="px-2 py-2 text-center font-medium">{P.colCount}</th>
                <th className="px-2 py-2 text-center font-medium">{P.colPages}</th>
                <th className="px-4 py-2 text-end font-medium">{P.colPoints}</th>
              </tr>
            </thead>
            <tbody>
              {data.rows.map((r, i) => (
                <tr key={i} className="border-b last:border-0">
                  <td className="px-4 py-2">
                    {kindLabel(r)}
                    {r.kind === 'opening' && r.note && <span className="block text-xs text-gray-400">{r.note}</span>}
                  </td>
                  <td className="px-2 py-2 text-center text-gray-600">{r.count}</td>
                  <td className="px-2 py-2 text-center text-gray-600">{r.pages != null && r.pages > 0 ? num(r.pages) : '—'}</td>
                  <td className={`px-4 py-2 text-end font-semibold ${r.points < 0 ? 'text-red-600' : 'text-gray-900'}`}>
                    <span dir="ltr">{signed(r.points)}</span>
                  </td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr className="bg-gray-50 font-bold">
                <td className="px-4 py-2" colSpan={3}>{P.total}</td>
                <td className="px-4 py-2 text-end"><span dir="ltr">{data.rows_sum}</span></td>
              </tr>
            </tfoot>
          </table>
        </div>
      )}
      {data.rows_sum !== data.total_points && !mine && (
        <p className="border-t bg-amber-50 px-4 py-2 text-xs text-amber-800">{fmt(P.mismatch, { sum: data.rows_sum, total: data.total_points })}</p>
      )}

      {staff && (
        <div className="grid gap-4 border-t p-4 md:grid-cols-2">
          {staff.canAward && (
            <form action={awardPoints} className="flex min-w-0 flex-col gap-2">
              <h3 className="text-sm font-semibold">{P.awardTitle}</h3>
              <input type="hidden" name="orgId" value={staff.orgId} />
              <input type="hidden" name="studentId" value={staff.studentId} />
              <input type="hidden" name="back" value={staff.back} />
              <input type="hidden" name="ref" value={crypto.randomUUID()} />
              {staff.reasons.length === 0 ? (
                <p className="text-sm text-gray-400">{P.noReasons}</p>
              ) : (
                <>
                  <div className="flex flex-wrap gap-2">
                    {staff.reasons.map((r) => (
                      <label
                        key={r.id}
                        className={`cursor-pointer rounded-full border px-3 py-1.5 text-sm has-[:checked]:text-white ${r.kind === 'bonus' ? 'border-green-200 text-green-800 has-[:checked]:border-green-600 has-[:checked]:bg-green-600' : 'border-red-200 text-red-700 has-[:checked]:border-red-600 has-[:checked]:bg-red-600'}`}
                      >
                        <input type="radio" name="reason" value={r.id} required className="sr-only" />
                        {r.name} <b dir="ltr">{r.kind === 'bonus' ? `+${r.points}` : `-${r.points}`}</b>
                      </label>
                    ))}
                  </div>
                  <input name="note" maxLength={500} placeholder={P.awardNote} className="rounded border px-3 py-2 text-sm" />
                  <SubmitButton className="self-start rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50" pendingText={T.staff.common.saving}>
                    {P.awardBtn}
                  </SubmitButton>
                </>
              )}
            </form>
          )}

          <div className="min-w-0">
            <h3 className="mb-2 text-sm font-semibold">{P.recentTitle}</h3>
            {entries.length === 0 ? (
              <p className="text-sm text-gray-400">—</p>
            ) : (
              <ul className="flex flex-col divide-y text-sm">
                {entries.map((e) => (
                  <li key={e.id} className="flex items-center gap-2 py-1.5">
                    <b className={`w-10 shrink-0 text-center ${e.points < 0 ? 'text-red-600' : 'text-green-700'}`} dir="ltr">{signed(e.points)}</b>
                    <span className="min-w-0 flex-1">
                      {e.label ?? '—'}
                      <span className="block truncate text-xs text-gray-400">
                        {fmtDay(e.occurred_on, lang)}
                        {e.by ? ` · ${fmt(P.byV, { name: e.by })}` : ''}
                        {e.note ? ` · ${e.note}` : ''}
                      </span>
                    </span>
                    {e.can_delete && (
                      <form action={undoPointEntry}>
                        <input type="hidden" name="orgId" value={staff.orgId} />
                        <input type="hidden" name="id" value={e.id} />
                        <input type="hidden" name="back" value={staff.back} />
                        <SubmitButton className="rounded border px-2 py-1 text-xs text-gray-600 hover:bg-gray-50">{P.undo}</SubmitButton>
                      </form>
                    )}
                  </li>
                ))}
              </ul>
            )}
            {staff.canAward && !staff.isAdmin && <p className="mt-2 text-xs text-gray-400">{P.undoHint}</p>}
          </div>

          {staff.isAdmin && (
            <form action={saveOpeningBalance} className="flex min-w-0 flex-col gap-2 md:col-span-2">
              <h3 className="text-sm font-semibold">{P.openingTitle}</h3>
              <p className="text-xs text-gray-500">{P.openingHint}</p>
              <input type="hidden" name="orgId" value={staff.orgId} />
              <input type="hidden" name="studentId" value={staff.studentId} />
              <input type="hidden" name="back" value={staff.back} />
              <div className="flex flex-wrap gap-2">
                <input type="number" dir="ltr" name="points" min={-100000} max={100000} defaultValue={opening?.points ?? 0} aria-label={P.openingTitle} className="w-28 rounded border px-3 py-2 text-sm" />
                <input name="note" maxLength={500} defaultValue={opening?.note ?? ''} placeholder={P.openingNote} className="min-w-0 flex-1 rounded border px-3 py-2 text-sm" />
                <SubmitButton className="rounded border border-brand px-4 py-2 text-sm font-semibold text-brand disabled:opacity-50" pendingText={T.staff.common.saving}>
                  {P.openingSave}
                </SubmitButton>
              </div>
            </form>
          )}
        </div>
      )}
    </section>
  );
}
