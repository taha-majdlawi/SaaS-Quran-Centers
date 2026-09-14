import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';

const ACTION_LABELS: Record<string, string> = { delete: 'حذف', update: 'تعديل', create: 'إضافة' };
const TABLE_LABELS: Record<string, string> = {
  students_profile: 'طالب',
  circles: 'حلقة',
  stages: 'مرحلة',
  serd_sessions: 'جلسة سرد',
};

interface AuditRow {
  id: string;
  actor_id: string;
  action: string;
  entity_table: string;
  entity_id: string;
  created_at: string;
}

interface MemberRow {
  user_id: string;
  full_name: string | null;
  email: string | null;
}

// Admin-only (audit_log_select_admin RLS). Currently logs deletions of
// students/circles/stages/serd sessions - see logAudit() call sites.
export default async function AuditPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const [{ data: entries }, { data: members }] = await Promise.all([
    supabase
      .from('audit_log')
      .select('id, actor_id, action, entity_table, entity_id, created_at')
      .eq('organization_id', org.id)
      .order('created_at', { ascending: false })
      .limit(100),
    supabase.rpc('list_org_members', { org_id: org.id }),
  ]);

  const nameByUserId = new Map(
    ((members ?? []) as MemberRow[]).map((m) => [m.user_id, m.full_name ?? m.email ?? '—']),
  );

  return (
    <div>
      <h1 className="mb-1 text-2xl font-bold">سجل العمليات</h1>
      <p className="mb-6 text-sm text-gray-500">آخر 100 عملية حذف/تعديل حساسة بالمركز.</p>

      <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
        <thead className="bg-gray-50 text-right">
          <tr>
            <th className="px-4 py-2">التاريخ</th>
            <th className="px-4 py-2">من قام بالعملية</th>
            <th className="px-4 py-2">العملية</th>
            <th className="px-4 py-2">على</th>
          </tr>
        </thead>
        <tbody>
          {((entries ?? []) as AuditRow[]).map((e) => (
            <tr key={e.id} className="border-t">
              <td className="px-4 py-2">{new Date(e.created_at).toLocaleString('ar')}</td>
              <td className="px-4 py-2">{nameByUserId.get(e.actor_id) ?? '—'}</td>
              <td className="px-4 py-2">{ACTION_LABELS[e.action] ?? e.action}</td>
              <td className="px-4 py-2">{TABLE_LABELS[e.entity_table] ?? e.entity_table}</td>
            </tr>
          ))}
          {!entries?.length && (
            <tr>
              <td colSpan={4} className="px-4 py-6 text-center text-gray-400">
                لا يوجد عمليات مسجّلة بعد
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
