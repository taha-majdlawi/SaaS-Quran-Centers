import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';


interface MemberRow {
  user_id: string;
  role: string;
  full_name: string | null;
  email: string | null;
}

// Replaces wep-eqraa-center/admin/circles - list + real add/edit/delete
// (see actions.ts, new/page.tsx, [id]/page.tsx).
export default async function CirclesPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();

  const [{ data: circles }, { data: members }] = await Promise.all([
    supabase
      .from('circles')
      .select('id, name, capacity, status, teacher_id, stages(name)')
      .eq('organization_id', org.id)
      .order('name'),
    supabase.rpc('list_org_members', { org_id: org.id }),
  ]);

  const { data: assistData } = org.myRole === 'admin' ? await supabase.rpc('circle_assistants_list', { p_org: org.id }) : { data: [] };
  const assistantsByCircle = new Map<string, string[]>();
  for (const a of (assistData ?? []) as { circle_id: string; name: string | null }[]) {
    assistantsByCircle.set(a.circle_id, [...(assistantsByCircle.get(a.circle_id) ?? []), a.name ?? '—']);
  }

  const teacherNameByUserId = new Map(
    ((members ?? []) as MemberRow[]).map((m) => [m.user_id, m.full_name ?? m.email ?? '—']),
  );
  const isAdmin = org.myRole === 'admin';

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">{S.circles.title}</h1>
        {isAdmin && (
          <a href="/circles/new" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
            {S.circles.add}
          </a>
        )}
      </div>
      {!isAdmin && <p className="mb-4 text-sm text-gray-500">{S.circles.yoursOnly}</p>}
      <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
        <thead className="bg-gray-50 text-start">
          <tr>
            <th className="px-4 py-2">{S.circles.colName}</th>
            <th className="px-4 py-2">{S.circles.colStage}</th>
            <th className="px-4 py-2">{S.circles.colTeacher}</th>
            <th className="px-4 py-2">{S.circles.colCapacity}</th>
            <th className="px-4 py-2">{S.circles.colStatus}</th>
            <th className="px-4 py-2"></th>
          </tr>
        </thead>
        <tbody>
          {(circles ?? []).map((c) => (
            <tr key={c.id} className="border-t">
              <td className="px-4 py-2">{c.name}</td>
              <td className="px-4 py-2">{(c.stages as unknown as { name: string } | null)?.name ?? '—'}</td>
              <td className="px-4 py-2">{c.teacher_id ? teacherNameByUserId.get(c.teacher_id) ?? '—' : '—'}
                {(assistantsByCircle.get(c.id) ?? []).length > 0 && (
                  <span className="mt-0.5 block text-xs text-gray-500">{fmt(S.circles.assistant, { names: (assistantsByCircle.get(c.id) ?? []).join(T.labels.listSep) })}</span>
                )}
              </td>
              <td className="px-4 py-2">{c.capacity ?? '—'}</td>
              <td className="px-4 py-2">{S.circles.status[c.status] ?? c.status}</td>
              <td className="px-4 py-2 text-end">
                {isAdmin && (
                  <a href={`/circles/${c.id}`} className="text-brand hover:underline">
                    {S.common.edit}
                  </a>
                )}
              </td>
            </tr>
          ))}
          {!circles?.length && (
            <tr>
              <td colSpan={6} className="px-4 py-6 text-center text-gray-400">
                {S.circles.none}
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
