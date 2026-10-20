import { AuthCard } from '@/components/auth-card';
import { authInputClass, authLabelClass, authButtonClass } from '@/components/auth-styles';
import { SubmitButton } from '@/components/submit-button';
import { createClient } from '@/lib/supabase/server';
import { signUpAndAcceptInvitation, signInAndAcceptInvitation, acceptInvitationForCurrentUser, signOutForInvitation } from './actions';
import { signInWithGoogle } from '@/lib/auth/google';
import { GoogleButton, OrLine } from '@/components/google-button';
import { googleEnabled } from '@/lib/auth/google-enabled';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

// an email inside an Arabic sentence keeps its own (left-to-right) order
const bidi = (s: string) => `\u2068${s}\u2069`;

export default async function JoinPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ token?: string; error?: string; sent?: string; mode?: string }>;
}) {
  const { org } = await params;
  const { token, error, sent, mode } = await searchParams;
  const { t } = await getI18n();
  const google = await googleEnabled();

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

  if (sent && !user) {
    // "Confirm email" is on: the link in the email finishes joining
    return (
      <AuthCard title={title} subtitle={fmt(t.join.asRole, { role: roleLabel })}>
        <p className="rounded-lg bg-green-50 px-3 py-3 text-center text-sm text-green-700">{fmt(t.join.checkEmail, { email: sent })}</p>
      </AuthCard>
    );
  }

  // another account is signed in - typically the admin who just made the link, in their own
  // browser. Never join that account: offer to sign out and continue as the invited email.
  const sameEmail = (a?: string | null, b?: string | null) => !!a && !!b && a.trim().toLowerCase() === b.trim().toLowerCase();
  if (user && !sameEmail(user.email, invitation.email)) {
    return (
      <AuthCard title={title} subtitle={fmt(t.join.asRole, { role: roleLabel })} error={error}>
        <p className="mb-4 rounded-lg bg-amber-50 px-3 py-3 text-center text-sm text-amber-800">
          {fmt(t.join.wrongAccount, { email: bidi(user.email ?? ''), invited: bidi(invitation.email) })}
        </p>
        <form action={signOutForInvitation}>
          <input type="hidden" name="token" value={token} />
          <SubmitButton className={authButtonClass}>{t.join.signOutContinue}</SubmitButton>
        </form>
      </AuthCard>
    );
  }

  if (user) {
    return (
      <AuthCard title={title} subtitle={fmt(t.join.asRole, { role: roleLabel })} error={error}>
        <p className="mb-4 text-center text-sm text-gray-500">{fmt(t.join.signedInAs, { email: bidi(user.email ?? '') })}</p>
        <form action={acceptInvitationForCurrentUser}>
          <input type="hidden" name="token" value={token} />
          <SubmitButton className={authButtonClass} pendingText={t.join.joining}>
            {t.join.confirm}
          </SubmitButton>
        </form>
      </AuthCard>
    );
  }

  const emailField = (
    <label className={authLabelClass}>
      {t.common.email}
      <input type="email" value={invitation.email} readOnly dir="ltr" className={`mt-1 ${authInputClass} bg-gray-50`} />
    </label>
  );

  // the invited email already has an account: its own password
  if (mode === 'signin') {
    return (
      <AuthCard title={title} subtitle={fmt(t.join.asRoleSignIn, { role: roleLabel })} error={error}>
        <form action={signInAndAcceptInvitation} className="flex flex-col gap-3">
          <input type="hidden" name="token" value={token} />
          {emailField}
          <label className={authLabelClass}>
            {t.common.password}
            <input type="password" name="password" required autoComplete="current-password" className={`mt-1 ${authInputClass}`} />
          </label>
          <SubmitButton className={`mt-2 ${authButtonClass}`} pendingText={t.join.signingIn}>
            {t.join.signIn}
          </SubmitButton>
        </form>
        <p className="mt-4 text-center text-sm">
          <a href={`/join?token=${encodeURIComponent(token)}` as never} className="text-brand hover:underline">{t.join.noAccount}</a>
        </p>
      </AuthCard>
    );
  }

  return (
    <AuthCard title={title} subtitle={fmt(t.join.asRoleCreate, { role: roleLabel })} error={error}>
      <form action={signUpAndAcceptInvitation} className="flex flex-col gap-3">
        <input type="hidden" name="token" value={token} />
        {emailField}
        <label className={authLabelClass}>
          {t.common.password}
          <input type="password" name="password" required minLength={8} autoComplete="new-password" className={`mt-1 ${authInputClass}`} />
          <span className="mt-1 block text-xs font-normal text-gray-400">{t.join.passwordHint}</span>
        </label>
        <label className={authLabelClass}>
          {t.join.confirmPassword}
          <input type="password" name="confirm" required minLength={8} autoComplete="new-password" className={`mt-1 ${authInputClass}`} />
        </label>
        <SubmitButton className={`mt-2 ${authButtonClass}`} pendingText={t.join.creating}>
          {t.join.create}
        </SubmitButton>
      </form>
      <p className="mt-4 text-center text-sm">
        <a href={`/join?token=${encodeURIComponent(token)}&mode=signin` as never} className="text-brand hover:underline">{t.join.haveAccount}</a>
      </p>
      {google && (invitation.role === 'teacher' || invitation.role === 'admin') && (
        <form action={signInWithGoogle} className="mt-3 flex flex-col gap-2">
          <input type="hidden" name="orgSlug" value={org} />
          <input type="hidden" name="invite" value={token} />
          <OrLine text={t.login.or} />
          <GoogleButton label={t.join.google} pendingText={t.join.creating} />
        </form>
      )}
    </AuthCard>
  );
}
