'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export async function createAnnouncement(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const title = (formData.get('title') as string)?.trim();
  const body = (formData.get('body') as string)?.trim();
  const audience = formData.get('audience') as string;

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { error } = await supabase.from('announcements').insert({
    organization_id: orgId,
    title,
    body,
    audience,
    created_by: user?.id,
    published_at: new Date().toISOString(),
  });

  if (error) {
    redirect(`/announcements/new?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/announcements');
}

export async function updateAnnouncement(formData: FormData) {
  const id = formData.get('id') as string;
  const title = (formData.get('title') as string)?.trim();
  const body = (formData.get('body') as string)?.trim();
  const audience = formData.get('audience') as string;

  const supabase = await createClient();
  const { error } = await supabase.from('announcements').update({ title, body, audience }).eq('id', id);

  if (error) {
    redirect(`/announcements/${id}?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/announcements');
}

export async function deleteAnnouncement(formData: FormData) {
  const id = formData.get('id') as string;

  const supabase = await createClient();
  await supabase.from('announcements').delete().eq('id', id);

  redirect('/announcements');
}
