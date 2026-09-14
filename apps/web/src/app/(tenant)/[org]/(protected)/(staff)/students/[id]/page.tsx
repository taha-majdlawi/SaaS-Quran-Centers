import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { updateStudent, deleteStudent } from '../actions';

const STATUS_OPTIONS = [
  { value: 'active', label: 'نشط' },
  { value: 'paused', label: 'متوقف' },
  { value: 'graduated', label: 'تخرّج' },
  { value: 'withdrawn', label: 'منسحب' },
];

export default async function EditStudentPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug, id } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const [{ data: student }, { data: circles }] = await Promise.all([
    supabase
      .from('students_profile')
      .select('id, full_name, student_code, birth_date, circle_id, status')
      .eq('organization_id', org.id)
      .eq('id', id)
      .maybeSingle(),
    supabase.from('circles').select('id, name').eq('organization_id', org.id).order('name'),
  ]);

  if (!student) notFound();

  return (
    <div className="max-w-lg">
      <h1 className="mb-6 text-2xl font-bold">تعديل بيانات طالب</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={updateStudent} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="id" value={student.id} />

        <label className="text-sm font-medium text-gray-700">
          الاسم الكامل
          <input
            name="fullName"
            required
            defaultValue={student.full_name}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          رقم الطالب
          <input
            name="studentCode"
            required
            defaultValue={student.student_code}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          تاريخ الميلاد
          <input
            type="date"
            name="birthDate"
            defaultValue={student.birth_date ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          الحلقة
          <select
            name="circleId"
            required
            defaultValue={student.circle_id ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          >
            <option value="" disabled>
              اختر الحلقة
            </option>
            {(circles ?? []).map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </label>

        <label className="text-sm font-medium text-gray-700">
          الحالة
          <select
            name="status"
            defaultValue={student.status}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          >
            {STATUS_OPTIONS.map((s) => (
              <option key={s.value} value={s.value}>
                {s.label}
              </option>
            ))}
          </select>
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الحفظ..."
        >
          حفظ التعديلات
        </SubmitButton>
      </form>

      <form action={deleteStudent} className="mt-3">
        <input type="hidden" name="id" value={student.id} />
        <ConfirmSubmitButton
          confirmMessage={`متأكد إنك بدك تحذف "${student.full_name}"؟ رح يتحذف ملفه بالكامل (حضور، تسميع، نقاط...) ولا يمكن التراجع.`}
          pendingText="جاري الحذف..."
          className="rounded border border-red-200 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
        >
          حذف الطالب
        </ConfirmSubmitButton>
      </form>
    </div>
  );
}
