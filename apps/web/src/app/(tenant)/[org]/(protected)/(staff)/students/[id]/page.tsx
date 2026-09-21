import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { updateStudent, deleteStudent } from '../actions';
import { addStudentNote } from '@/lib/insights/actions';
import { createGuardianForStudent, setStudentGuardian } from './guardian-actions';

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
  searchParams: Promise<{
    error?: string;
    guardianCreated?: string;
    guardianPassword?: string;
    guardianLinked?: string;
    ok?: string;
  }>;
}) {
  const { org: slug, id } = await params;
  const { error, guardianCreated, guardianPassword, guardianLinked, ok } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const isAdmin = org.myRole === 'admin';

  const [{ data: student }, { data: circles }, { data: members }] = await Promise.all([
    supabase
      .from('students_profile')
      .select('id, full_name, student_code, birth_date, circle_id, status, phone, whatsapp, address, guardian_member_id')
      .eq('organization_id', org.id)
      .eq('id', id)
      .maybeSingle(),
    supabase.from('circles').select('id, name').eq('organization_id', org.id).order('name'),
    isAdmin ? supabase.rpc('list_org_members', { org_id: org.id }) : Promise.resolve({ data: [] }),
  ]);
  const guardians = ((members ?? []) as { id: string; role: string; full_name: string | null; email: string | null }[])
    .filter((m) => m.role === 'guardian');
  const currentGuardian = guardians.find((g) => g.id === student?.guardian_member_id);
  const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';
  const { data: notesData } = await supabase.rpc('list_student_notes', { p_org: org.id, p_student: id });
  const notes = (notesData ?? []) as { id: string; body: string; visibility: string; created_at: string; author: string | null }[];

  if (!student) notFound();

  return (
    <div className="max-w-lg">
      <h1 className="mb-2 text-2xl font-bold">تعديل بيانات طالب</h1>
      <a href={`/students/${student.id}/report` as never} className="mb-6 inline-block text-sm text-brand hover:underline">
        تقرير الطالب (طباعة)
      </a>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {ok && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{ok}</p>}

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
          الجوال
          <input name="phone" defaultValue={student.phone ?? ''} dir="ltr" className={field} />
        </label>
        <label className="text-sm font-medium text-gray-700">
          واتساب
          <input name="whatsapp" defaultValue={student.whatsapp ?? ''} dir="ltr" className={field} />
        </label>
        <label className="text-sm font-medium text-gray-700">
          العنوان
          <input name="address" defaultValue={student.address ?? ''} className={field} />
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

      {isAdmin && (
        <section className="mt-6 rounded-lg border bg-white p-6">
          <h2 className="mb-1 font-semibold">ولي الأمر</h2>
          <p className="mb-3 text-sm text-gray-500">
            {currentGuardian
              ? `المرتبط حاليًا: ${currentGuardian.full_name ?? currentGuardian.email ?? '—'}`
              : 'لا يوجد ولي أمر مرتبط بهذا الطالب.'}
          </p>

          {guardianCreated && (
            <p className="mb-3 rounded bg-green-50 px-3 py-2 text-sm text-green-700">
              تم إنشاء حساب ولي الأمر — رمز المركز: {slug} · الدخول: {guardianCreated} · كلمة السر: {guardianPassword}
              <br />
              <span className="text-xs">هذا العرض الوحيد لكلمة السر، سلّمها الآن.</span>
            </p>
          )}
          {guardianLinked && <p className="mb-3 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم تحديث الربط ✓</p>}

          <form action={setStudentGuardian} className="mb-4 flex items-end gap-2">
            <input type="hidden" name="orgId" value={org.id} />
            <input type="hidden" name="studentId" value={student.id} />
            <label className="flex-1 text-sm font-medium text-gray-700">
              ربط بولي أمر موجود
              <select name="guardianMemberId" defaultValue={student.guardian_member_id ?? ''} className={field}>
                <option value="">— بدون —</option>
                {guardians.map((g) => (
                  <option key={g.id} value={g.id}>
                    {g.full_name ?? g.email}
                  </option>
                ))}
              </select>
            </label>
            <SubmitButton className="rounded border px-4 py-2 text-sm font-semibold text-brand" pendingText="...">
              حفظ الربط
            </SubmitButton>
          </form>

          {!student.guardian_member_id && (
            <form action={createGuardianForStudent} className="flex flex-col gap-2 border-t pt-4">
              <input type="hidden" name="orgId" value={org.id} />
              <input type="hidden" name="studentId" value={student.id} />
              <p className="text-sm font-medium text-gray-700">أو أنشئ حساب ولي أمر جديد</p>
              <input name="fullName" required placeholder="اسم ولي الأمر" className={field} />
              <input name="identifier" required placeholder="رقم الدخول أو البريد" dir="ltr" className={field} />
              <input name="phone" placeholder="الجوال (اختياري)" dir="ltr" className={field} />
              <input name="password" required minLength={8} placeholder="كلمة السر" className={field} />
              <SubmitButton
                className="self-start rounded bg-brand px-4 py-2 text-sm font-semibold text-white"
                pendingText="جاري الإنشاء..."
              >
                إنشاء حساب ولي الأمر
              </SubmitButton>
            </form>
          )}
        </section>
      )}

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
      <section className="mt-8 rounded-lg border bg-white p-6">
        <h2 className="mb-1 font-semibold">ملاحظات المعلم</h2>
        <p className="mb-3 text-xs text-gray-500">سجل يُضاف إليه ولا يُعدَّل، لا يراه الطالب. الملاحظة «ظاهرة لولي الأمر» يراها وليّه فقط.</p>
        <form action={addStudentNote} className="mb-4 flex flex-col gap-2">
          <input type="hidden" name="orgId" value={org.id} />
          <input type="hidden" name="studentId" value={student.id} />
          <input type="hidden" name="back" value={`/students/${student.id}`} />
          <textarea name="body" required maxLength={1000} rows={2} placeholder="مثال: يستعجل في أواخر الآيات، يحتاج حلقة أبطأ" className="w-full rounded border px-3 py-2 text-sm" />
          <div className="flex items-center gap-3">
            <select name="visibility" className="rounded border px-2 py-1.5 text-sm">
              <option value="staff_only">للإدارة والمعلمين فقط</option>
              <option value="guardian_visible">ظاهرة لولي الأمر</option>
            </select>
            <SubmitButton className="rounded bg-brand px-4 py-1.5 text-sm text-white" pendingText="...">إضافة</SubmitButton>
          </div>
        </form>
        <ul className="flex flex-col gap-2 text-sm">
          {notes.map((n) => (
            <li key={n.id} className="rounded bg-gray-50 p-3">
              <p>{n.body}</p>
              <p className="mt-1 text-xs text-gray-400">
                {n.author ?? '—'} · {new Date(n.created_at).toLocaleDateString('ar')}
                {n.visibility === 'guardian_visible' ? ' · ظاهرة لولي الأمر' : ''}
              </p>
            </li>
          ))}
          {!notes.length && <li className="text-gray-400">لا ملاحظات بعد</li>}
        </ul>
      </section>
    </div>
  );
}
