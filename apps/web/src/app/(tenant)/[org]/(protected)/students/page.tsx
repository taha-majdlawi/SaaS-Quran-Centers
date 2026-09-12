import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';

const STATUS_LABELS: Record<string, string> = {
  active: 'نشط',
  paused: 'متوقف',
  graduated: 'تخرّج',
  withdrawn: 'منسحب',
};

// Replaces wep-eqraa-center/admin/students - list + real add/edit/delete
// (see actions.ts, new/page.tsx, [id]/page.tsx).
export default async function StudentsPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data: students } = await supabase
    .from('students_profile')
    .select('id, student_code, full_name, status, circles(name)')
    .eq('organization_id', org.id)
    .order('full_name');

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">الطلاب</h1>
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
                <a href={`/students/${s.id}`} className="text-brand hover:underline">
                  تعديل
                </a>
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
