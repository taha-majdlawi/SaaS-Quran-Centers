import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { SURAH_NAMES } from '@/lib/quran/data';
import { updateRecitation } from '../actions';

const TYPES: [string, string][] = [
  ['new_memorization', 'حفظ جديد'],
  ['recent_review', 'مراجعة قريبة'],
  ['distant_review', 'مراجعة بعيدة'],
];

const input = 'mt-1 w-full rounded border px-3 py-2 text-sm';

export default async function EditRecitationPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string; rid: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug, id, rid } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const [{ data: entry }, { data: grades }] = await Promise.all([
    supabase
      .from('daily_achievements')
      .select('id, achievement_type, surah_from, ayah_from, ayah_to, grade, notes')
      .eq('id', rid)
      .eq('student_id', id)
      .maybeSingle(),
    supabase
      .from('recitation_grades')
      .select('key, label, points')
      .eq('organization_id', org.id)
      .eq('is_active', true)
      .order('sort_order'),
  ]);
  if (!entry) notFound();

  return (
    <div className="max-w-xl">
      <a href={`/students/${id}/recitations`} className="text-sm text-brand hover:underline">
        ← رجوع
      </a>
      <h1 className="mb-6 mt-2 text-2xl font-bold">تعديل التسميع</h1>
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={updateRecitation} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="id" value={entry.id} />
        <input type="hidden" name="studentId" value={id} />
        <label className="text-sm font-medium text-gray-700">
          نوع الإنجاز
          <select name="type" defaultValue={entry.achievement_type} className={input}>
            {TYPES.map(([v, t]) => (
              <option key={v} value={v}>
                {t}
              </option>
            ))}
          </select>
        </label>
        <div className="grid grid-cols-[1fr_5rem_5rem] items-end gap-3">
          <label className="text-sm font-medium text-gray-700">
            السورة
            <select name="surah" defaultValue={entry.surah_from} className={input}>
              {SURAH_NAMES.map((n, i) => (
                <option key={i + 1} value={i + 1}>
                  {i + 1}. {n}
                </option>
              ))}
            </select>
          </label>
          <label className="text-sm font-medium text-gray-700">
            من آية
            <input type="number" name="ayahFrom" min={1} defaultValue={entry.ayah_from} className={input} />
          </label>
          <label className="text-sm font-medium text-gray-700">
            إلى آية
            <input type="number" name="ayahTo" min={1} defaultValue={entry.ayah_to} className={input} />
          </label>
        </div>
        <fieldset className="text-sm font-medium text-gray-700">
          <legend className="mb-1">تقييم التلاوة</legend>
          <div className="flex flex-wrap gap-3">
            {(grades ?? []).map((g) => (
              <label key={g.key} className="flex items-center gap-1 rounded border px-3 py-2">
                <input type="radio" name="grade" value={g.key} defaultChecked={g.key === entry.grade} required /> {g.label} ·{' '}
                {g.points}
              </label>
            ))}
          </div>
        </fieldset>
        <label className="text-sm font-medium text-gray-700">
          ملاحظات الشيخ
          <textarea name="notes" rows={2} defaultValue={entry.notes ?? ''} className={input} />
        </label>
        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الحفظ..."
        >
          حفظ التعديل
        </SubmitButton>
      </form>
    </div>
  );
}
