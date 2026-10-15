'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { getI18n } from '@/lib/i18n/server';
import { confirmUrl, isExistingAccount, type PendingSignup } from '@/lib/auth/signup';

/** Invitee has no account yet - create one, then accept in the same request. */
export async function signUpAndAcceptInvitation(formData: FormData) {
  const token = formData.get('token') as string;
  const email = formData.get('email') as string;
  const password = formData.get('password') as string;

  const supabase = await createClient();

  // with "Confirm email" on, /confirm accepts the invitation from what waits here
  const pending: PendingSignup = { pending_invite: token };
  const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
    email,
    password,
    options: { data: pending, emailRedirectTo: confirmUrl() },
  });
  if (signUpError) {
    redirect(`/join?token=${token}&error=${encodeURIComponent(signUpError.message)}`);
  }

  if (isExistingAccount(signUpData.user)) {
    const { t } = await getI18n();
    redirect(`/join?token=${token}&error=${encodeURIComponent(t.join.errorEmailHasAccount)}`);
  }

  if (!signUpData.session) {
    // "Confirm email" is on: the link in the email accepts the invitation (/confirm)
    redirect(`/join?token=${token}&sent=${encodeURIComponent(email)}`);
  }

  const { error: acceptError } = await supabase.rpc('accept_invitation', { invite_token: token });
  if (acceptError) {
    redirect(`/join?token=${token}&error=${encodeURIComponent(acceptError.message)}`);
  }
  await supabase.auth.updateUser({ data: { pending_invite: null } satisfies PendingSignup });

  redirect('/dashboard');
}

/** Invitee is already signed in (existing account) - just accept. */
export async function acceptInvitationForCurrentUser(formData: FormData) {
  const token = formData.get('token') as string;

  const supabase = await createClient();
  const { error } = await supabase.rpc('accept_invitation', { invite_token: token });
  if (error) {
    redirect(`/join?token=${token}&error=${encodeURIComponent(error.message)}`);
  }

  redirect('/dashboard');
}
