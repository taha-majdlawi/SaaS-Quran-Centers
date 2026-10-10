'use server';

import { cookies } from 'next/headers';
import { createClient } from '@/lib/supabase/server';
import { redirect } from '@/lib/platform/redirect';
import { MFA_UNAVAILABLE_COOKIE } from '@/lib/platform/mfa';

/**
 * The code from the authenticator app, for the factor being set up or the one
 * already set up. Supabase checks it and upgrades the session to aal2 (the new
 * cookies are written here), which is what the console and the database ask for.
 */
export async function verifyOwnerCode(formData: FormData) {
  const factorId = String(formData.get('factorId') ?? '');
  const code = String(formData.get('code') ?? '').replace(/\s/g, '');
  if (!factorId || !/^\d{6}$/.test(code)) return redirect(`/mfa?error=${encodeURIComponent('اكتب الرمز من ستة أرقام')}`);

  const supabase = await createClient();
  const { error } = await supabase.auth.mfa.challengeAndVerify({ factorId, code });
  if (error) return redirect(`/mfa?error=${encodeURIComponent('الرمز غير صحيح أو انتهت صلاحيته، جرّب الرمز الحالي')}`);

  (await cookies()).delete(MFA_UNAVAILABLE_COOKIE);
  return redirect('/');
}

/**
 * Supabase refused to set up a factor (MFA off for the project): open the console with a
 * warning until it is on. Tried again here, so it never skips a setup that would work.
 */
export async function continueWithoutMfa() {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.mfa.enroll({ factorType: 'totp', friendlyName: `check-${Date.now()}` });
  if (!error) {
    await supabase.auth.mfa.unenroll({ factorId: data.id });
    return redirect('/mfa');
  }
  (await cookies()).set(MFA_UNAVAILABLE_COOKIE, '1', { path: '/', httpOnly: true, sameSite: 'lax', secure: true, maxAge: 60 * 60 * 12 });
  return redirect('/');
}
