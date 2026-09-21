import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { SURAH_NAMES } from '@/lib/quran/data';
import { submitExternalRecitation, deleteExternalRecitation, matchExternalRecitation, rejectExternalRecitation } from '@/lib/gatherings/actions';

const TYPES: Record<string, string> = { new_memorization: 'حفظ جديد', recent_review: 'مراجعة قريبة', distant_review: 'مراجعة بعيدة' };
const STATUS: Record<string, { label: string; cls: string }> = {
  pending: { label: 'بانتظار الربط', cls: 'bg-amber-100 text-amber-800' },
  matched: { label: 'رُبط', cls: 'bg-green-100 text-green-700' },
  rejected: { label: 'مرفوض', cls: 'bg-red-100 text-red-700' },
};

interface Req {
  id: string;
  raw_student_name: string;
  type: string;
  surah: number;
  ayah_from: number;
  ayah_to: number;
  grade: string;
  notes: string | null;
  recorded_at: string;
  status: string;
  teacher_name?: string | null;
  matched_name: string | null;
  reject_reason: string | null;
  points?: number | null;
  suggestions?: { student_id: string; full_name: string; code: string; circle: string | null; score: number }[];
}

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

/** A recitation heard from a student outside the teacher's circle: recorded by name, linked to the student by the admin. */
export default async function ExternalRecitationsPage({ params, searchParams }: { params: Promise<{ org: string }>; searchParams: Promise<{ ok?: string; error?: string }> }) {
  const { org: slug } = await params;
  const { ok, error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const isAdmin = org.myRole === 'admin';

  const [{ data: listData }, { data: grades }, { data: students }] = await Promise.all([
    isAdmin ? supabase.rpc('admin_list_external_recitations', { p_org: org.id, p_status: null }) : supabase.rpc('my_external_recitations', { p_org: org.id }),
    supabase.from('recitation_grades').select('key, label').eq('organization_id', org.id).eq('is_active', true).order('sort_order'),
    isAdmin ? supabase.from('students_profile').select('id, full_name, student_code').eq('organization_id', org.id).eq('status', 'active').order('full_name').limit(1000) : Promise.resolve({ data: [] }),
  ]);
  const rows = (listData ?? []) as Req[];
  const gradeLabel = new Map(((grades ?? []) as { key: string; label: string }[]).map((g) => [g.key, g.label]));
  const clientRef = crypto.randomUUID();

  return (
    <div className="max-w-3xl">
      <h1 className="mb-1 text-2xl font-bold">التسميع الخارجي</h1>
      <p className="mb-5 text-sm text-gray-500">
        سمعتَ من طالب ليس في حلقتك؟ سجّله باسمه. لا يُكتب التسميع في سجلّه حتى يربط المشرف الاسم بملف الطالب، وعندها يُحتسب بنفس نقاط المركز وباسمك.
      </p>
      {ok && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{ok}</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <details className="mb-6 rounded-lg border bg-white" open={!rows.length}>
        <summary className="cursor-pointer px-4 py-3 font-semibold">تسجيل تسميع جديد</summary>
        <form action={submitExternalRecitation} className="grid gap-3 border-t p-4 sm:grid-cols-2">
          <input type="hidden" name="orgId" value={org.id} />
          <input type="hidden" name="clientRef" value={clientRef} />
          <label className="text-sm font-medium text-gray-700 sm:col-span-2">
            اسم الطالب
            <input name="name" required maxLength={120} className={field} />
          </label>
          <label className="text-sm font-medium text-gray-700">
            النوع
            <select name="type" className={field}>
              {Object.entries(TYPES).map(([k, v]) => (
                <option key={k} value={k}>{v}</option>
              ))}
            </select>
          </label>
          <label className="text-sm font-medium text-gray-700">
            التقدير
            <select name="grade" className={field}>
              {((grades ?? []) as { key: string; label: string }[]).map((g) => (
                <option key={g.key} value={g.key}>{g.label}</option>
              ))}
            </select>
          </label>
          <label className="text-sm font-medium text-gray-700">
            السورة
            <select name="surah" className={field}>
              {SURAH_NAMES.map((n, i) => (
                <option key={n} value={i + 1}>{i + 1}. {n}</option>
              ))}
            </select>
          </label>
          <div className="grid grid-cols-2 gap-3">
            <label className="text-sm font-medium text-gray-700">
              من آية
              <input type="number" name="ayahFrom" min={1} defaultValue={1} required className={field} />
            </label>
            <label className="text-sm font-medium text-gray-700">
              إلى آية
              <input type="number" name="ayahTo" min={1} defaultValue={1} required className={field} />
            </label>
          </div>
          <label className="text-sm font-medium text-gray-700 sm:col-span-2">
            ملاحظات (اختياري)
            <input name="notes" className={field} />
          </label>
          <SubmitButton className="self-start rounded bg-brand px-5 py-2 text-sm text-white sm:col-span-2" pendingText="جاري الرفع...">رفع التسميع</SubmitButton>
        </form>
      </details>

      <div className="flex flex-col gap-3">
        {rows.map((r) => (
          <div key={r.id} className="rounded-lg border bg-white p-4">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div>
                <p className="font-semibold">{r.raw_student_name}</p>
                <p className="text-xs text-gray-500">
                  {TYPES[r.type] ?? r.type} · {SURAH_NAMES[r.surah - 1]} ({r.ayah_from}–{r.ayah_to}) · {gradeLabel.get(r.grade) ?? r.grade}
                  {r.teacher_name ? ` · ${r.teacher_name}` : ''} · {new Date(r.recorded_at).toLocaleDateString('ar')}
                </p>
                {r.notes && <p className="mt-1 text-xs text-gray-500">{r.notes}</p>}
              </div>
              <span className={`rounded px-2 py-0.5 text-xs ${STATUS[r.status]?.cls}`}>
                {STATUS[r.status]?.label}
                {r.status === 'matched' && r.matched_name ? `: ${r.matched_name}` : ''}
                {r.status === 'matched' && r.points != null ? ` (+${r.points})` : ''}
              </span>
            </div>
            {r.reject_reason && <p className="mt-1 text-xs text-red-600">السبب: {r.reject_reason}</p>}

            {isAdmin && r.status === 'pending' && (
              <div className="mt-3 flex flex-col gap-2 border-t pt-3">
                {(r.suggestions ?? []).length > 0 && (
                  <div className="flex flex-wrap gap-1.5">
                    {(r.suggestions ?? []).map((s) => (
                      <form key={s.student_id} action={matchExternalRecitation}>
                        <input type="hidden" name="id" value={r.id} />
                        <input type="hidden" name="studentId" value={s.student_id} />
                        <button className="rounded-full border border-brand/40 bg-brand/5 px-3 py-1 text-xs text-brand hover:bg-brand/10">
                          {s.full_name} {s.circle ? `· ${s.circle}` : ''} ({Math.round(s.score * 100)}%)
                        </button>
                      </form>
                    ))}
                  </div>
                )}
                <form action={matchExternalRecitation} className="flex flex-wrap items-center gap-2">
                  <input type="hidden" name="id" value={r.id} />
                  <select name="studentId" required defaultValue="" className="max-w-[16rem] rounded border px-2 py-1 text-xs">
                    <option value="" disabled>اختر الطالب…</option>
                    {((students ?? []) as { id: string; full_name: string; student_code: string }[]).map((s) => (
                      <option key={s.id} value={s.id}>{s.full_name} ({s.student_code})</option>
                    ))}
                  </select>
                  <SubmitButton className="rounded bg-brand px-3 py-1 text-xs text-white" pendingText="...">ربط وتسجيل</SubmitButton>
                </form>
                <form action={rejectExternalRecitation} className="flex items-center gap-2">
                  <input type="hidden" name="id" value={r.id} />
                  <input name="reason" placeholder="سبب الرفض (اختياري)" className="flex-1 rounded border px-2 py-1 text-xs" />
                  <button className="rounded border px-3 py-1 text-xs text-red-600 hover:bg-red-50">رفض</button>
                </form>
              </div>
            )}

            {(isAdmin ? r.status !== 'matched' : r.status === 'pending') && (
              <form action={deleteExternalRecitation} className="mt-2">
                <input type="hidden" name="id" value={r.id} />
                <ConfirmSubmitButton confirmMessage="حذف هذا الطلب؟" pendingText="..." className="text-xs text-red-500 hover:underline">حذف</ConfirmSubmitButton>
              </form>
            )}
          </div>
        ))}
        {!rows.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا طلبات بعد</p>}
      </div>
    </div>
  );
}
