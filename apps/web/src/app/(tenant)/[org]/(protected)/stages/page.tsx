import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';

// Replaces wep-eqraa-center/admin/stages. Write access is admin-only (see
// stages_write_admin in 0002_identity_academic_core.sql) - the "code"
// column (0012) feeds the suggested student-code numbering on
// students/new.
export default async function StagesPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data: stages } = await supabase
    .from('stages')
    .select('id, name, code, sort_order')
    .eq('organization_id', org.id)
    .order('sort_order');

  const isAdmin = org.myRole === 'admin';

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">المراحل</h1>
        {isAdmin && (
          <a href="/stages/new" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
            + إضافة مرحلة
          </a>
        )}
      </div>
      <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
        <thead className="bg-gray-50 text-right">
          <tr>
            <th className="px-4 py-2">الترتيب</th>
            <th className="px-4 py-2">الاسم</th>
            <th className="px-4 py-2">الكود</th>
            {isAdmin && <th className="px-4 py-2"></th>}
          </tr>
        </thead>
        <tbody>
          {(stages ?? []).map((s) => (
            <tr key={s.id} className="border-t">
              <td className="px-4 py-2">{s.sort_order}</td>
              <td className="px-4 py-2">{s.name}</td>
              <td className="px-4 py-2">{s.code ?? '—'}</td>
              {isAdmin && (
                <td className="px-4 py-2 text-left">
                  <a href={`/stages/${s.id}`} className="text-brand hover:underline">
                    تعديل
                  </a>
                </td>
              )}
            </tr>
          ))}
          {!stages?.length && (
            <tr>
              <td colSpan={isAdmin ? 4 : 3} className="px-4 py-6 text-center text-gray-400">
                لا يوجد مراحل بعد
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
