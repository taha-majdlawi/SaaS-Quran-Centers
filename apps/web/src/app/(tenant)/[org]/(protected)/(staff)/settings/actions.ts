'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export async function updateOrgSettings(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const name = (formData.get('name') as string)?.trim();
  const logoUrl = (formData.get('logoUrl') as string)?.trim();
  const primaryColor = formData.get('primaryColor') as string;
  const secondaryColor = formData.get('secondaryColor') as string;
  const timezone = (formData.get('timezone') as string)?.trim();

  const supabase = await createClient();
  const { error } = await supabase
    .from('organizations')
    .update({
      name,
      logo_url: logoUrl || null,
      primary_color: primaryColor,
      secondary_color: secondaryColor,
      timezone,
    })
    .eq('id', orgId);

  if (error) {
    redirect(`/settings?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/settings?saved=1');
}
