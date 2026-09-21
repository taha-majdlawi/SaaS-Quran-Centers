'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export async function sendTestPush(formData: FormData) {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('send_test_push', {
    p_org: formData.get('orgId') as string,
    p_user: ((formData.get('userId') as string) || null) as string | null,
  });
  if (error) redirect(`/notifications?pushError=${encodeURIComponent(error.message)}` as never);
  redirect(`/notifications?pushSent=${Number(data) || 1}` as never);
}
