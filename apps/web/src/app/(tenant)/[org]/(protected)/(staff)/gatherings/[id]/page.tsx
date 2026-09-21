import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import {
  updateGathering,
  addGatheringEntry,
  deleteGatheringEntry,
  matchGatheringEntry,
  skipGatheringEntry,
  unmatchGatheringEntry,
} from '@/lib/gatherings/actions';

interface Entry {
  id: string;
  raw_name: string;
  status: 'pending' | 'matched' | 'skipped';
  matched_name: string | null;
  matched_code: string | null;
  matched_circle: string | null;
}
interface Detail {
  id: string;
  title: string;
  activity_type_id: string | null;
  activity_type_label: string | null;
  session_date: string;
  location: string | null;
  notes: string | null;
  status: string;
  teacher_name: string | null;
  is_admin: boolean;
  entries: Entry[];
}
interface Suggestion {
  entry_id: string;
  suggestions: { student_id: string; full_name: string; code: string; circle: string | null; score: number }[];
}

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

export default async function GatheringPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ ok?: string; error?: string }>;
}) {
  const { org: slug, id } = await params;
  const { ok, error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data } = await supabase.rpc('gathering_detail', { p_gathering: id });
  const g = data as Detail | null;
  if (!g) notFound();
  const back = `/gatherings/${id}`;

  const [{ data: sugData }, { data: students }, { data: types }] = await Promise.all([
    g.is_admin ? supabase.rpc('admin_suggest_gathering_matches', { p_gathering: id }) : Promise.resolve({ data: [] }),
    g.is_admin ? supabase.from('students_profile').select('id, full_name, student_code').eq('organization_id', org.id).eq('status', 'active').order('full_name').limit(1000) : Promise.resolve({ data: [] }),
    g.is_admin ? supabase.from('activity_types').select('id, name').eq('organization_id', org.id).order('name') : Promise.resolve({ data: [] }),
  ]);
  const suggestions = new Map(((sugData ?? []) as Suggestion[]).map((s) => [s.entry_id, s.suggestions]));
  const pending = g.entries.filter((e) => e.status === 'pending').length;

  return (
    <div className="max-w-3xl">
      <a href={'/gatherings' as never} className="text-sm text-brand hover:underline">← المجالس</a>
      <h1 className="mb-1 mt-2 text-2xl font-bold">{g.title}</h1>
      <p className="mb-4 text-sm text-gray-500">
        {new Date(g.session_date).toLocaleDateString('ar')}
        {g.activity_type_label ? ` · ${g.activity_type_label}` : ''}
        {g.location ? ` · ${g.location}` : ''} · رفعه {g.teacher_name ?? '—'} ·{' '}
        <b className={g.status === 'reviewed' ? 'text-green-700' : 'text-amber-700'}>{g.status === 'reviewed' ? 'تمت المراجعة' : `بانتظار الربط (${pending})`}</b>
      </p>
      {g.notes && <p className="mb-4 rounded bg-gray-50 px-3 py-2 text-sm text-gray-600">{g.notes}</p>}
      {ok && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{ok}</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      {g.is_admin && (
        <details className="mb-5 rounded-lg border bg-white">
          <summary className="cursor-pointer px-4 py-2 text-sm font-semibold">تعديل بيانات النشاط</summary>
          <form action={updateGathering} className="grid gap-3 border-t p-4 sm:grid-cols-2">
            <input type="hidden" name="id" value={g.id} />
            <label className="text-sm font-medium text-gray-700 sm:col-span-2">
              الاسم
              <input name="title" defaultValue={g.title} required className={field} />
            </label>
            <label className="text-sm font-medium text-gray-700">
              النوع
              <select name="type" defaultValue={g.activity_type_id ?? ''} className={field}>
                <option value="">— بدون —</option>
                {((types ?? []) as { id: string; name: string }[]).map((t) => (
                  <option key={t.id} value={t.id}>{t.name}</option>
                ))}
              </select>
            </label>
            <label className="text-sm font-medium text-gray-700">
              التاريخ
              <input type="date" name="date" defaultValue={g.session_date} required className={field} />
            </label>
            <label className="text-sm font-medium text-gray-700">
              المكان
              <input name="location" defaultValue={g.location ?? ''} className={field} />
            </label>
            <label className="text-sm font-medium text-gray-700">
              ملاحظات
              <input name="notes" defaultValue={g.notes ?? ''} className={field} />
            </label>
            <SubmitButton className="self-start rounded bg-brand px-4 py-2 text-sm text-white" pendingText="...">حفظ</SubmitButton>
          </form>
        </details>
      )}

      <section className="rounded-lg border bg-white p-4">
        <h2 className="mb-3 font-semibold">الأسماء ({g.entries.length})</h2>
        <ul className="divide-y text-sm">
          {g.entries.map((e) => (
            <li key={e.id} className="py-3">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <span className="font-medium">{e.raw_name}</span>
                <span className="flex items-center gap-2 text-xs">
                  {e.status === 'matched' && <span className="rounded bg-green-100 px-2 py-0.5 text-green-700">رُبط: {e.matched_name} {e.matched_code ? `(${e.matched_code})` : ''}{e.matched_circle ? ` · ${e.matched_circle}` : ''}</span>}
                  {e.status === 'skipped' && <span className="rounded bg-gray-100 px-2 py-0.5 text-gray-600">تُجوهل</span>}
                  {e.status === 'pending' && <span className="rounded bg-amber-100 px-2 py-0.5 text-amber-800">بانتظار الربط</span>}
                </span>
              </div>

              {g.is_admin && e.status === 'pending' && (
                <div className="mt-2 flex flex-col gap-2">
                  {(suggestions.get(e.id) ?? []).length > 0 && (
                    <div className="flex flex-wrap gap-1.5">
                      {(suggestions.get(e.id) ?? []).map((s) => (
                        <form key={s.student_id} action={matchGatheringEntry}>
                          <input type="hidden" name="entryId" value={e.id} />
                          <input type="hidden" name="studentId" value={s.student_id} />
                          <input type="hidden" name="back" value={back} />
                          <button className="rounded-full border border-brand/40 bg-brand/5 px-3 py-1 text-xs text-brand hover:bg-brand/10">
                            {s.full_name} {s.circle ? `· ${s.circle}` : ''} ({Math.round(s.score * 100)}%)
                          </button>
                        </form>
                      ))}
                    </div>
                  )}
                  <div className="flex flex-wrap items-center gap-2">
                    <form action={matchGatheringEntry} className="flex items-center gap-2">
                      <input type="hidden" name="entryId" value={e.id} />
                      <input type="hidden" name="back" value={back} />
                      <select name="studentId" required defaultValue="" className="max-w-[16rem] rounded border px-2 py-1 text-xs">
                        <option value="" disabled>اختر الطالب…</option>
                        {((students ?? []) as { id: string; full_name: string; student_code: string }[]).map((s) => (
                          <option key={s.id} value={s.id}>{s.full_name} ({s.student_code})</option>
                        ))}
                      </select>
                      <SubmitButton className="rounded bg-brand px-3 py-1 text-xs text-white" pendingText="...">ربط</SubmitButton>
                    </form>
                    <form action={skipGatheringEntry}>
                      <input type="hidden" name="entryId" value={e.id} />
                      <input type="hidden" name="back" value={back} />
                      <button className="rounded border px-3 py-1 text-xs text-gray-600 hover:bg-gray-50">تجاهل</button>
                    </form>
                  </div>
                </div>
              )}

              <div className="mt-1 flex gap-2">
                {g.is_admin && e.status !== 'pending' && (
                  <form action={unmatchGatheringEntry}>
                    <input type="hidden" name="entryId" value={e.id} />
                    <input type="hidden" name="back" value={back} />
                    <button className="text-xs text-gray-500 hover:underline">إلغاء الربط</button>
                  </form>
                )}
                {(g.is_admin || e.status === 'pending') && (
                  <form action={deleteGatheringEntry}>
                    <input type="hidden" name="entryId" value={e.id} />
                    <input type="hidden" name="back" value={back} />
                    <button className="text-xs text-red-500 hover:underline">حذف الاسم</button>
                  </form>
                )}
              </div>
            </li>
          ))}
        </ul>

        <form action={addGatheringEntry} className="mt-4 flex gap-2 border-t pt-4">
          <input type="hidden" name="gatheringId" value={g.id} />
          <input name="name" required maxLength={120} placeholder="إضافة اسم آخر" className="flex-1 rounded border px-3 py-2 text-sm" />
          <SubmitButton className="rounded border px-4 py-2 text-sm text-brand" pendingText="...">إضافة</SubmitButton>
        </form>
      </section>
    </div>
  );
}
