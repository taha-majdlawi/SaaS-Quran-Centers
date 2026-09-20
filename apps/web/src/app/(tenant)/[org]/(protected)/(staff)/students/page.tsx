import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { deleteStudent } from './actions';

const STATUS_LABELS: Record<string, string> = {
  active: 'نشط',
  paused: 'متوقف',
  graduated: 'تخرّج',
  withdrawn: 'منسحب',
};

// Replaces wep-eqraa-center/admin/students - list + real add/edit/delete
// (see actions.ts, new/page.tsx, [id]/page.tsx).
export default async function StudentsPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ createdId?: string; createdPassword?: string }>;
}) {
  const { org: slug } = await params;
  const { createdId, createdPassword } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data: students } = await supabase
    .from('students_profile')
    .select('id, student_code, full_name, status, circles(name)')
    .eq('organization_id', org.id)
    .order('full_name');

  return (
    <div>
      {createdId && createdPassword && (
        <div className="mb-6 rounded-lg border border-green-200 bg-green-50 p-4 text-sm">
          <p className="mb-2 font-semibold text-green-800">تم إنشاء حساب الطالب - أعطه بيانات الدخول الآن:</p>
          <p dir="ltr" className="font-mono text-green-900">
            {org.slug} / {createdId} / {createdPassword}
          </p>
          <p className="mt-2 text-xs text-green-700">
            رمز المركز، ثم رقم الطالب، ثم كلمة السر. هذا العرض الوحيد لكلمة السر - انسخها الآن.
          </p>
        </div>
      )}
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">الطلاب</h1>
      {org.myPermissions.includes('students') && (
        <div className="mb-4 flex gap-2 text-sm">
          <a href="/students/import" className="rounded border px-3 py-1.5 text-brand hover:bg-gray-50">
            استيراد من CSV
          </a>
          <a href="/students/export" className="rounded border px-3 py-1.5 text-brand hover:bg-gray-50">
            تصدير CSV
          </a>
        </div>
      )}
        <a href="/students/new" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
          + إضافة طالب
        </a>
      </div>
      <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
        <thead className="bg-gray-50 text-right">
          <tr>
            <th className="px-4 py-2">الرقم</th>
            <th className="px-4 py-2">الاسم</th>
            <th className="px-4 py-2">الحلقة</th>
            <th className="px-4 py-2">الحالة</th>
            <th className="px-4 py-2"></th>
          </tr>
        </thead>
        <tbody>
          {(students ?? []).map((s) => (
            <tr key={s.id} className="border-t">
              <td className="px-4 py-2">{s.student_code}</td>
              <td className="px-4 py-2">{s.full_name}</td>
              <td className="px-4 py-2">{(s.circles as unknown as { name: string } | null)?.name ?? '—'}</td>
              <td className="px-4 py-2">{STATUS_LABELS[s.status] ?? s.status}</td>
              <td className="px-4 py-2 text-left">
                <div className="flex items-center justify-end gap-3">
                  <a href={`/students/${s.id}/recitations`} className="text-brand hover:underline">
                    تسميع
                  </a>
                  <a href={`/students/${s.id}`} className="text-brand hover:underline">
                    تعديل
                  </a>
                  <form action={deleteStudent}>
                    <input type="hidden" name="id" value={s.id} />
                    <ConfirmSubmitButton
                      confirmMessage={`متأكد إنك بدك تحذف "${s.full_name}"؟ رح يتحذف ملفه بالكامل (حضور، تسميع، نقاط...) ولا يمكن التراجع.`}
                      pendingText="جاري الحذف..."
                      className="text-red-600 hover:underline"
                    >
                      حذف
                    </ConfirmSubmitButton>
                  </form>
                </div>
              </td>
            </tr>
          ))}
          {!students?.length && (
            <tr>
              <td colSpan={5} className="px-4 py-6 text-center text-gray-400">
                لا يوجد طلاب بعد
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
