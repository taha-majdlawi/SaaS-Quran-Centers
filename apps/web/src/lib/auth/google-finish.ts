import type { SupabaseClient, User } from '@supabase/supabase-js';
import { createAdminClient } from '@/lib/supabase/admin';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';
import { productUrl, validSlug } from './signup';

export type GoogleResult = { to: string } | { error: string };

/**
 * After Google, on a center: only a teacher or admin of it gets in. Supabase signs a Google
 * account in as the account with the same email (a teacher's, an admin's); anyone else is
 * signed out again - and an account Google just made for a stranger is removed, so none are
 * left lying around. `invite` accepts that invitation first (the invited person chose Google).
 */
export async function finishGoogleSignIn(supabase: SupabaseClient, user: User, slug: string, invite?: string | null): Promise<GoogleResult> {
  const { t } = await getI18n();
  if (!validSlug(slug)) return { error: t.login.errorGoogle };
  if (invite) await supabase.rpc('accept_invitation', { invite_token: invite });

  const admin = createAdminClient();
  const { data: org } = await admin.from('organizations').select('id').eq('slug', slug).maybeSingle();
  const { data: member } = org
    ? await admin.from('organization_members').select('role').eq('organization_id', org.id).eq('user_id', user.id).eq('status', 'active').maybeSingle()
    : { data: null };

  if (member?.role === 'admin' || member?.role === 'teacher') return { to: productUrl('/dashboard', slug) };

  await supabase.auth.signOut();
  await removeIfStranger(user);
  return { error: fmt(t.login.errorGoogleNotStaff, { email: user.email ?? '' }) };
}

/** A stranger's account Google just made (no center anywhere, Google its only sign-in): gone again. */
export async function removeIfStranger(user: User): Promise<void> {
  const admin = createAdminClient();
  const { count } = await admin.from('organization_members').select('id', { count: 'exact', head: true }).eq('user_id', user.id);
  const fresh = Date.now() - new Date(user.created_at).getTime() < 10 * 60 * 1000;
  const googleOnly = (user.identities ?? []).every((i) => i.provider === 'google');
  if (!count && fresh && googleOnly) await admin.auth.admin.deleteUser(user.id);
}

/** After Google, for a new center: its name and link waited in a cookie (lib/auth/google.ts). */
export async function finishGoogleSignUp(supabase: SupabaseClient, pending: { orgName?: string; slug?: string }): Promise<GoogleResult> {
  const { t } = await getI18n();
  const slug = (pending.slug ?? '').toLowerCase();
  if (!pending.orgName || !validSlug(slug)) return { error: t.signup.googleNeedsCenter };
  const { error } = await supabase.rpc('create_organization_with_owner', { org_name: pending.orgName, org_slug: slug });
  if (error) return { error: error.code === '23505' ? t.signup.errorSlugTaken : error.message };
  return { to: productUrl('/dashboard', slug) };
}

/** The pending center from its cookie (JSON), or nothing. */
export function readPendingOrg(value: string | undefined): { orgName?: string; slug?: string } {
  try {
    return JSON.parse(value ?? '{}');
  } catch {
    return {};
  }
}
