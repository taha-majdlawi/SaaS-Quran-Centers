'use server';

import { createClient as createPlainClient } from '@supabase/supabase-js';
import { createClient } from '@/lib/supabase/server';
import { LOGIN_DOMAIN, hasRealEmail } from '@/lib/accounts/login-id';
import { productUrl } from '@/lib/auth/signup';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

export interface AccountState {
  ok?: string;
  error?: string;
}

const code = (e: unknown) => (e as { code?: string } | null)?.code;

/**
 * A new email for the signed-in staff member. Supabase changes it only once the link mailed to
 * the new address is opened (supabase/templates/email_change.html -> /confirm); with "Secure
 * email change" on, the current address gets a link too.
 */
export async function changeEmail(_prev: AccountState, formData: FormData): Promise<AccountState> {
  const { t } = await getI18n();
  const A = t.staff.myAccount;
  const email = String(formData.get('email') ?? '').trim().toLowerCase();
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: A.failed.replace('{error}', 'session') };
  if (!hasRealEmail(user.email)) return { error: A.noEmail };
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.endsWith(`.${LOGIN_DOMAIN}`)) return { error: A.emailInvalid };
  if (email === user.email?.toLowerCase()) return { error: A.emailSame };

  const { error } = await supabase.auth.updateUser({ email }, { emailRedirectTo: productUrl('/confirm') });
  if (error) {
    const c = code(error);
    if (c === 'email_exists' || /already/i.test(error.message)) return { error: A.emailTaken };
    if (c === 'email_address_invalid') return { error: A.emailInvalid };
    if (c === 'over_email_send_rate_limit' || c === 'over_request_rate_limit') return { error: A.tooMany };
    return { error: fmt(A.failed, { error: error.message }) };
  }
  return { ok: fmt(A.emailSent, { email }) };
}

/**
 * A new password, after the current one: checked on a separate client that keeps no session,
 * so the staff member's own sign-in (and its second factor) is left as it is.
 */
export async function changePassword(_prev: AccountState, formData: FormData): Promise<AccountState> {
  const { t } = await getI18n();
  const A = t.staff.myAccount;
  const current = String(formData.get('current') ?? '');
  const next = String(formData.get('password') ?? '');
  if (next.length < 8) return { error: A.short };
  if (next !== String(formData.get('confirm') ?? '')) return { error: A.mismatch };

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user?.email) return { error: fmt(A.failed, { error: 'session' }) };

  const check = createPlainClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { error: wrong } = await check.auth.signInWithPassword({ email: user.email, password: current });
  if (wrong) return { error: code(wrong) === 'over_request_rate_limit' ? A.tooMany : A.wrongCurrent };
  await check.auth.signOut({ scope: 'local' });

  const { error } = await supabase.auth.updateUser({ password: next });
  if (error) {
    const c = code(error);
    if (c === 'same_password') return { error: A.same };
    if (c === 'weak_password') return { error: A.weak };
    if (c === 'insufficient_aal') return { error: A.needCode };
    return { error: fmt(A.failed, { error: error.message }) };
  }
  return { ok: A.passwordChanged };
}
