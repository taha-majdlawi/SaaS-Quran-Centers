'use server';

import { createClient } from '@/lib/supabase/server';
import { isEmail } from '@/lib/accounts/login-id';
import { resetEmailsForNationalId } from '@/lib/auth/national-id';
import { productUrl } from '@/lib/auth/signup';
import { getI18n } from '@/lib/i18n/server';

export interface ForgotPasswordState {
  error?: string;
  sent?: boolean;
  /** a number was typed (not an email): the answer covers both an ID with an email and a number-only account */
  byNumber?: boolean;
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

  const supabase = await createClient();
  const redirectTo = productUrl('/reset-password', orgSlug);

  if (!isEmail(identifier)) {
    // A number: a student's number has a made-up address that receives no mail (only an admin
    // can reset it), but it may be a national ID (0095) of an account that has a real email - a
    // teacher who signs in with their ID. The link goes there. One answer for both cases, so it
    // never tells whether an ID belongs to someone here.
    for (const email of (await resetEmailsForNationalId(orgSlug, identifier)).slice(0, 3)) {
      await supabase.auth.resetPasswordForEmail(email, { redirectTo });
    }
    return { sent: true, byNumber: true };
  }

  await supabase.auth.resetPasswordForEmail(identifier.toLowerCase(), { redirectTo });

  // Same message whether or not the address is registered, so this can't be
  // used to check which emails exist in the system.
  return { sent: true };
}
