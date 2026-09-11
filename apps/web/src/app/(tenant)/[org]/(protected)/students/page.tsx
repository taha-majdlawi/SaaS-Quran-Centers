import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';

// Replaces wep-eqraa-center/admin/students - list view. CRUD forms and the
// /detail subpage are left for the real implementation pass.
export default async function StudentsPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data: students } = await supabase
    .from('students_profile')
    .select('id, student_code, full_name, status')
    .eq('organization_id', org.id)
    .order('full_name');

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold">الطلاب</h1>
      <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
        <thead className="bg-gray-50 text-right">
          <tr>
            <th className="px-4 py-2">الرقم</th>
            <th className="px-4 py-2">الاسم</th>
            <th className="px-4 py-2">الحالة</th>
          </tr>
        </thead>
        <tbody>
          {(students ?? []).map((s) => (
            <tr key={s.id} className="border-t">
              <td className="px-4 py-2">{s.student_code}</td>
              <td className="px-4 py-2">{s.full_name}</td>
              <td className="px-4 py-2">{s.status}</td>
            </tr>
          ))}
          {!students?.length && (
            <tr>
              <td colSpan={3} className="px-4 py-6 text-center text-gray-400">
                لا يوجد طلاب بعد
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
