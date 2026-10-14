import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';
import { productUrl, validSlug } from '@/lib/auth/signup';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

/**
 * Back from Google (lib/auth/google.ts) on {center}.bustan-alquran.com/auth/callback. Only a
 * teacher or admin of this center gets in: Supabase signs the Google account in as the account
 * with the same email (a teacher's, an admin's); anyone else is signed out again - and an
 * account Google just created for a stranger is removed, so none are left lying around.
 * ?invite= accepts that invitation first (the invited person chose Google on /join).
 */
export async function GET(req: Request, { params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const url = new URL(req.url);
  const { t } = await getI18n();
  const back = (error: string) => NextResponse.redirect(productUrl(`/login?error=${encodeURIComponent(error)}`, slug));
  if (!validSlug(slug)) return NextResponse.redirect(productUrl('/login'));

  const code = url.searchParams.get('code');
  if (!code) return back(t.login.errorGoogle);
  const supabase = await createClient();
  const { data, error } = await supabase.auth.exchangeCodeForSession(code);
  if (error || !data.user) return back(t.login.errorGoogle);
  const user = data.user;

  const invite = url.searchParams.get('invite');
  if (invite) await supabase.rpc('accept_invitation', { invite_token: invite });

  const admin = createAdminClient();
  const { data: org } = await admin.from('organizations').select('id').eq('slug', slug).maybeSingle();
  const { data: member } = org
    ? await admin.from('organization_members').select('role').eq('organization_id', org.id).eq('user_id', user.id).eq('status', 'active').maybeSingle()
    : { data: null };

  if (member?.role !== 'admin' && member?.role !== 'teacher') {
    await supabase.auth.signOut();
    // a stranger's account Google just made (no center anywhere, Google its only sign-in): gone again
    const { count } = await admin.from('organization_members').select('id', { count: 'exact', head: true }).eq('user_id', user.id);
    const fresh = Date.now() - new Date(user.created_at).getTime() < 10 * 60 * 1000;
    const googleOnly = (user.identities ?? []).every((i) => i.provider === 'google');
    if (!count && fresh && googleOnly) await admin.auth.admin.deleteUser(user.id);
    return back(fmt(t.login.errorGoogleNotStaff, { email: user.email ?? '' }));
  }
  return NextResponse.redirect(productUrl('/dashboard', slug));
}
