'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { getI18n } from '@/lib/i18n/server';

// The root domain has no single "login" - each center lives on its own
// subdomain. This just looks the slug up (readable by anyone, see
// organizations_select_public in 0008_public_org_branding.sql) and forwards
// the visitor to that specific center's real login page.
export async function findOrgLogin(formData: FormData) {
  const slug = (formData.get('slug') as string)?.trim().toLowerCase();
  const { t } = await getI18n();

  if (!slug) {
    redirect(`/login?error=${encodeURIComponent(t.lookup.errorEmpty)}`);
  }

  const supabase = await createClient();
  const { data: org } = await supabase.from('organizations').select('slug').eq('slug', slug).maybeSingle();

  if (!org) {
    redirect(`/login?error=${encodeURIComponent(t.lookup.errorNotFound)}`);
  }

  redirect(`https://${slug}.${process.env.NEXT_PUBLIC_ROOT_DOMAIN}/login`);
}
