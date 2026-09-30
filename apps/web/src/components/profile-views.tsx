import { surahLabel } from '@/lib/quran/data';
import { fmtDay } from '@/lib/reports/format';

// Building blocks shared by the student / teacher / circle profile pages.

export const initials = (name: string | null | undefined) =>
  (name ?? '?')
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((w) => w[0])
    .join('');

/** The big card at the top: avatar, name, a line under it, chips and actions. */
export function ProfileHeader({
  name,
  subtitle,
  chips,
  actions,
}: {
  name: string;
  subtitle?: React.ReactNode;
  chips?: React.ReactNode;
  actions?: React.ReactNode;
}) {
  return (
    <section className="mb-6 overflow-hidden rounded-2xl border bg-white">
      <div className="h-16 bg-brand/90" />
      <div className="flex flex-wrap items-end gap-4 px-5 pb-5">
        <div className="-mt-9 flex h-[72px] w-[72px] shrink-0 items-center justify-center rounded-full border-4 border-white bg-brand text-2xl font-bold text-white shadow">
          {initials(name)}
        </div>
        <div className="min-w-0 flex-1 pt-3">
          <h1 className="truncate text-2xl font-bold">{name}</h1>
          {subtitle && <div className="mt-0.5 text-sm text-gray-500">{subtitle}</div>}
          {chips && <div className="mt-2 flex flex-wrap gap-2">{chips}</div>}
        </div>
        {actions && <div className="flex flex-wrap gap-2 print:hidden">{actions}</div>}
      </div>
    </section>
  );
}

