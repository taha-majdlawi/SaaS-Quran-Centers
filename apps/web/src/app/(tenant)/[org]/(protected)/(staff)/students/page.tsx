import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { deleteStudent } from './actions';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

// Replaces wep-eqraa-center/admin/students - list + real add/edit/delete
// (see actions.ts, new/page.tsx, [id]/page.tsx).
export default async function StudentsPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ createdId?: string; createdPassword?: string; q?: string; circle?: string }>;
}) {
  const { org: slug } = await params;
  const { createdId, createdPassword, q: rawQ, circle } = await searchParams;
  // a name or a number; the characters that mean something to a LIKE pattern / the filter syntax are dropped
  const q = (rawQ ?? '').replace(/[%_,()*\\]/g, ' ').trim().slice(0, 60);
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();

  let query = supabase
    .from('students_profile')
    .select('id, student_code, full_name, status, circles(name)')
    .eq('organization_id', org.id)
    .order('full_name');
  if (q) query = query.or(`full_name.ilike.%${q}%,student_code.ilike.%${q}%`);
  if (circle && /^[0-9a-f-]{36}$/i.test(circle)) query = query.eq('circle_id', circle);
  const [{ data: students }, { data: circles }] = await Promise.all([
    query,
    supabase.from('circles').select('id, name').eq('organization_id', org.id).order('name'),
  ]);
  const filtered = !!q || !!circle;

  return (
    <div>
      {createdId && createdPassword && (
        <div className="mb-6 rounded-lg border border-green-200 bg-green-50 p-4 text-sm">
          <p className="mb-2 font-semibold text-green-800">{S.students.created}</p>
          <p dir="ltr" className="font-mono text-green-900">
            {org.slug} / {createdId} / {createdPassword}
          </p>
          <p className="mt-2 text-xs text-green-700">
            {S.students.createdHint}
          </p>
        </div>
      )}
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-bold">
          {S.students.title}
          <span className="ms-2 align-middle text-sm font-normal text-gray-400">{fmt(S.students.countN, { n: students?.length ?? 0 })}</span>
        </h1>
        <div className="flex flex-wrap gap-2 text-sm">
          {org.myPermissions.includes('students') && (
            <>
              <a href="/students/import" className="rounded-lg border bg-white px-3 py-2 text-brand hover:bg-gray-50">
                {S.students.import}
              </a>
              <a href="/students/export" className="rounded-lg border bg-white px-3 py-2 text-brand hover:bg-gray-50">
                {S.students.export}
              </a>
            </>
          )}
          <a href="/students/new" className="rounded-lg bg-brand px-4 py-2 font-semibold text-white">
            {S.students.add}
          </a>
        </div>
      </div>
      <form method="get" className="mb-4 flex flex-wrap gap-2 text-sm">
        <input
          type="search"
          name="q"
          defaultValue={q}
          placeholder={S.students.searchPh}
          className="min-w-[12rem] flex-1 rounded-lg border bg-white px-3 py-2"
        />
        <select name="circle" defaultValue={circle ?? ''} className="rounded-lg border bg-white px-3 py-2">
          <option value="">{S.students.allCircles}</option>
          {(circles ?? []).map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
        <button className="rounded-lg bg-brand px-4 py-2 font-semibold text-white">{S.students.filter}</button>
        {filtered && (
          <a href="/students" className="rounded-lg border bg-white px-3 py-2 text-gray-600 hover:bg-gray-50">
            {S.students.clear}
          </a>
        )}
      </form>
      <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
        <thead className="bg-gray-50 text-right">
          <tr>
            <th className="px-4 py-2">{S.students.colCode}</th>
            <th className="px-4 py-2">{S.students.colName}</th>
            <th className="px-4 py-2">{S.students.colCircle}</th>
            <th className="px-4 py-2">{S.students.colStatus}</th>
            <th className="px-4 py-2"></th>
          </tr>
        </thead>
        <tbody>
          {(students ?? []).map((s) => (
            <tr key={s.id} className="border-t">
              <td className="px-4 py-2">{s.student_code}</td>
              <td className="px-4 py-2"><a href={`/students/${s.id}` as never} className="font-medium text-brand hover:underline">{s.full_name}</a></td>
              <td className="px-4 py-2">{(s.circles as unknown as { name: string } | null)?.name ?? '—'}</td>
              <td className="px-4 py-2">{S.students.status[s.status] ?? s.status}</td>
              <td className="px-4 py-2 text-end">
                <div className="flex items-center justify-end gap-3">
                  <a href={`/students/${s.id}/recitations`} className="text-brand hover:underline">
                    {S.students.recite}
                  </a>
                  <a href={`/students/${s.id}/edit` as never} className="text-brand hover:underline">
                    {S.common.edit}
                  </a>
                  <form action={deleteStudent}>
                    <input type="hidden" name="id" value={s.id} />
                    <ConfirmSubmitButton
                      confirmMessage={fmt(S.students.deleteConfirm, { name: s.full_name })}
                      pendingText={S.common.deleting}
                      className="text-red-600 hover:underline"
                    >
                      {S.common.delete}
                    </ConfirmSubmitButton>
                  </form>
                </div>
              </td>
            </tr>
          ))}
          {!students?.length && (
            <tr>
              <td colSpan={5} className="px-4 py-6 text-center text-gray-400">
                {filtered ? S.students.noMatch : S.students.none}
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
