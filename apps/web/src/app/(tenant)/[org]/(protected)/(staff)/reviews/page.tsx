import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { surahLabel } from '@/lib/quran/data';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

interface Due {
  student_id: string;
  student_name: string;
  circle_id: string | null;
  circle_name: string | null;
  surah: number;
  due: string;
  days_overdue: number;
  last_grade: string | null;
}

/** Spaced-review schedule: which surahs each student should review today (interval grows with good grades). */
export default async function ReviewsPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const { t: T, locale } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();
  const { data } = await supabase.rpc('due_reviews', { p_org: org.id, p_circle: null });
  const rows = (data ?? []) as Due[];

  const byCircle = new Map<string, Map<string, Due[]>>();
  for (const r of rows) {
    const c = r.circle_name ?? S.reviews.noCircle;
    if (!byCircle.has(c)) byCircle.set(c, new Map());
    const m = byCircle.get(c)!;
    m.set(r.student_id, [...(m.get(r.student_id) ?? []), r]);
  }

  return (
    <div className="max-w-3xl">
      <h1 className="mb-1 text-2xl font-bold">{S.reviews.title}</h1>
      <p className="mb-5 text-sm text-gray-500">
        {S.reviews.intro}
      </p>
      {!rows.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">{S.reviews.none}</p>}
      <div className="flex flex-col gap-4">
        {[...byCircle.entries()].map(([circle, students]) => (
          <section key={circle} className="rounded-lg border bg-white p-4">
            <h2 className="mb-3 font-semibold">{circle}</h2>
            <ul className="divide-y text-sm">
              {[...students.entries()].map(([id, list]) => (
                <li key={id} className="flex flex-wrap items-center justify-between gap-2 py-2">
                  <a href={`/students/${id}/report` as never} className="font-medium text-brand hover:underline">
                    {list[0].student_name}
                  </a>
                  <span className="flex flex-wrap gap-1.5">
                    {list.map((r) => (
                      <span key={r.surah} className={`rounded-full px-2 py-0.5 text-xs ${r.days_overdue > 3 ? 'bg-red-100 text-red-700' : 'bg-amber-100 text-amber-800'}`}>
                        {surahLabel(r.surah, locale)}
                        {r.days_overdue > 0 ? fmt(S.reviews.overdue, { n: r.days_overdue }) : ''}
                      </span>
                    ))}
                  </span>
                </li>
              ))}
            </ul>
          </section>
        ))}
      </div>
    </div>
  );
}