export function Chip({ children, tone = 'gray' }: { children: React.ReactNode; tone?: 'gray' | 'green' | 'amber' | 'red' | 'brand' }) {
  const tones = {
    gray: 'bg-gray-100 text-gray-700',
    green: 'bg-green-50 text-green-700',
    amber: 'bg-amber-50 text-amber-700',
    red: 'bg-red-50 text-red-700',
    brand: 'bg-brand/10 text-brand',
  };
  return <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold ${tones[tone]}`}>{children}</span>;
}

export function ActionLink({ href, children, primary }: { href: string; children: React.ReactNode; primary?: boolean }) {
  return (
    <a
      href={href as never}
      className={
        primary
          ? 'rounded-lg bg-brand px-4 py-2 text-sm font-semibold text-white hover:opacity-90'
          : 'rounded-lg border px-4 py-2 text-sm font-semibold text-brand hover:bg-gray-50'
      }
    >
      {children}
    </a>
  );
}

export function Stat({ label, value, hint }: { label: string; value: React.ReactNode; hint?: React.ReactNode }) {
  return (
    <div className="rounded-xl border bg-white p-4">
      <p className="text-xs text-gray-500">{label}</p>
      <p className="mt-1 text-2xl font-bold text-brand">{value}</p>
      {hint && <p className="mt-0.5 text-xs text-gray-400">{hint}</p>}
    </div>
  );
}

export function StatGrid({ children }: { children: React.ReactNode }) {
  return <div className="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">{children}</div>;
}

export function Panel({ title, children, className = '', flush }: { title: string; children: React.ReactNode; className?: string; flush?: boolean }) {
  return (
    <section className={`overflow-hidden rounded-xl border bg-white ${className}`}>
      <h2 className="border-b px-4 py-2.5 text-sm font-semibold">{title}</h2>
      <div className={flush ? '' : 'p-4'}>{children}</div>
    </section>
  );
}

/** Label / value rows. Empty values show a dash. */
export function Facts({ rows }: { rows: [string, React.ReactNode][] }) {
  return (
    <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-2 text-sm">
      {rows.map(([k, v]) => (
        <div key={k} className="contents">
          <dt className="text-gray-500">{k}</dt>
          <dd className="min-w-0 break-words font-medium">{v === null || v === undefined || v === '' ? '—' : v}</dd>
        </div>
      ))}
    </dl>
  );
}

/** Simple bars, one per day that had recitations. */
export function DailyBars({ daily, lang }: { daily: { date: string; recitations: number }[]; lang: string }) {
  if (!daily.length) return <p className="text-sm text-gray-400">—</p>;
  const max = Math.max(1, ...daily.map((d) => d.recitations));
  return (
    <div className="flex h-28 items-end gap-1">
      {daily.map((d) => (
        <div key={d.date} className="group relative flex h-full flex-1 flex-col items-center justify-end" title={`${fmtDay(d.date, lang)}: ${d.recitations}`}>
          <div className="w-full min-w-1 rounded-t bg-brand/80 group-hover:bg-brand" style={{ height: `${Math.max(4, (d.recitations / max) * 100)}%` }} />
        </div>
      ))}
    </div>
  );
}

export function CountList({ items }: { items: { label: string; count: number }[] }) {
  if (!items.length) return <p className="text-sm text-gray-400">—</p>;
  const total = Math.max(1, items.reduce((a, x) => a + x.count, 0));
  return (
    <ul className="flex flex-col gap-2 text-sm">
      {items.map((x) => (
        <li key={x.label}>
          <div className="flex justify-between">
            <span>{x.label}</span>
            <b>{x.count}</b>
          </div>
          <div className="mt-1 h-1.5 rounded-full bg-gray-100">
            <div className="h-1.5 rounded-full bg-brand" style={{ width: `${(x.count / total) * 100}%` }} />
          </div>
        </li>
      ))}
    </ul>
  );
}

export interface RecRow {
  at: string;
  type: string;
  surah_from: number | null;
  ayah_from: number | null;
  surah_to: number | null;
  ayah_to: number | null;
  grade: string | number | null;
  points: number;
  student_id?: string;
  student?: string;
  by?: string | null;
}

export const passage = (row: RecRow, locale: string) => {
  if (row.surah_from == null) return '—';
  const a = surahLabel(row.surah_from, locale);
  if (row.surah_to == null || row.surah_to === row.surah_from) return `${a} (${row.ayah_from}–${row.ayah_to})`;
  return `${a} ${row.ayah_from} ${locale === 'ar' ? '←' : '→'} ${surahLabel(row.surah_to, locale)} ${row.ayah_to}`;
};

const th = 'px-3 py-2 text-start font-semibold';
const td = 'px-3 py-2';

export function RecitationTable({
  rows,
  labels,
  typeLabels,
  locale,
  lang,
  showStudent,
  showBy,
  empty,
  gradeLabels,
}: {
  rows: RecRow[];
  labels: { colDate: string; colStudent: string; colType: string; colPassage: string; colGrade: string; colPoints: string; colBy: string };
  typeLabels: Record<string, string>;
  locale: string;
  lang: string;
  showStudent?: boolean;
  showBy?: boolean;
  empty: string;
  /** grade key -> the center's label */
  gradeLabels?: Record<string, string>;
}) {
  const cols = 5 + (showStudent ? 1 : 0) + (showBy ? 1 : 0);
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead className="bg-gray-50">
          <tr>
            <th className={th}>{labels.colDate}</th>
            {showStudent && <th className={th}>{labels.colStudent}</th>}
            <th className={th}>{labels.colType}</th>
            <th className={th}>{labels.colPassage}</th>
            <th className={th}>{labels.colGrade}</th>
            <th className={th}>{labels.colPoints}</th>
            {showBy && <th className={th}>{labels.colBy}</th>}
          </tr>
        </thead>
        <tbody>
          {rows.map((x, i) => (
            <tr key={i} className="border-t">
              <td className={`${td} whitespace-nowrap`}>{fmtDay(x.at, lang)}</td>
              {showStudent && (
                <td className={td}>
                  {x.student_id ? (
                    <a href={`/students/${x.student_id}` as never} className="font-medium text-brand hover:underline">
                      {x.student ?? '—'}
                    </a>
                  ) : (
                    x.student ?? '—'
                  )}
                </td>
              )}
              <td className={td}>{typeLabels[x.type] ?? x.type}</td>
              <td className={td}>{passage(x, locale)}</td>
              <td className={td}>{x.grade == null ? '—' : gradeLabels?.[String(x.grade)] ?? x.grade}</td>
              <td className={td}>{x.points}</td>
              {showBy && <td className={td}>{x.by ?? '—'}</td>}
            </tr>
          ))}
          {!rows.length && (
            <tr>
              <td colSpan={cols} className={`${td} py-6 text-center text-gray-400`}>
                {empty}
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

/** The center's grade names, for [RecitationTable]. */
export const gradeLabelMap = (rows: unknown): Record<string, string> =>
  Object.fromEntries(((rows ?? []) as { key: string; label: string }[]).map((g) => [g.key, g.label]));

/** "Today" / "Yesterday" / "5 days ago" / a date. */
export function relDay(iso: string | null | undefined, L: { today: string; yesterday: string; daysAgo: string; never: string }, lang: string) {
  if (!iso) return L.never;
  const d = new Date(iso);
  const days = Math.floor((Date.now() - d.getTime()) / 86400000);
  if (days <= 0) return L.today;
  if (days === 1) return L.yesterday;
  if (days < 30) return L.daysAgo.replace('{n}', String(days));
  return fmtDay(iso, lang);
}
