'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { getI18n } from '@/lib/i18n/server';

const RESERVED_SLUGS = new Set(['www', 'admin', 'api', 'app', 'platform']);
const SLUG_PATTERN = /^[a-z0-9]+(-[a-z0-9]+)*$/;

export async function signUpAndCreateOrganization(formData: FormData) {
  const orgName = (formData.get('orgName') as string)?.trim();
  const slug = (formData.get('slug') as string)?.trim().toLowerCase();
  const email = formData.get('email') as string;
  const password = formData.get('password') as string;
  const { t } = await getI18n();

  if (!orgName || !slug || !email || !password) {
    redirect(`/signup?error=${encodeURIComponent(t.signup.errorRequired)}`);
  }
  if (!SLUG_PATTERN.test(slug) || RESERVED_SLUGS.has(slug)) {
    redirect(
      `/signup?error=${encodeURIComponent(t.signup.errorSlug)}`,
    );
  }

  const supabase = await createClient();

  const { data: signUpData, error: signUpError } = await supabase.auth.signUp({ email, password });

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
    // "Confirm email" is on for this project - org creation resumes after
    // the visitor confirms and logs in (not wired yet in this skeleton).
    redirect(
      `/signup?error=${encodeURIComponent(t.signup.errorConfirmEmail)}`,
    );
  }

  const { error: orgError } = await supabase.rpc('create_organization_with_owner', {
    org_name: orgName,
    org_slug: slug,
  });

  if (orgError) {
    const message = orgError.code === '23505' ? t.signup.errorSlugTaken : orgError.message;
    redirect(`/signup?error=${encodeURIComponent(message)}`);
  }

  redirect(`https://${slug}.${process.env.NEXT_PUBLIC_ROOT_DOMAIN}/dashboard`);
}
