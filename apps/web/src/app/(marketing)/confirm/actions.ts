'use server';

import { createClient } from '@/lib/supabase/server';
import { productUrl, validSlug, type PendingSignup } from '@/lib/auth/signup';

export interface FinishResult {
  /** where to go next */
  to?: string;
  /** the chosen center link was taken meanwhile: pick another */
  slugTaken?: { slug: string; orgName: string };
  error?: string;
}

/**
 * The address is confirmed (the browser has just verified the link): finish what the
 * sign-up form started - create the center, or accept the invitation - from what waits
 * in the account's own user_metadata (lib/auth/signup.ts). Acts only for the signed-in
 * account, on its own pending choice; then clears it, so a second call does nothing.
 */
export async function finishSignup(override?: { orgName: string; slug: string }): Promise<FinishResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: 'session' };
  const pending = (user.user_metadata ?? {}) as PendingSignup;
  const clear = (fields: PendingSignup) => supabase.auth.updateUser({ data: fields });

  if (pending.pending_invite) {
    const token = pending.pending_invite;
    const { data: inv } = await supabase.rpc('get_invitation', { invite_token: token });
    const slug = (inv as { organization_slug: string | null }[] | null)?.[0]?.organization_slug;
    const { error } = await supabase.rpc('accept_invitation', { invite_token: token });
    await clear({ pending_invite: null });
    if (error || !slug) return { error: 'invite' };
    return { to: productUrl('/dashboard', slug) };
  }

  if (pending.pending_org_slug) {
    const orgName = (override?.orgName ?? pending.pending_org_name ?? '').trim();
    const slug = (override?.slug ?? pending.pending_org_slug).trim().toLowerCase();
    if (!orgName || !validSlug(slug)) return { slugTaken: { slug, orgName } };
    const { error } = await supabase.rpc('create_organization_with_owner', { org_name: orgName, org_slug: slug });
    if (error?.code === '23505') return { slugTaken: { slug, orgName } };
    if (error) return { error: error.message };
    await clear({ pending_org_name: null, pending_org_slug: null });
    return { to: productUrl('/dashboard', slug) };
  }

  // nothing waiting (an email change, or a link opened twice): just sign in
  return { to: '/login' };
}
