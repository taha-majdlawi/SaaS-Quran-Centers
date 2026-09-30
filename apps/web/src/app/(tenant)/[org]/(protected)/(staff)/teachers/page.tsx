import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { getI18n } from '@/lib/i18n/server';

interface MemberRow {
  id: string;
  user_id: string;
  role: string;
  full_name: string | null;
  email: string | null;
}

interface CircleRow {
  name: string;
  teacher_id: string | null;
}

// A "teacher" is an organization_members row with role='teacher' (added via
// the invitation flow in members/) - there is no separate teachers table.
// This page is a filtered, read-only view plus each teacher's assigned
// circles; assigning a circle to a teacher happens on the circle itself
// (circles/[id]).
export default async function TeachersPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();

  const [{ data: members, error: membersError }, { data: circles }] = await Promise.all([
    supabase.rpc('list_org_members', { org_id: org.id }),
    supabase.from('circles').select('name, teacher_id').eq('organization_id', org.id),
  ]);

  const teachers = ((members ?? []) as MemberRow[]).filter((m) => m.role === 'teacher');
  const isAdmin = org.myRole === 'admin';

  const circleNamesByTeacher = new Map<string, string[]>();
  ((circles ?? []) as CircleRow[]).forEach((c) => {
    if (!c.teacher_id) return;
    const list = circleNamesByTeacher.get(c.teacher_id) ?? [];
    list.push(c.name);
    circleNamesByTeacher.set(c.teacher_id, list);
  });

  return (
    <div>
      {membersError && (
        <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600" dir="ltr">
          {membersError.code}: {membersError.message}
        </p>
      )}
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">{S.teachers.title}</h1>
        <a href="/members" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
          {S.teachers.invite}
        </a>
      </div>
      <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
        <thead className="bg-gray-50 text-start">
          <tr>
            <th className="px-4 py-2">{S.teachers.colName}</th>
            <th className="px-4 py-2">{S.teachers.colEmail}</th>
            <th className="px-4 py-2">{S.teachers.colCircles}</th>
            {isAdmin && <th className="px-4 py-2"></th>}
          </tr>
        </thead>
        <tbody>
          {teachers.map((t) => (
            <tr key={t.id} className="border-t">
              <td className="px-4 py-2"><a href={`/teachers/${t.id}` as never} className="font-medium text-brand hover:underline">{t.full_name ?? t.email ?? '—'}</a></td>
              <td className="px-4 py-2">{t.email}</td>
              <td className="px-4 py-2">{(circleNamesByTeacher.get(t.user_id) ?? []).join(T.labels.listSep) || '—'}</td>
              {isAdmin && (
                <td className="px-4 py-2 text-end">
                  <a href={`/teachers/${t.id}/edit` as never} className="text-brand hover:underline">
                    {S.common.edit}
                  </a>
                </td>
              )}
            </tr>
          ))}
          {!teachers.length && (
            <tr>
              <td colSpan={isAdmin ? 4 : 3} className="px-4 py-6 text-center text-gray-400">
                {S.teachers.none}
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
