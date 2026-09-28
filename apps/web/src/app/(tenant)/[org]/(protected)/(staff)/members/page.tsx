import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { createInvitation } from './actions';
import { getI18n } from '@/lib/i18n/server';


interface MemberRow {
  id: string;
  user_id: string;
  role: string;
  status: string;
  full_name: string | null;
  email: string | null;
  created_at: string;
}

interface InvitationRow {
  id: string;
  email: string;
  role: string;
  token: string;
  expires_at: string;
  accepted_at: string | null;
}

export default async function MembersPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ createdEmail?: string; createdPassword?: string; error?: string }>;
}) {
  const { org: slug } = await params;
  const { createdEmail, createdPassword, error: actionError } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();

  const { data: members, error: membersError } = await supabase.rpc('list_org_members', { org_id: org.id });
  const isAdmin = org.myRole === 'admin';
  const { data: flags } = isAdmin ? await supabase.rpc('list_account_flags', { p_org: org.id }) : { data: [] };
  const viewers = new Set(((flags ?? []) as { user_id: string }[]).map((f) => f.user_id));

  const { data: invitations } = isAdmin
    ? await supabase.rpc('list_org_invitations', { org_id: org.id })
    : { data: [] as InvitationRow[] };

  const pendingInvitations = ((invitations ?? []) as InvitationRow[]).filter((i) => !i.accepted_at);

  return (
    <div className="flex flex-col gap-8">
      {createdEmail && createdPassword && (
        <div className="rounded-lg border border-green-200 bg-green-50 p-4 text-sm">
          <p className="mb-2 font-semibold text-green-800">{S.members.teacherCreated}</p>
          <p dir="ltr" className="font-mono text-green-900">
            {createdEmail} / {createdPassword}
          </p>
          <p className="mt-2 text-xs text-green-700">
            {S.members.passwordOnce}
          </p>
        </div>
      )}

      {actionError && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{actionError}</p>}

      <div>
        {membersError && (
          <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600" dir="ltr">
            {membersError.code}: {membersError.message}
          </p>
        )}
        <div className="mb-4 flex items-center justify-between">
          <h1 className="text-2xl font-bold">{S.members.title}</h1>
          {org.myRole === 'admin' && (
            <a href="/members/new-teacher" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
              {S.members.addTeacher}
            </a>
          )}
        </div>
        <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
          <thead className="bg-gray-50 text-start">
            <tr>
              <th className="px-4 py-2">{S.members.colName}</th>
              <th className="px-4 py-2">{S.members.email}</th>
              <th className="px-4 py-2">{S.members.role}</th>
              <th className="px-4 py-2">{S.members.status}</th>
              {isAdmin && <th className="px-4 py-2"></th>}
            </tr>
          </thead>
          <tbody>
            {((members ?? []) as MemberRow[]).map((m) => (
              <tr key={m.id} className="border-t">
                <td className="px-4 py-2">
                  {m.full_name ?? '—'}
                  {viewers.has(m.user_id) && <span className="ms-2 rounded bg-amber-50 px-2 py-0.5 text-xs text-amber-700">{S.members.viewOnly}</span>}
                </td>
                <td className="px-4 py-2">{m.email}</td>
                <td className="px-4 py-2">{T.shell.roles[m.role] ?? m.role}</td>
                <td className="px-4 py-2">{S.teachers.memberStatus[m.status] ?? m.status}</td>
                {isAdmin && (
                  <td className="px-4 py-2 text-end">
                    <a href={`/members/${m.id}`} className="text-brand hover:underline">
                      {S.common.edit}
                    </a>
                  </td>
                )}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {isAdmin && (
        <div>
          <h2 className="mb-4 text-lg font-bold">{S.members.inviteTitle}</h2>
          <form action={createInvitation} className="flex flex-wrap items-end gap-3 rounded-lg border bg-white p-4">
            <input type="hidden" name="orgId" value={org.id} />
            <label className="text-sm">
              {S.members.email}
              <input
                type="email"
                name="email"
                required
                placeholder="teacher@example.com"
                className="mt-1 block rounded border px-3 py-2 text-sm"
              />
            </label>
            <label className="text-sm">
              {S.members.role}
              <select name="role" className="mt-1 block rounded border px-3 py-2 text-sm">
                {['teacher', 'admin', 'guardian', 'student'].map((r) => (
                  <option key={r} value={r}>
                    {T.shell.roles[r]}
                  </option>
                ))}
              </select>
            </label>
            <SubmitButton
              className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
              pendingText={S.common.creating}
            >
              {S.members.createInvite}
            </SubmitButton>
          </form>

          {pendingInvitations.length > 0 && (
            <div className="mt-4">
              <h3 className="mb-2 text-sm font-semibold text-gray-600">{S.members.pending}</h3>
              <ul className="flex flex-col gap-2">
                {pendingInvitations.map((inv) => (
                  <li key={inv.id} className="rounded border bg-white p-3 text-sm">
                    <div className="mb-1 flex items-center justify-between">
                      <span>
                        {inv.email} — {T.shell.roles[inv.role] ?? inv.role}
                      </span>
                    </div>
                    <p className="break-all text-xs text-gray-400" dir="ltr">
                      {`https://${org.slug}.bustan-alquran.com/join?token=${inv.token}`}
                    </p>
                  </li>
                ))}
              </ul>
              <p className="mt-2 text-xs text-gray-400">
                {S.members.copyHint}
              </p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
