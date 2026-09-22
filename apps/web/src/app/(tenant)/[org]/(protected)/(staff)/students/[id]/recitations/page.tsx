import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { SURAH_NAMES, AYAH_COUNTS } from '@/lib/quran/data';
import { SerdSummaryCard, type SerdSummary } from '@/components/serd-summary-card';
import { logRecitation, setStudentPlan, deleteRecitation } from './actions';

const TYPES: [string, string][] = [
  ['new_memorization', 'حفظ جديد'],
  ['recent_review', 'مراجعة قريبة'],
  ['distant_review', 'مراجعة بعيدة'],
];

const input = 'mt-1 w-full rounded border px-3 py-2 text-sm';

interface Recitation {
  id: string;
  achievement_type: string;
  surah_from: number;
  ayah_from: number;
  ayah_to: number;
  grade: string | null;
  points_awarded: number;
  notes: string | null;
  created_at: string;
}

export default async function StudentRecitationsPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ error?: string; saved?: string; planSaved?: string; deleted?: string; updated?: string; prefillSurah?: string; prefillType?: string }>;
}) {
  const { org: slug, id } = await params;
  const { error, saved, planSaved, deleted, updated, prefillSurah, prefillType } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const [{ data: student }, { data: grades }, { data: recent }, { data: serdData }, { data: dueData }] = await Promise.all([
    supabase
      .from('students_profile')
      .select('id, full_name, student_code, total_points, next_plan')
      .eq('id', id)
      .eq('organization_id', org.id)
      .maybeSingle(),
    supabase
      .from('recitation_grades')
      .select('key, label, points')
      .eq('organization_id', org.id)
      .eq('is_active', true)
      .order('sort_order'),
    supabase
      .from('daily_achievements')
      .select('id, achievement_type, surah_from, ayah_from, ayah_to, grade, points_awarded, notes, created_at')
      .eq('student_id', id)
      .order('created_at', { ascending: false })
      .limit(20),
    supabase.rpc('serd_student_summary', { p_org: org.id, p_student: id }),
    supabase.rpc('student_due_reviews', { p_org: org.id, p_student: id }),
  ]);

  if (!student) notFound();

  const gradeLabel = new Map((grades ?? []).map((g) => [g.key as string, g.label as string]));
  const typeLabel = new Map(TYPES);
  const today = new Date().toISOString().slice(0, 10);
  const due = (dueData ?? []) as { surah: number; days_overdue: number }[];
  const chosenSurah = prefillSurah ? Number(prefillSurah) : null;

  return (
    <div className="max-w-2xl">
      <a href="/students" className="text-sm text-brand hover:underline">
        ← الطلاب
      </a>
      <h1 className="mb-1 mt-2 text-2xl font-bold">{student.full_name}</h1>
      <p className="mb-6 text-sm text-gray-500">
        {student.student_code} · {student.total_points} نقطة
      </p>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {saved && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم الحفظ ✓ +{saved} نقطة</p>}
      {planSaved && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم حفظ الخطة ✓</p>}
      {updated && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم تعديل التسميع ✓</p>}
      {deleted && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم حذف التسميع</p>}

      <form action={setStudentPlan} className="mb-6 flex flex-col gap-2 rounded-lg border bg-white p-4">
        <input type="hidden" name="orgId" value={org.id} />
        <input type="hidden" name="studentId" value={student.id} />
        <label className="text-sm font-medium text-gray-700">
          الخطة القادمة
          <textarea
            name="plan"
            rows={2}
            defaultValue={student.next_plan ?? ''}
            placeholder="مثال: حفظ سورة الملك من الآية 1 إلى 15"
            className={input}
          />
        </label>
        <SubmitButton
          className="self-start rounded border px-4 py-1.5 text-sm font-semibold text-brand disabled:opacity-50"
          pendingText="جاري الحفظ..."
        >
          حفظ الخطة
        </SubmitButton>
      </form>

      {due.length > 0 && (
        <div className="mb-4 flex flex-wrap items-center gap-2 rounded-lg border border-amber-200 bg-amber-50 p-3 text-sm">
          <span className="font-semibold text-amber-800">مراجعة مستحقة:</span>
          {due.map((d) => (
            <a
              key={d.surah}
              href={`?prefillSurah=${d.surah}&prefillType=recent_review#log` as never}
              className="rounded-full border border-amber-300 bg-white px-3 py-1 text-amber-800 hover:bg-amber-100"
            >
              {SURAH_NAMES[d.surah - 1]}
              {d.days_overdue > 0 ? ` · متأخرة ${d.days_overdue}` : ''}
            </a>
          ))}
        </div>
      )}

      <form id="log" action={logRecitation} className="mb-8 flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />
        <input type="hidden" name="studentId" value={student.id} />
        <h2 className="font-semibold">تسجيل إنجاز يومي</h2>
        {chosenSurah && <p className="-mt-1 text-xs text-amber-700">مُعبّأ من جدول المراجعة المقترح — عدّله إن لزم</p>}

        <div className="grid grid-cols-2 gap-3">
          <label className="text-sm font-medium text-gray-700">
            تاريخ التسميع
            <input type="date" name="date" defaultValue={today} max={today} className={input} />
          </label>
          <label className="text-sm font-medium text-gray-700">
            نوع الإنجاز
            <select name="type" defaultValue={prefillType ?? TYPES[0][0]} className={input}>
              {TYPES.map(([value, text]) => (
                <option key={value} value={value}>
                  {text}
                </option>
              ))}
            </select>
          </label>
        </div>

        {[0, 1, 2].map((i) => (
          <div key={i} className="grid grid-cols-[1fr_5rem_5rem] items-end gap-3 rounded bg-gray-50 p-3">
            <label className="text-sm font-medium text-gray-700">
              {i === 0 ? 'السورة' : `سورة إضافية (${i})`}
              <select name="surah" defaultValue={i === 0 && chosenSurah ? String(chosenSurah) : ''} className={input}>
                <option value="">{i === 0 ? 'اختر السورة' : '—'}</option>
                {SURAH_NAMES.map((n, idx) => (
                  <option key={idx + 1} value={idx + 1}>
                    {idx + 1}. {n} ({AYAH_COUNTS[idx]} آية)
                  </option>
                ))}
              </select>
            </label>
            <label className="text-sm font-medium text-gray-700">
              من آية
              <input type="number" name="ayahFrom" min={1} defaultValue={1} className={input} />
            </label>
            <label className="text-sm font-medium text-gray-700">
              إلى آية
              <input type="number" name="ayahTo" min={1} defaultValue={i === 0 && chosenSurah ? AYAH_COUNTS[chosenSurah - 1] : undefined} className={input} />
            </label>
          </div>
        ))}

        <fieldset className="text-sm font-medium text-gray-700">
          <legend className="mb-1">تقييم التلاوة</legend>
          <div className="flex flex-wrap gap-3">
            {(grades ?? []).map((g) => (
              <label key={g.key} className="flex items-center gap-1 rounded border px-3 py-2">
                <input type="radio" name="grade" value={g.key} required /> {g.label} · {g.points}
              </label>
            ))}
          </div>
        </fieldset>

        <label className="text-sm font-medium text-gray-700">
          ملاحظات الشيخ (اختياري)
          <textarea name="notes" rows={2} className={input} />
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الحفظ..."
        >
          حفظ التسميع
        </SubmitButton>
      </form>

      <h2 className="mb-3 font-semibold">السرد القرآني</h2>
      <div className="mb-8">
        <SerdSummaryCard summary={serdData as SerdSummary | null} />
      </div>

      <h2 className="mb-3 font-semibold">آخر التسميعات</h2>
      <div className="flex flex-col gap-2">
        {((recent ?? []) as Recitation[]).map((r) => (
          <div key={r.id} className="rounded-lg border bg-white p-3 text-sm">
            <div className="flex items-center justify-between">
              <span className="font-semibold">
                {SURAH_NAMES[r.surah_from - 1]} ({r.ayah_from}–{r.ayah_to})
              </span>
              <span className="text-brand">+{r.points_awarded}</span>
            </div>
            <div className="mt-1 flex items-center gap-3 text-xs">
              <a href={`/students/${student.id}/recitations/${r.id}`} className="text-brand hover:underline">
                تعديل
              </a>
              <form action={deleteRecitation}>
                <input type="hidden" name="id" value={r.id} />
                <input type="hidden" name="studentId" value={student.id} />
                <button className="text-red-600 hover:underline">حذف</button>
              </form>
            </div>
            <p className="text-xs text-gray-500">
              {typeLabel.get(r.achievement_type)} · {gradeLabel.get(r.grade ?? '') ?? r.grade ?? '—'} ·{' '}
              {new Date(r.created_at).toLocaleDateString('ar')}
            </p>
            {r.notes && <p className="mt-1 text-xs text-gray-600">{r.notes}</p>}
          </div>
        ))}
        {!recent?.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا يوجد تسميعات بعد</p>}
      </div>
    </div>
  );
}
