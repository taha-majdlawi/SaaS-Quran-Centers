'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';
import { getI18n } from '@/lib/i18n/server';
import { confirmUrl, productUrl, validSlug, type PendingSignup } from '@/lib/auth/signup';

export async function signUpAndCreateOrganization(formData: FormData) {
  const orgName = (formData.get('orgName') as string)?.trim();
  const slug = (formData.get('slug') as string)?.trim().toLowerCase();
  const email = formData.get('email') as string;
  const password = formData.get('password') as string;
  const { t } = await getI18n();

  if (!orgName || !slug || !email || !password) {
    redirect(`/signup?error=${encodeURIComponent(t.signup.errorRequired)}`);
  }
  if (!validSlug(slug)) {
    redirect(
      `/signup?error=${encodeURIComponent(t.signup.errorSlug)}`,
    );
  }

  const supabase = await createClient();

  // taken already: say so now, not after the email round-trip (a visitor cannot read
  // organizations, so the server looks - only whether this one link exists)
  const { data: taken } = await createAdminClient().from('organizations').select('id').eq('slug', slug).maybeSingle();
  if (taken) redirect(`/signup?error=${encodeURIComponent(t.signup.errorSlugTaken)}`);

  // with "Confirm email" on, the center is created by /confirm from what waits here
  const pending: PendingSignup = { pending_org_name: orgName, pending_org_slug: slug };
  const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
    email,
    password,
    options: { data: pending, emailRedirectTo: confirmUrl() },
  });

  if (signUpError) {
    // Supabase answers in English; the two common cases get the viewer's language
    const message = /already registered/i.test(signUpError.message)
      ? t.signup.errorEmailTaken
      : /password/i.test(signUpError.message)
        ? t.signup.errorWeakPassword
        : signUpError.message;
    redirect(`/signup?error=${encodeURIComponent(message)}`);
  }

  if (!signUpData.session) {
    // "Confirm email" is on: the link in the email finishes the center (/confirm)
    redirect(`/signup?sent=${encodeURIComponent(email)}`);
  }

  const { error: orgError } = await supabase.rpc('create_organization_with_owner', {
    org_name: orgName,
    org_slug: slug,
  });

  if (orgError) {
    const message = orgError.code === '23505' ? t.signup.errorSlugTaken : orgError.message;
    redirect(`/signup?error=${encodeURIComponent(message)}`);
  }

  await supabase.auth.updateUser({ data: { pending_org_name: null, pending_org_slug: null } satisfies PendingSignup });
  redirect(productUrl('/dashboard', slug) as never);
}
