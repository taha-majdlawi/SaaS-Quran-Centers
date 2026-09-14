'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export async function sendNotification(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const userId = formData.get('userId') as string;
  const title = (formData.get('title') as string)?.trim();
  const body = (formData.get('body') as string)?.trim();

  const supabase = await createClient();
  const { error } = await supabase.from('notification_log').insert({
    organization_id: orgId,
    user_id: userId,
    channel: 'in_app',
    title,
    body,
  });

  if (error) {
    redirect(`/notifications?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/notifications');
}
