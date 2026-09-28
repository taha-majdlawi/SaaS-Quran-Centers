import { JUZ_NAMES, fmtDate, juzEquivalent, partsLabel, type SerdRow } from '@/lib/serd/format';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

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
export async function SerdSummaryCard({ summary }: { summary: SerdSummary | null }) {
  const { t, locale } = await getI18n();
  const c = t.serdCard;
  const lang = t.labels.dateLocale;
  if (!summary || summary.sessions_count === 0) {
    return <p className="rounded-lg border bg-white p-4 text-sm text-gray-400">{c.none}</p>;
  }
  return (
    <div className="rounded-lg border bg-white p-4 text-sm">
      <div className="mb-3 grid grid-cols-2 gap-2 sm:grid-cols-4">
        {[
          [c.sessions, summary.sessions_count],
          [c.average, summary.average_score == null ? '—' : `${summary.average_score}%`],
          [c.best, summary.best_score == null ? '—' : `${summary.best_score}%`],
          [c.covered, fmt(c.juzCount, { n: juzEquivalent(summary.eighths_total) })],
        ].map(([label, value]) => (
          <div key={String(label)} className="rounded bg-gray-50 p-2 text-center">
            <p className="text-base font-bold">{value}</p>
            <p className="text-xs text-gray-500">{label}</p>
          </div>
        ))}
      </div>
      {summary.juz_done.length > 0 && (
        <p className="mb-1">
          <b>{c.complete}</b> {summary.juz_done.map((j) => (locale === 'ar' ? `${j} (${JUZ_NAMES[j - 1]})` : String(j))).join(t.labels.listSep)}
        </p>
      )}
      {summary.juz_progress.length > 0 && (
        <p className="mb-2 text-gray-600">
          <b>{c.partial}</b> {summary.juz_progress.map((p) => fmt(c.partialItem, { juz: p.juz, e: p.eighths })).join(t.labels.listSep)}
        </p>
      )}
      <ul className="flex flex-col gap-1">
        {summary.sessions.slice(0, 6).map((s) => (
          <li key={s.id} className="flex justify-between rounded bg-gray-50 px-3 py-1.5">
            <span>
              {partsLabel(s.parts, t.labels)} <span className="text-xs text-gray-500">· {fmtDate(s.session_date, lang)}</span>
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
