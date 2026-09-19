import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { SerdPartsFields } from '@/components/serd-parts-fields';
import { scheduleSerd } from '../actions';

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

export default async function ScheduleSerdPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const [{ data: setup }, { data: students }, { data: members }] = await Promise.all([
    supabase.rpc('serd_grading_setup', { p_org: org.id }),
    supabase.from('students_profile').select('id, full_name, student_code').eq('organization_id', org.id).order('full_name'),
    supabase.rpc('list_org_members', { org_id: org.id }),
  ]);
  const s = setup as { default_denominators: number[]; stages: { denominators: number[] }[] } | null;
  const dens = Array.from(
    new Set([1, ...(s?.default_denominators ?? []), ...(s?.stages ?? []).flatMap((x) => x.denominators)]),
  );
  const teachers = (
    (members ?? []) as { user_id: string; role: string; status: string; full_name: string | null; email: string | null }[]
  ).filter((m) => m.role === 'teacher' && m.status === 'active');

  return (
    <div className="max-w-2xl">
      <a href="/serd" className="text-sm text-brand hover:underline">
        ← السرد
      </a>
      <h1 className="mb-1 mt-2 text-2xl font-bold">جدولة سرد</h1>
      <p className="mb-4 text-sm text-gray-500">مهمة تظهر للمعلمين ليرصدها من يتفرغ لها، أو تُسند لمعلم بعينه.</p>
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={scheduleSerd} className="flex flex-col gap-4 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />
        <label className="text-sm font-medium text-gray-700">
          الطالب
          <select name="studentId" required defaultValue="" className={field}>
            <option value="" disabled>
              اختر الطالب
            </option>
            {(students ?? []).map((st) => (
              <option key={st.id} value={st.id}>
                {st.full_name} ({st.student_code})
              </option>
            ))}
          </select>
        </label>
        <label className="text-sm font-medium text-gray-700">
          الموعد
          <input type="date" name="date" defaultValue={new Date().toISOString().slice(0, 10)} className={field} />
        </label>
        <div>
          <p className="mb-1 text-sm font-medium text-gray-700">الأجزاء المطلوبة</p>
          <SerdPartsFields denominators={dens} />
        </div>
        <label className="text-sm font-medium text-gray-700">
          إسناد إلى معلم
          <select name="teacherId" defaultValue="" className={field}>
            <option value="">مفتوح لأي معلم</option>
            {teachers.map((t) => (
              <option key={t.user_id} value={t.user_id}>
                {t.full_name ?? t.email}
              </option>
            ))}
          </select>
        </label>
        <label className="text-sm font-medium text-gray-700">
          ملاحظات (اختياري)
          <textarea name="notes" rows={2} className={field} />
        </label>
        <SubmitButton
          className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الحفظ..."
        >
          جدولة السرد
        </SubmitButton>
      </form>
    </div>
  );
}
