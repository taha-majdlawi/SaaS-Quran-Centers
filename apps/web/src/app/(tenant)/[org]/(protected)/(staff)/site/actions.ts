'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export async function updateSiteSettings(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const publicSiteEnabled = formData.get('publicSiteEnabled') === 'on';
  const heroTitle = (formData.get('heroTitle') as string)?.trim() || null;
  const heroBody = (formData.get('heroBody') as string)?.trim() || null;
  const contactEmail = (formData.get('contactEmail') as string)?.trim() || null;

  const supabase = await createClient();
  const { error } = await supabase.from('site_settings').upsert({
    organization_id: orgId,
    public_site_enabled: publicSiteEnabled,
    hero_title: heroTitle,
    hero_body: heroBody,
    contact_email: contactEmail,
    updated_at: new Date().toISOString(),
  });

  if (error) {
    redirect(`/site?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/site?saved=1');
}
