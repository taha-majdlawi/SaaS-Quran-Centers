import { notFound, redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { MODULE_DEFS } from '@/lib/permissions/modules';
import { updateTeacherAccount } from '../../actions';
import { setTeacherAttendance } from '@/lib/insights/actions';
import { getI18n } from '@/lib/i18n/server';

const ROLE_OPTIONS = ['teacher', 'admin', 'guardian', 'student'];
const STATUS_OPTIONS = ['active', 'suspended'];

interface MemberRow {
  id: string;
  user_id: string;
  role: string;
  status: string;
  full_name: string | null;
  email: string | null;
  permissions: string[] | null;
}

// Full account edit (name/email/password/role/status) - members/[id] only
// covers role/status; this one also needs the Admin API (see actions.ts)
// since changing someone else's email/password can't go through RLS.
export default async function EditTeacherPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ error?: string; ok?: string }>;
}) {
  const { org: slug, id } = await params;
  const { error, ok } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;

  if (org.myRole !== 'admin') redirect('/teachers' as never);

  const supabase = await createClient();
  const { data: members } = await supabase.rpc('list_org_members', { org_id: org.id });
  const member = ((members ?? []) as MemberRow[]).find((m) => m.id === id);

  if (!member) notFound();

  const today = new Date().toISOString().slice(0, 10);
  const from = new Date(Date.now() - 30 * 86400000).toISOString().slice(0, 10);
  const [{ data: attData }, { data: circleRows }] = await Promise.all([
    supabase.rpc('admin_teacher_attendance', { p_org: org.id, p_teacher: member.user_id, p_from: from, p_to: today }),
    supabase.from('circles').select('id, name').eq('organization_id', org.id).eq('teacher_id', member.user_id),
  ]);
  const att = (attData ?? []) as { id: string; circle_name: string; status: string; date: string; checked_in_at: string | null; note: string | null; set_by_admin: boolean }[];
  const teacherCircles = (circleRows ?? []) as { id: string; name: string }[];
  const STATUS: Record<string, string> = S.teachers.attStatus;

  return (
    <div className="max-w-md">
      <a href={`/teachers/${member.id}` as never} className="text-sm text-brand hover:underline">
        {S.profile.backProfile}
      </a>
      <h1 className="mb-6 mt-2 text-2xl font-bold">{S.teachers.editTitle}</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {ok && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{ok}</p>}

      <form action={updateTeacherAccount} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="memberId" value={member.id} />
        <input type="hidden" name="userId" value={member.user_id} />
        <input type="hidden" name="orgId" value={org.id} />

        <label className="text-sm font-medium text-gray-700">
          {S.teachers.fullName}
          <input
            name="fullName"
            required
            defaultValue={member.full_name ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.teachers.colEmail}
          <input
            type="email"
            name="email"
            required
            defaultValue={member.email ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
            dir="ltr"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.teachers.newPassword}
          <input
            name="password"
            minLength={8}
            placeholder="••••••"
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
            dir="ltr"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.teachers.role}
          <select name="role" defaultValue={member.role} className="mt-1 w-full rounded border px-3 py-2 text-sm">
            {ROLE_OPTIONS.map((r) => (
              <option key={r} value={r}>
                {T.shell.roles[r]}
              </option>
            ))}
          </select>
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.teachers.status}
          <select name="status" defaultValue={member.status} className="mt-1 w-full rounded border px-3 py-2 text-sm">
            {STATUS_OPTIONS.map((s) => (
              <option key={s} value={s}>
                {S.teachers.memberStatus[s]}
              </option>
            ))}
          </select>
        </label>

        <fieldset className="rounded border p-3">
          <legend className="px-1 text-sm font-medium text-gray-700">
            {S.teachers.modulesTitle}
          </legend>
          <p className="mb-2 text-xs text-gray-400">
            {S.teachers.modulesHint}
          </p>
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
            {MODULE_DEFS.map((m) => (
              <label key={m.key} className="flex items-center gap-2 text-sm text-gray-700">
                <input
                  type="checkbox"
                  name={`perm_${m.key}`}
                  defaultChecked={(member.permissions ?? []).includes(m.key)}
                />
                {S.teachers.modules[m.key] ?? m.label}
              </label>
            ))}
          </div>
        </fieldset>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText={S.common.saving}
        >
          {S.teachers.saveChanges}
        </SubmitButton>
      </form>
      <section className="mt-8 rounded-lg border bg-white p-6">
        <h2 className="mb-1 font-semibold">{S.teachers.attTitle}</h2>
        <p className="mb-3 text-xs text-gray-500">{S.teachers.attHint}</p>
        {teacherCircles.length > 0 && (
          <form action={setTeacherAttendance} className="mb-4 grid grid-cols-2 gap-2 text-sm">
            <input type="hidden" name="orgId" value={org.id} />
            <input type="hidden" name="teacherId" value={member.user_id} />
            <input type="hidden" name="back" value={`/teachers/${member.id}/edit`} />
            <select name="circleId" className="rounded border px-2 py-1.5">
              {teacherCircles.map((c) => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>
            <input type="date" name="date" defaultValue={today} required className="rounded border px-2 py-1.5" />
            <select name="status" className="rounded border px-2 py-1.5">
              {Object.entries(STATUS).map(([k, v]) => (
                <option key={k} value={k}>{v}</option>
              ))}
            </select>
            <input name="note" placeholder={S.teachers.notePh} className="rounded border px-2 py-1.5" />
            <SubmitButton className="col-span-2 rounded bg-brand px-4 py-1.5 text-white" pendingText="...">{S.teachers.saveAtt}</SubmitButton>
          </form>
        )}
        <ul className="divide-y text-sm">
          {att.map((a) => (
            <li key={a.id} className="flex justify-between py-1.5">
              <span>{new Date(a.date).toLocaleDateString(T.labels.dateLocale)} · {a.circle_name}</span>
              <span className="text-xs text-gray-500">
                {STATUS[a.status] ?? a.status}
                {a.checked_in_at ? ` · ${new Date(a.checked_in_at).toLocaleTimeString(T.labels.dateLocale, { hour: '2-digit', minute: '2-digit' })}` : ''}
                {a.set_by_admin ? S.teachers.byAdmin : ''}
                {a.note ? ` · ${a.note}` : ''}
              </span>
            </li>
          ))}
          {!att.length && <li className="py-2 text-gray-400">{S.teachers.noRecords}</li>}
        </ul>
      </section>
    </div>
  );
}
