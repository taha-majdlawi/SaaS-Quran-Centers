import type { SupabaseClient, User } from '@supabase/supabase-js';

/**
 * The owner's second factor (TOTP, Supabase Auth MFA - 0094).
 *  - 'ok':     past the second factor (aal2), or allowed without one (see below)
 *  - 'verify': has a factor, signed in with the password only: enter the code
 *  - 'enroll': no factor yet: the console asks to set one up first
 * The database enforces the same rule on its side (is_platform_owner()).
 */
export type MfaState = 'ok' | 'verify' | 'enroll';

/** Cookie set when Supabase refused to set up a factor (MFA off for the project): the console opens with a warning. */
export const MFA_UNAVAILABLE_COOKIE = 'bustan-mfa-unavailable';

export function mfaState(aal: string | null | undefined, verifiedFactors: number): MfaState {
  if (aal === 'aal2') return 'ok';
  return verifiedFactors > 0 ? 'verify' : 'enroll';
}

/** The session's assurance level, read from its access token (getUser() has just checked that token). */
export function tokenAal(accessToken: string | null | undefined): string | null {
  const payload = accessToken?.split('.')[1];
  if (!payload) return null;
  try {
    const json = JSON.parse(atob(payload.replace(/-/g, '+').replace(/_/g, '/')));
    return typeof json.aal === 'string' ? json.aal : null;
  } catch {
    return null;
  }
}

export function verifiedTotp(user: User) {
  return (user.factors ?? []).filter((f) => f.factor_type === 'totp' && f.status === 'verified');
}

/** The signed-in owner's state; `user` must come from getUser() (fresh factors). */
export async function ownerMfaState(supabase: SupabaseClient, user: User): Promise<MfaState> {
  const {
    data: { session },
  } = await supabase.auth.getSession();
  return mfaState(tokenAal(session?.access_token), verifiedTotp(user).length);
}
