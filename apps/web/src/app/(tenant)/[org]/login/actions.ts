'use server';

import { redirect } from '@/lib/platform/redirect';
import { destinationFor, safeNext } from '@/lib/auth/next';
import { createClient } from '@/lib/supabase/server';
import { isEmail, toLoginEmail } from '@/lib/accounts/login-id';
import { signInWithNationalId } from '@/lib/auth/national-id';
import { getI18n } from '@/lib/i18n/server';

/** A failed attempt keeps the page to come back to. */
function withNext(path: string, formData: FormData): string {
  const next = safeNext(formData.get('next'));
  return next ? `${path}&next=${encodeURIComponent(next)}` : path;
}

export async function signInToTenant(formData: FormData) {
  const orgSlug = formData.get('orgSlug') as string;
  const identifier = (formData.get('identifier') as string) ?? '';
  const password = formData.get('password') as string;
  const { t } = await getI18n();

  const supabase = await createClient();

  const { data: org } = await supabase.from('organizations').select('id').eq('slug', orgSlug).maybeSingle();

  if (!org) {
    return redirect(`/login?error=${encodeURIComponent(t.login.errorNoCenter)}`);
  }

  let { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
    email: toLoginEmail(orgSlug, identifier),
    password,
  });
  // not the number at the center / the email: maybe the national ID (0095), with the same password
  if ((signInError || !signInData.user) && !isEmail(identifier)) {
    const byId = await signInWithNationalId(supabase, orgSlug, identifier, password);
    if (byId) ({ data: signInData, error: signInError } = { data: byId, error: null });
  }

  if (signInError || !signInData.user) {
    return redirect(withNext(`/login?error=${encodeURIComponent(t.login.errorCredentials)}`, formData));
  }

  const { data: membership } = await supabase
    .from('organization_members')
    .select('role')
    .eq('organization_id', org.id)
    .eq('user_id', signInData.user.id)
    .eq('status', 'active')
    .maybeSingle();

  if (!membership) {
    await supabase.auth.signOut();
    return redirect(withNext(`/login?error=${encodeURIComponent(t.login.errorNotMember)}`, formData));
  }

  // the page they were on when the session ran out, else their own first page (students: /my)
  return redirect(destinationFor(membership.role, safeNext(formData.get('next'))));
}
