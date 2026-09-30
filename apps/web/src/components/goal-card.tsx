import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';
import { fmtDay } from '@/lib/reports/format';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { clearStudentGoal, saveStudentGoal } from '@/lib/goals/actions';

export interface GoalProgress {
  goal: { pages_per_day: number; target_pages: number; start_date: string; note: string | null; set_by: string | null } | null;
  memorized_pages: number;
  memorized_percent: number;
  target_pages: number;
  remaining_pages: number;
  pace: number;
  expected_since_start: number | null;
  actual_since_start: number | null;
  status: 'ahead' | 'on_track' | 'behind' | 'done' | null;
  forecast_date: string | null;
  goal_date: string | null;
  can_edit: boolean;
}

const TONE: Record<string, string> = {
  ahead: 'bg-green-50 text-green-700',
  on_track: 'bg-brand/10 text-brand',
  behind: 'bg-amber-50 text-amber-800',
  done: 'bg-green-100 text-green-800',
};

const num = (n: number | null | undefined) => (n == null ? '—' : String(Math.round(Number(n) * 10) / 10));

/** Where the student stands against their goal, and when they will finish. With `edit`, the form to set it. */
export async function GoalCard({ g, orgId, studentId, back, edit }: { g: GoalProgress; orgId: string; studentId: string; back: string; edit?: boolean }) {
  const { t } = await getI18n();
  const G = t.staff.goal;
  const lang = t.labels.dateLocale;
  const target = g.goal?.target_pages ?? 604;
  const pct = Math.min(100, (Number(g.memorized_pages) / target) * 100);
  const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';
  const today = new Date().toISOString().slice(0, 10);

  return (
    <section className="overflow-hidden rounded-xl border bg-white">
      <div className="flex items-center justify-between gap-2 border-b px-4 py-2.5">
        <h2 className="text-sm font-semibold">{G.title}</h2>
        {g.status && <span className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${TONE[g.status]}`}>{G.status[g.status]}</span>}
      </div>
      <div className="p-4">
        <div className="mb-1 flex items-baseline justify-between text-sm">
          <span className="text-gray-500">{G.memorized}</span>
          <span className="font-semibold">{fmt(G.pagesOf, { n: num(g.memorized_pages), total: target })}</span>
        </div>
        <div className="h-3 overflow-hidden rounded-full bg-gray-100">
          <div className="h-3 rounded-full bg-brand" style={{ width: `${Math.max(pct, 1)}%` }} />
        </div>
        <p className="mt-1 text-xs text-gray-400">{fmt(G.percentQuran, { p: num(g.memorized_percent) })}</p>

        <dl className="mt-4 grid grid-cols-2 gap-3 text-sm">
          <div>
            <dt className="text-xs text-gray-500">{G.pace}</dt>
            <dd className="font-semibold">{g.pace > 0 ? fmt(G.paceV, { n: num(g.pace) }) : '—'}</dd>
            <dd className="text-[11px] text-gray-400">{G.paceHint}</dd>
          </div>
          <div>
            <dt className="text-xs text-gray-500">{G.goalPace}</dt>
            <dd className="font-semibold">{g.goal ? fmt(G.goalPaceV, { n: num(g.goal.pages_per_day) }) : '—'}</dd>
            {g.goal?.set_by && <dd className="text-[11px] text-gray-400">{fmt(G.setBy, { name: g.goal.set_by })}</dd>}
          </div>
          {g.goal && g.expected_since_start != null && (
            <div className="col-span-2">
              <dt className="text-xs text-gray-500">{fmt(G.sinceStart, { date: fmtDay(g.goal.start_date, lang) })}</dt>
              <dd className="font-semibold">{fmt(G.sinceStartV, { actual: num(g.actual_since_start), expected: num(g.expected_since_start) })}</dd>
            </div>
          )}
          <div>
            <dt className="text-xs text-gray-500">{G.forecast}</dt>
            <dd className="font-semibold text-brand">{g.status === 'done' ? G.done : g.forecast_date ? fmtDay(g.forecast_date, lang) : G.noPace}</dd>
          </div>
          {g.goal && g.status !== 'done' && (
            <div>
              <dt className="text-xs text-gray-500">{G.forecastGoal}</dt>
              <dd className="font-semibold">{g.goal_date ? fmtDay(g.goal_date, lang) : '—'}</dd>
            </div>
          )}
        </dl>
        {g.goal?.note && <p className="mt-3 rounded bg-gray-50 p-2 text-xs text-gray-600">{g.goal.note}</p>}
        {!g.goal && <p className="mt-3 text-xs text-gray-400">{G.noGoal}</p>}

        {edit && g.can_edit && (
          <details className="mt-4 border-t pt-3 print:hidden" open={!g.goal}>
            <summary className="cursor-pointer text-sm font-semibold text-brand">{G.setTitle}</summary>
            <form action={saveStudentGoal} className="mt-3 grid grid-cols-2 gap-3">
              <input type="hidden" name="orgId" value={orgId} />
              <input type="hidden" name="studentId" value={studentId} />
              <input type="hidden" name="back" value={back} />
              <label className="text-xs text-gray-600">
                {G.pagesPerDay}
                <input type="number" name="pagesPerDay" step="0.25" min="0.25" max="20" required defaultValue={g.goal?.pages_per_day ?? 1} className={field} />
              </label>
              <label className="text-xs text-gray-600">
                {G.targetPages}
                <input type="number" name="targetPages" min="1" max="604" required defaultValue={g.goal?.target_pages ?? 604} className={field} />
                <span className="text-[11px] text-gray-400">{G.targetHint}</span>
              </label>
              <label className="text-xs text-gray-600">
                {G.startDate}
                <input type="date" name="startDate" defaultValue={g.goal?.start_date ?? today} className={field} />
              </label>
              <label className="text-xs text-gray-600">
                {G.note}
                <input name="note" maxLength={300} defaultValue={g.goal?.note ?? ''} className={field} />
              </label>
              <div className="col-span-2 flex items-center gap-3">
                <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText="...">{G.save}</SubmitButton>
              </div>
            </form>
            {g.goal && (
              <form action={clearStudentGoal} className="mt-2">
                <input type="hidden" name="orgId" value={orgId} />
                <input type="hidden" name="studentId" value={studentId} />
                <input type="hidden" name="back" value={back} />
                <ConfirmSubmitButton confirmMessage={G.clearConfirm} pendingText="..." className="text-xs text-red-600 hover:underline">
                  {G.clear}
                </ConfirmSubmitButton>
              </form>
            )}
          </details>
        )}
      </div>
    </section>
  );
}
