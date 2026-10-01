import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';
import { surahLabel } from '@/lib/quran/data';
import { SubmitButton } from '@/components/submit-button';
import { approveAllReviews, approveReview, skipReview } from '@/lib/goals/review-actions';

export interface ReviewPlan {
  page_from: number;
  page_to: number;
  pages: number;
  surah_from: number;
  ayah_from: number;
  surah_to: number;
  ayah_to: number;
  status: 'suggested' | 'approved' | 'done' | 'skipped';
  approved: boolean;
  cycle_start?: boolean;
}

export interface ReviewRow {
  student_id: string;
  name: string;
  circle_id: string;
  circle: string;
  plan: ReviewPlan;
}

export async function reviewRange(p: Pick<ReviewPlan, 'surah_from' | 'ayah_from' | 'surah_to' | 'ayah_to'>) {
  const { t, locale } = await getI18n();
  return fmt(t.staff.rplan.range, { from: `${surahLabel(p.surah_from, locale)} ${p.ayah_from}`, to: `${surahLabel(p.surah_to, locale)} ${p.ayah_to}` });
}

/** The teacher's daily review portions, by circle, with approve / approve all. */
export async function ReviewPlansSection({ rows, orgId, back }: { rows: ReviewRow[]; orgId: string; back: string }) {
  const { t } = await getI18n();
  const R = t.staff.rplan;
  const tone: Record<string, string> = { suggested: 'bg-gray-100 text-gray-600', approved: 'bg-brand/10 text-brand', done: 'bg-green-50 text-green-700' };
  const circles = [...new Map(rows.map((r) => [r.circle_id, r.circle])).entries()];
  const waiting = rows.filter((r) => !r.plan.approved).length;
  return (
    <section className="mb-8">
      <div className="mb-1 flex flex-wrap items-center justify-between gap-2">
        <h2 className="text-xl font-bold">{R.title}</h2>
        {waiting > 0 && (
          <form action={approveAllReviews}>
            <input type="hidden" name="orgId" value={orgId} />
            <input type="hidden" name="back" value={back} />
            <SubmitButton className="rounded bg-brand px-4 py-1.5 text-sm font-semibold text-white" pendingText="...">
              {R.approveAll} ({waiting})
            </SubmitButton>
          </form>
        )}
      </div>
      <p className="mb-4 text-sm text-gray-500">{R.hint}</p>
      {!rows.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">{R.none}</p>}
      <div className="flex flex-col gap-4">
        {await Promise.all(
          circles.map(async ([cid, cname]) => (
            <div key={cid} className="overflow-hidden rounded-lg border bg-white">
              <h3 className="border-b bg-gray-50 px-4 py-2 text-sm font-semibold">{cname}</h3>
              <ul className="divide-y text-sm">
                {await Promise.all(
                  rows
                    .filter((r) => r.circle_id === cid)
                    .map(async (r) => (
                      <li key={r.student_id} className="flex flex-wrap items-center justify-between gap-3 px-4 py-2.5">
                        <div className="min-w-0">
                          <a href={`/students/${r.student_id}` as never} className="font-semibold text-brand hover:underline">{r.name}</a>
                          <p className="text-gray-700">{await reviewRange(r.plan)}</p>
                          <p className="text-xs text-gray-400">
                            {fmt(R.pagesN, { n: r.plan.pages, a: r.plan.page_from, b: r.plan.page_to })}
                            {r.plan.cycle_start && r.plan.status === 'suggested' ? ` · ${R.cycleStart}` : ''}
                          </p>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className={`rounded-full px-2.5 py-0.5 text-xs font-semibold ${tone[r.plan.status] ?? ''}`}>{R.status[r.plan.status] ?? r.plan.status}</span>
                          {r.plan.status === 'suggested' && (
                            <form action={approveReview}>
                              <input type="hidden" name="orgId" value={orgId} />
                              <input type="hidden" name="studentId" value={r.student_id} />
                              <input type="hidden" name="back" value={back} />
                              <SubmitButton className="rounded border border-brand px-3 py-1 text-xs font-semibold text-brand hover:bg-brand/5" pendingText="...">
                                {R.approve}
                              </SubmitButton>
                            </form>
                          )}
                          {r.plan.status === 'approved' && (
                            <form action={skipReview}>
                              <input type="hidden" name="orgId" value={orgId} />
                              <input type="hidden" name="studentId" value={r.student_id} />
                              <input type="hidden" name="back" value={back} />
                              <SubmitButton className="text-xs text-gray-400 hover:text-red-600" pendingText="...">{R.cancel}</SubmitButton>
                            </form>
                          )}
                        </div>
                      </li>
                    )),
                )}
              </ul>
            </div>
          )),
        )}
      </div>
    </section>
  );
}

/** Today's approved portion (student profile, family home). */
export async function TodayReview({ plan }: { plan: (ReviewPlan & { plan_date?: string }) | null }) {
  if (!plan) return null;
  const { t } = await getI18n();
  const R = t.staff.rplan;
  const done = plan.status === 'done';
  return (
    <section className={`flex items-center gap-3 rounded-xl border p-4 text-sm ${done ? 'border-green-200 bg-green-50' : 'bg-white'}`}>
      <span className="text-2xl">{done ? '✅' : '🔁'}</span>
      <div className="min-w-0 flex-1">
        <p className="font-semibold">{R.today}</p>
        <p>{await reviewRange(plan)}</p>
        <p className="text-xs text-gray-500">{fmt(R.pagesN, { n: plan.pages, a: plan.page_from, b: plan.page_to })}</p>
      </div>
      {done && <span className="rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-semibold text-green-700">{R.status.done}</span>}
    </section>
  );
}
