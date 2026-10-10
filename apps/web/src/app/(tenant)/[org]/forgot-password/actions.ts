'use server';

import { createClient } from '@/lib/supabase/server';
import { toLoginEmail, LOGIN_DOMAIN } from '@/lib/accounts/login-id';
import { getI18n } from '@/lib/i18n/server';

export interface ForgotPasswordState {
  error?: string;
  sent?: boolean;
}

// Returns state instead of redirect()-ing back to this same route: a
// same-route redirect from a Server Action loses the tenant's [org] segment
// in Next's client router (it soft-navigates against the bare path with no
// subdomain rewrite to resolve it), landing on a client-side 404. See the
// form's usage of useActionState - no navigation happens, so this cannot hit
// that bug.
export async function requestPasswordReset(
  _prev: ForgotPasswordState,
  formData: FormData,
): Promise<ForgotPasswordState> {
  const orgSlug = ((formData.get('orgSlug') as string) ?? '').trim().toLowerCase();
  const identifier = ((formData.get('identifier') as string) ?? '').trim();
  const { t } = await getI18n();

  if (!identifier) {
    return { error: t.forgot.errorEmpty };
  }
  // the center's address goes into the link mailed out: a made-up value ("evil.com#") would send
  // the reset link - and its token - elsewhere. Only a center slug is accepted.
  if (!/^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$/.test(orgSlug)) {
    return { error: t.forgot.errorEmpty };
  }

  const email = toLoginEmail(orgSlug, identifier);

  // Numbers-only accounts sign in with a virtual address that receives no
  // real mail - there is nothing to send a reset link to. Their only path
  // back in is a center admin resetting the password from member management.
  if (email.endsWith(`.${LOGIN_DOMAIN}`)) {
    return { error: t.forgot.errorNoEmail };
  }

  const supabase = await createClient();
  await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `https://${orgSlug}.bustan-alquran.com/reset-password`,
  });

  // Same message whether or not the address is registered, so this can't be
  // used to check which emails exist in the system.
  return { sent: true };
}
