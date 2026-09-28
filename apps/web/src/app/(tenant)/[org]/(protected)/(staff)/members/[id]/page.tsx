import { notFound, redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { updateMember, removeMember } from '../actions';
import { setAccountAccess } from '@/lib/certs/actions';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

const ROLE_OPTIONS = ['admin', 'teacher', 'guardian', 'student'];
const STATUS_OPTIONS = ['active', 'suspended'];

interface MemberRow {
  id: string;
  user_id: string;
  role: string;
  status: string;
  full_name: string | null;
  email: string | null;
}

export default async function EditMemberPage({
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

  if (org.myRole !== 'admin') redirect('/members' as never);

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: members } = await supabase.rpc('list_org_members', { org_id: org.id });
  const member = ((members ?? []) as MemberRow[]).find((m) => m.id === id);

  if (!member) notFound();

  const isSelf = member.user_id === user?.id;
  const { data: flags } = await supabase.rpc('list_account_flags', { p_org: org.id });
  const flag = ((flags ?? []) as { user_id: string; note: string | null }[]).find((f) => f.user_id === member.user_id);

  return (
    <div className="max-w-md">
      <h1 className="mb-1 text-2xl font-bold">{S.members.editTitle}</h1>
      <p className="mb-6 text-sm text-gray-500">{member.full_name ?? member.email}</p>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {ok === 'access' && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{S.members.accessSaved}</p>}

      {isSelf ? (
        <p className="rounded-lg border bg-yellow-50 p-4 text-sm text-yellow-800">
          {S.members.self}
        </p>
      ) : (
        <>
          <form action={updateMember} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
            <input type="hidden" name="id" value={member.id} />
            <label className="text-sm font-medium text-gray-700">
              {S.members.role}
              <select name="role" defaultValue={member.role} className="mt-1 w-full rounded border px-3 py-2 text-sm">
                {ROLE_OPTIONS.map((r) => (
                  <option key={r} value={r}>
                    {T.shell.roles[r]}
                  </option>
                ))}
              </select>
            </label>
            <label className="text-sm font-medium text-gray-700">
              {S.members.status}
              <select
                name="status"
                defaultValue={member.status}
                className="mt-1 w-full rounded border px-3 py-2 text-sm"
              >
                {STATUS_OPTIONS.map((s) => (
                  <option key={s} value={s}>
                    {S.teachers.memberStatus[s]}
                  </option>
                ))}
              </select>
            </label>
            <SubmitButton
              className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
              pendingText={S.common.saving}
            >
              {S.members.saveChanges}
            </SubmitButton>
          </form>

          <form action={setAccountAccess} className="mt-3 flex flex-col gap-2 rounded-lg border bg-white p-4 text-sm">
            <input type="hidden" name="orgId" value={org.id} />
            <input type="hidden" name="memberId" value={member.id} />
            <input type="hidden" name="userId" value={member.user_id} />
            <label className="flex items-center gap-2 font-medium text-gray-700">
              <input type="checkbox" name="readOnly" defaultChecked={!!flag} />
              {S.members.readOnly}
            </label>
            <p className="text-xs text-gray-500">{S.members.readOnlyHint}</p>
            <input name="note" defaultValue={flag?.note ?? ''} maxLength={200} placeholder={S.members.notePh} className="rounded border px-3 py-2 text-sm" />
            <SubmitButton className="self-start rounded border px-4 py-2 text-sm hover:bg-gray-50" pendingText={S.common.saving}>
              {S.members.saveAccess}
            </SubmitButton>
          </form>

          <form action={removeMember} className="mt-3">
            <input type="hidden" name="id" value={member.id} />
            <ConfirmSubmitButton
              confirmMessage={fmt(S.members.removeConfirm, { name: member.full_name ?? member.email ?? '' })}
              pendingText={S.common.deleting}
              className="rounded border border-red-200 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
            >
              {S.members.remove}
            </ConfirmSubmitButton>
          </form>
        </>
      )}
    </div>
  );
}
