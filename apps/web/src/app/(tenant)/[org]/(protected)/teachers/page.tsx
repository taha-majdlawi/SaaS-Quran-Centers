import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';

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
  const supabase = await createClient();

  const [{ data: members }, { data: circles }] = await Promise.all([
    supabase.rpc('list_org_members', { org_id: org.id }),
    supabase.from('circles').select('name, teacher_id').eq('organization_id', org.id),
  ]);

  const teachers = ((members ?? []) as MemberRow[]).filter((m) => m.role === 'teacher');

  const circleNamesByTeacher = new Map<string, string[]>();
  ((circles ?? []) as CircleRow[]).forEach((c) => {
    if (!c.teacher_id) return;
    const list = circleNamesByTeacher.get(c.teacher_id) ?? [];
    list.push(c.name);
    circleNamesByTeacher.set(c.teacher_id, list);
  });

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">المعلمون</h1>
        <a href="/members" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
          + دعوة معلم
        </a>
      </div>
      <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
        <thead className="bg-gray-50 text-right">
          <tr>
            <th className="px-4 py-2">الاسم</th>
            <th className="px-4 py-2">البريد الإلكتروني</th>
            <th className="px-4 py-2">الحلقات</th>
          </tr>
        </thead>
        <tbody>
          {teachers.map((t) => (
            <tr key={t.id} className="border-t">
              <td className="px-4 py-2">{t.full_name ?? '—'}</td>
              <td className="px-4 py-2">{t.email}</td>
              <td className="px-4 py-2">{(circleNamesByTeacher.get(t.user_id) ?? []).join('، ') || '—'}</td>
            </tr>
          ))}
          {!teachers.length && (
            <tr>
              <td colSpan={3} className="px-4 py-6 text-center text-gray-400">
                لا يوجد معلمون بعد - ادعُ معلمًا من صفحة الأعضاء
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
