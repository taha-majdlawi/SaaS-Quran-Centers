import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { productUrl } from '@/lib/auth/signup';
import { finishGoogleSignIn } from '@/lib/auth/google-finish';
import { getI18n } from '@/lib/i18n/server';

/**
 * Back from Google through Supabase (the redirect flow, used while no Google client id is set
 * for the /google page) on {center}.bustan-alquran.com/auth/callback: who may come in is
 * decided by finishGoogleSignIn. ?invite= accepts that invitation first.
 */
export async function GET(req: Request, { params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const url = new URL(req.url);
  const { t } = await getI18n();
  const back = (error: string) => NextResponse.redirect(productUrl(`/login?error=${encodeURIComponent(error)}`, slug));

  const code = url.searchParams.get('code');
  if (!code) return back(t.login.errorGoogle);
  const supabase = await createClient();
  const { data, error } = await supabase.auth.exchangeCodeForSession(code);
  if (error || !data.user) return back(t.login.errorGoogle);

  const result = await finishGoogleSignIn(supabase, data.user, slug, url.searchParams.get('invite'));
  return 'to' in result ? NextResponse.redirect(result.to) : back(result.error);
}
