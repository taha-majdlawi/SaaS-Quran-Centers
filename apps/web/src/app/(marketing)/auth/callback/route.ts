import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import { createClient } from '@/lib/supabase/server';
import { PENDING_ORG_COOKIE, productUrl } from '@/lib/auth/signup';
import { finishGoogleSignUp, readPendingOrg } from '@/lib/auth/google-finish';
import { getI18n } from '@/lib/i18n/server';

/**
 * Back from Google through Supabase after "Sign up with Google" (the redirect flow): the new
 * center's name and link waited in a cookie; the center is created with the Google account as admin.
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const { t } = await getI18n();
  const jar = await cookies();
  const back = (error: string) => NextResponse.redirect(productUrl(`/signup?error=${encodeURIComponent(error)}`));

  const code = url.searchParams.get('code');
  if (!code) return back(t.login.errorGoogle);
  const supabase = await createClient();
  const { error } = await supabase.auth.exchangeCodeForSession(code);
  if (error) return back(t.login.errorGoogle);

  const pending = readPendingOrg(jar.get(PENDING_ORG_COOKIE)?.value);
  jar.delete(PENDING_ORG_COOKIE);
  const result = await finishGoogleSignUp(supabase, pending);
  return 'to' in result ? NextResponse.redirect(result.to) : back(result.error);
}
