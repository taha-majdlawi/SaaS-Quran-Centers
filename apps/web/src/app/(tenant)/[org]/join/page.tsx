import { AuthCard } from '@/components/auth-card';
import { authInputClass, authLabelClass, authButtonClass } from '@/components/auth-styles';
import { SubmitButton } from '@/components/submit-button';
import { createClient } from '@/lib/supabase/server';
import { signUpAndAcceptInvitation, acceptInvitationForCurrentUser } from './actions';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

export default async function JoinPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ token?: string; error?: string }>;
}) {
  const { org } = await params;
  const { token, error } = await searchParams;
  const { t } = await getI18n();

  if (!token) {
    return (
      <AuthCard title={t.join.incompleteTitle} subtitle={org}>
        <p className="text-center text-sm text-gray-500">{t.join.incompleteBody}</p>
      </AuthCard>
    );
  }

  const supabase = await createClient();
  const { data } = await supabase.rpc('get_invitation', { invite_token: token });
  const invitation = data?.[0];

  if (!invitation || !invitation.valid) {
    return (
      <AuthCard title={t.join.invalidTitle} subtitle={org}>
        <p className="text-center text-sm text-gray-500">{t.join.invalidBody}</p>
      </AuthCard>
    );
  }

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const roleLabel = t.join.roles[invitation.role] ?? invitation.role;
  const title = fmt(t.join.inviteFrom, { org: invitation.organization_name });

  if (user) {
    return (
      <AuthCard title={title} subtitle={fmt(t.join.asRole, { role: roleLabel })} error={error}>
        <p className="mb-4 text-center text-sm text-gray-500">{fmt(t.join.signedInAs, { email: user.email ?? '' })}</p>
        <form action={acceptInvitationForCurrentUser}>
          <input type="hidden" name="token" value={token} />
          <SubmitButton className={authButtonClass} pendingText={t.join.joining}>
            {t.join.confirm}
          </SubmitButton>
        </form>
      </AuthCard>
    );
  }

  return (
    <AuthCard
      title={title}
      subtitle={fmt(t.join.asRoleCreate, { role: roleLabel })}
      error={error}
    >
      <form action={signUpAndAcceptInvitation} className="flex flex-col gap-3">
        <input type="hidden" name="token" value={token} />
        <label className={authLabelClass}>
          {t.common.email}
          <input
            type="email"
            name="email"
            required
            defaultValue={invitation.email}
            readOnly
            className={`mt-1 ${authInputClass} bg-gray-50`}
          />
        </label>
        <label className={authLabelClass}>
          {t.common.password}
          <input type="password" name="password" required minLength={8} className={`mt-1 ${authInputClass}`} />
        </label>
        <SubmitButton className={`mt-2 ${authButtonClass}`} pendingText={t.join.creating}>
          {t.join.create}
        </SubmitButton>
      </form>
    </AuthCard>
  );
}
