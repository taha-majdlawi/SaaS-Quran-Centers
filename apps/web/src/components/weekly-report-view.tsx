import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';
import { fmtDay } from '@/lib/reports/format';
import { Delta, passage, type RecRow } from '@/components/profile-views';
import { GoalCard, type GoalProgress } from '@/components/goal-card';

export interface WeeklyReport {
  student: { id: string; name: string; circle: string | null; teacher: string | null; next_plan: string | null; total_points: number };
  from: string;
  to: string;
  week: WeekNumbers;
  previous: WeekNumbers;
  goal: GoalProgress;
  note: { body: string; at: string; by: string | null } | null;
  last_recitation: RecRow | null;
  smart: boolean;
}

interface WeekNumbers {
  recitations: number;
  points: number;
  new_memorization: number;
  reviews: number;
  pages: number;
  present: number;
  days: number;
}

const r1 = (n: number) => String(Math.round(Number(n) * 10) / 10);

/** One week of a student against the week before, the goal, and the teacher's note. */
export async function WeeklyReportView({ r, orgId, nav }: { r: WeeklyReport; orgId: string; nav?: { prev: string; next: string | null } }) {
  const { t, locale } = await getI18n();
  const W = t.staff.weekly;
  const C = t.staff.compare;
  const lang = t.labels.dateLocale;
  const w = r.week;
  const p = r.previous;
  const rows: [string, React.ReactNode, React.ReactNode, React.ReactNode][] = [
    [W.recitations, w.recitations, p.recitations, <Delta key="a" now={w.recitations} prev={p.recitations} labels={C} />],
    [W.newPages, r1(w.pages), r1(p.pages), <Delta key="b" now={w.pages} prev={p.pages} labels={C} />],
    [W.reviews, w.reviews, p.reviews, <Delta key="c" now={w.reviews} prev={p.reviews} labels={C} />],
    [W.points, w.points, p.points, <Delta key="d" now={w.points} prev={p.points} labels={C} />],
    [
      W.attendance,
      w.days ? fmt(W.attV, { present: w.present, days: w.days }) : '—',
      p.days ? fmt(W.attV, { present: p.present, days: p.days }) : '—',
      w.days && p.days ? <Delta key="e" now={Math.round((100 * w.present) / w.days)} prev={Math.round((100 * p.present) / p.days)} points labels={C} /> : null,
    ],
  ];
  return (
    <div className="flex flex-col gap-4">
      <div>
        <h2 className="text-xl font-bold">{r.student.name}</h2>
        <p className="text-sm text-gray-500">
          {fmt(W.period, { from: fmtDay(r.from, lang), to: fmtDay(r.to, lang) })}
          {r.student.circle && ` · ${r.student.circle}`}
          {r.student.teacher && ` · ${r.student.teacher}`}
        </p>
        {nav && (
          <div className="mt-2 flex gap-4 text-sm print:hidden">
            <a href={nav.prev as never} className="text-brand hover:underline">{W.prevWeek}</a>
            {nav.next && <a href={nav.next as never} className="text-brand hover:underline">{W.nextWeek}</a>}
          </div>
        )}
      </div>

      <section className="overflow-hidden rounded-xl border bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-3 py-2 text-start"></th>
              <th className="px-3 py-2 text-start">{W.thisWeek}</th>
              <th className="px-3 py-2 text-start text-gray-500">{W.lastWeek}</th>
              <th className="px-3 py-2 text-start"></th>
            </tr>
          </thead>
          <tbody>
            {rows.map(([label, a, b, d]) => (
              <tr key={label} className="border-t">
                <td className="px-3 py-2 text-gray-600">{label}</td>
                <td className="px-3 py-2 text-lg font-bold text-brand">{a}</td>
                <td className="px-3 py-2 text-gray-500">{b}</td>
                <td className="px-3 py-2">{d}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <GoalCard g={r.goal} orgId={orgId} studentId={r.student.id} back="" />

      <section className="rounded-xl border bg-white p-4 text-sm">
        <h3 className="mb-2 font-semibold">{W.teacherNote}</h3>
        {r.note ? (
          <>
            <p className="whitespace-pre-wrap rounded bg-amber-50 p-3">{r.note.body}</p>
            <p className="mt-1 text-xs text-gray-400">
              {r.note.by ?? ''} · {fmtDay(r.note.at, lang)}
            </p>
          </>
        ) : (
          <p className="text-gray-400">{W.noNote}</p>
        )}
        {r.student.next_plan && (
          <>
            <h3 className="mb-1 mt-4 font-semibold">{W.nextPlan}</h3>
            <p className="whitespace-pre-wrap">{r.student.next_plan}</p>
          </>
        )}
        {r.last_recitation && (
          <p className="mt-4 text-xs text-gray-500">
            {W.lastRecitation}: {t.labels.recitationType[r.last_recitation.type] ?? r.last_recitation.type} · {passage(r.last_recitation, locale)} ·{' '}
            {fmtDay(r.last_recitation.at, lang)}
          </p>
        )}
      </section>
    </div>
  );
}

/** yyyy-mm-dd of a date shifted by [days]. */
export const shiftDay = (iso: string, days: number) => {
  const d = new Date(`${iso}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
};
