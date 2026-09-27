'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { getI18n } from '@/lib/i18n/server';

/** Invitee has no account yet - create one, then accept in the same request. */
export async function signUpAndAcceptInvitation(formData: FormData) {
  const token = formData.get('token') as string;
  const email = formData.get('email') as string;
  const password = formData.get('password') as string;

  const supabase = await createClient();

  const { data: signUpData, error: signUpError } = await supabase.auth.signUp({ email, password });
  if (signUpError) {
    redirect(`/join?token=${token}&error=${encodeURIComponent(signUpError.message)}`);
  }

  if (!signUpData.session) {
    // "Confirm email" is on for this project - no session yet, so
    // accept_invitation (which requires auth.uid()) would fail silently.
    redirect(
      `/join?token=${token}&error=${encodeURIComponent((await getI18n()).t.join.errorConfirmEmail)}`,
    );
  }

  const { error: acceptError } = await supabase.rpc('accept_invitation', { invite_token: token });
  if (acceptError) {
    redirect(`/join?token=${token}&error=${encodeURIComponent(acceptError.message)}`);
  }

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
