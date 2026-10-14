'use server';

import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';
import { getI18n } from '@/lib/i18n/server';
import { PENDING_ORG_COOKIE, productUrl, validSlug } from './signup';

/**
 * "Continue with Google" for teachers and admins (docs/GOOGLE_SIGNIN.md). Supabase signs the
 * person in with Google and comes back to /auth/callback with a one-time code (PKCE: the
 * verifier waits in a cookie of this browser). A Google account whose email is a teacher's or
 * admin's account is the same account (Supabase links them); any other is refused there.
 */

async function toGoogle(redirectTo: string): Promise<never> {
  const supabase = await createClient();
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: { redirectTo, skipBrowserRedirect: true, queryParams: { prompt: 'select_account' } },
  });
  if (error || !data.url) {
    const { t } = await getI18n();
    redirect(`/login?error=${encodeURIComponent(t.login.errorGoogle)}`);
  }
  redirect(data.url as never);
}

/** The center's sign-in page (and an invitation: the callback accepts it). */
export async function signInWithGoogle(formData: FormData): Promise<never> {
  const slug = String(formData.get('orgSlug') ?? '').trim().toLowerCase();
  const invite = String(formData.get('invite') ?? '').trim();
  if (!validSlug(slug)) redirect('/login');
  const query = /^[0-9a-f-]{36}$/i.test(invite) ? `?invite=${invite}` : '';
  return toGoogle(productUrl(`/auth/callback${query}`, slug));
}

/** A new center with a Google account: its name and link wait in a cookie for the callback. */
export async function signUpWithGoogle(formData: FormData): Promise<never> {
  const { t } = await getI18n();
  const orgName = String(formData.get('orgName') ?? '').trim();
  const slug = String(formData.get('slug') ?? '').trim().toLowerCase();
  if (!orgName || !slug) redirect(`/signup?error=${encodeURIComponent(t.signup.googleNeedsCenter)}`);
  if (!validSlug(slug)) redirect(`/signup?error=${encodeURIComponent(t.signup.errorSlug)}`);
  const { data: taken } = await createAdminClient().from('organizations').select('id').eq('slug', slug).maybeSingle();
  if (taken) redirect(`/signup?error=${encodeURIComponent(t.signup.errorSlugTaken)}`);
  (await cookies()).set(PENDING_ORG_COOKIE, JSON.stringify({ orgName: orgName.slice(0, 120), slug }), {
    path: '/',
    httpOnly: true,
    sameSite: 'lax',
    secure: !/^localhost(:|$)/.test(process.env.NEXT_PUBLIC_ROOT_DOMAIN ?? ''),
    maxAge: 60 * 30,
  });
  return toGoogle(productUrl('/auth/callback'));
}
