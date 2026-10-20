'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';
import { confirmUrl, isExistingAccount, type PendingSignup } from '@/lib/auth/signup';

// Joining a center from an invitation link. The account is always the invited email's (the
// database refuses any other - 0097): a new password for a new account, the account's own
// password for an existing one, or "confirm" when that very account is already signed in.

const back = (token: string, extra = '') => `/join?token=${encodeURIComponent(token)}${extra}` as never;
const err = (token: string, message: string, mode?: 'signin'): never =>
  back(token, `${mode ? `&mode=${mode}` : ''}&error=${encodeURIComponent(message)}`);

/** The invited email, from the invitation itself - never from the form. */
async function invitedEmail(token: string): Promise<string | null> {
  const supabase = await createClient();
  const { data } = await supabase.rpc('get_invitation', { invite_token: token });
  const inv = (data as { email: string | null; valid: boolean }[] | null)?.[0];
  return inv?.valid && inv.email ? inv.email : null;
}

/** Invitee has no account yet - create one with their own password, then accept. */
export async function signUpAndAcceptInvitation(formData: FormData) {
  const token = String(formData.get('token') ?? '');
  const password = String(formData.get('password') ?? '');
  const confirm = String(formData.get('confirm') ?? '');
  const { t } = await getI18n();
  const email = await invitedEmail(token);
  if (!email) redirect(back(token));
  if (password !== confirm) redirect(err(token, t.join.passwordsDiffer));

  const supabase = await createClient();
  // with "Confirm email" on, /confirm accepts the invitation from what waits here
  const pending: PendingSignup = { pending_invite: token };
  const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
    email,
    password,
    options: { data: pending, emailRedirectTo: confirmUrl() },
  });
  if (signUpError) redirect(err(token, signUpError.message));

  // the email already has an account: its own password, on the sign-in form
  if (isExistingAccount(signUpData.user)) redirect(err(token, t.join.errorEmailHasAccount, 'signin'));

  if (!signUpData.session) {
    // "Confirm email" is on: the link in the email accepts the invitation (/confirm)
    redirect(back(token, `&sent=${encodeURIComponent(email)}`));
  }

  const { error: acceptError } = await supabase.rpc('accept_invitation', { invite_token: token });
  if (acceptError) redirect(err(token, acceptError.message));
  await supabase.auth.updateUser({ data: { pending_invite: null } satisfies PendingSignup });
  redirect('/dashboard');
}

/** Invitee already has an account (e.g. a teacher at another center): its password, then accept. */
export async function signInAndAcceptInvitation(formData: FormData) {
  const token = String(formData.get('token') ?? '');
  const password = String(formData.get('password') ?? '');
  const { t } = await getI18n();
  const email = await invitedEmail(token);
  if (!email) redirect(back(token));

  const supabase = await createClient();
  const { error: signInError } = await supabase.auth.signInWithPassword({ email, password });
  if (signInError) redirect(err(token, t.join.errorWrongPassword, 'signin'));

  const { error } = await supabase.rpc('accept_invitation', { invite_token: token });
  if (error) {
    await supabase.auth.signOut();
    redirect(err(token, error.message, 'signin'));
  }
  redirect('/dashboard');
}

/** The invited account is the one signed in - just accept. */
export async function acceptInvitationForCurrentUser(formData: FormData) {
  const token = String(formData.get('token') ?? '');
  const supabase = await createClient();
  const { error } = await supabase.rpc('accept_invitation', { invite_token: token });
  if (error) {
    const { t } = await getI18n();
    const email = await invitedEmail(token);
    redirect(err(token, error.code === '42501' && email ? fmt(t.join.errorOtherEmail, { invited: `\u2068${email}\u2069` }) : error.message));
  }
  redirect('/dashboard');
}

/** Another account is signed in (often the admin who made the link): sign out, back to the invitation. */
export async function signOutForInvitation(formData: FormData) {
  const token = String(formData.get('token') ?? '');
  const supabase = await createClient();
  await supabase.auth.signOut({ scope: 'local' });
  redirect(back(token));
}
