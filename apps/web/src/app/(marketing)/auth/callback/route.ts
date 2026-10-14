import { NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import { createClient } from '@/lib/supabase/server';
import { PENDING_ORG_COOKIE, productUrl, validSlug } from '@/lib/auth/signup';
import { getI18n } from '@/lib/i18n/server';

/**
 * Back from Google after "Sign up with Google" (lib/auth/google.ts): the new center's name and
 * link waited in a cookie; the center is created with the Google account as its admin.
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

  let pending: { orgName?: string; slug?: string } = {};
  try {
    pending = JSON.parse(jar.get(PENDING_ORG_COOKIE)?.value ?? '{}');
  } catch {
    // no center waiting
  }
  jar.delete(PENDING_ORG_COOKIE);
  const slug = (pending.slug ?? '').toLowerCase();
  if (!pending.orgName || !validSlug(slug)) return back(t.signup.googleNeedsCenter);

  const { error: orgError } = await supabase.rpc('create_organization_with_owner', { org_name: pending.orgName, org_slug: slug });
  if (orgError) return back(orgError.code === '23505' ? t.signup.errorSlugTaken : orgError.message);
  return NextResponse.redirect(productUrl('/dashboard', slug));
}
