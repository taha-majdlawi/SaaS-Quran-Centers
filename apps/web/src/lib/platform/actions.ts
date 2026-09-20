'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

/** Platform owner: change a center's status and/or plan (the only door: organizations columns are closed to center admins). */
export async function setOrgStatus(formData: FormData) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('platform_set_org', {
    p_org: formData.get('orgId') as string,
    p_status: formData.get('status') as string,
    p_plan: ((formData.get('planId') as string) || null) as string | null,
  });
  if (error) redirect(`/organizations?error=${encodeURIComponent(error.message)}` as never);
  redirect('/organizations?saved=1' as never);
}
