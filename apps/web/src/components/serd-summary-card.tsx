import { JUZ_NAMES, fmtDate, juzEquivalent, partsLabel, type SerdRow } from '@/lib/serd/format';

export interface SerdSummary {
  sessions_count: number;
  average_score: number | null;
  best_score: number | null;
  last_date: string | null;
  total_points: number;
  juz_done: number[];
  juz_progress: { juz: number; juz_name: string; eighths: number }[];
  eighths_total: number;
  sessions: SerdRow[];
}

/**
 * A student's APPROVED serd record. A juz is listed as done only when every
 * eighth of it is covered, so a half never reads as a whole juz.
 */
export function SerdSummaryCard({ summary }: { summary: SerdSummary | null }) {
  if (!summary || summary.sessions_count === 0) {
    return <p className="rounded-lg border bg-white p-4 text-sm text-gray-400">لا يوجد سرد معتمد بعد</p>;
  }
  return (
    <div className="rounded-lg border bg-white p-4 text-sm">
      <div className="mb-3 grid grid-cols-2 gap-2 sm:grid-cols-4">
        {[
          ['جلسات معتمدة', summary.sessions_count],
          ['المتوسط', summary.average_score == null ? '—' : `${summary.average_score}%`],
          ['الأفضل', summary.best_score == null ? '—' : `${summary.best_score}%`],
          ['ما سُرد', `${juzEquivalent(summary.eighths_total)} جزء`],
        ].map(([label, value]) => (
          <div key={String(label)} className="rounded bg-gray-50 p-2 text-center">
            <p className="text-base font-bold">{value}</p>
            <p className="text-xs text-gray-500">{label}</p>
          </div>
        ))}
      </div>
      {summary.juz_done.length > 0 && (
        <p className="mb-1">
          <b>أجزاء مكتملة:</b> {summary.juz_done.map((j) => `${j} (${JUZ_NAMES[j - 1]})`).join('، ')}
        </p>
      )}
      {summary.juz_progress.length > 0 && (
        <p className="mb-2 text-gray-600">
          <b>جزئي:</b> {summary.juz_progress.map((p) => `جزء ${p.juz} — ${p.eighths}/8`).join('، ')}
        </p>
      )}
      <ul className="flex flex-col gap-1">
        {summary.sessions.slice(0, 6).map((s) => (
          <li key={s.id} className="flex justify-between rounded bg-gray-50 px-3 py-1.5">
            <span>
              {partsLabel(s.parts)} <span className="text-xs text-gray-500">· {fmtDate(s.session_date)}</span>
            </span>
            <span>
              {s.score_percent}% <span className="text-brand">+{s.points_awarded}</span>
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}
