'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { deleteErrorMessage } from '@/lib/db-errors';

export async function createActivity(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const title = (formData.get('title') as string)?.trim();
  const description = (formData.get('description') as string)?.trim() || null;
  const scheduledAt = (formData.get('scheduledAt') as string) || null;

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { error } = await supabase.from('activities').insert({
    organization_id: orgId,
    title,
    description,
    scheduled_at: scheduledAt,
    created_by: user?.id,
  });

  if (error) {
    redirect(`/activities/new?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/activities');
}

export async function updateActivity(formData: FormData) {
  const id = formData.get('id') as string;
  const title = (formData.get('title') as string)?.trim();
  const description = (formData.get('description') as string)?.trim() || null;
  const scheduledAt = (formData.get('scheduledAt') as string) || null;

  const supabase = await createClient();
  const { error } = await supabase
    .from('activities')
    .update({ title, description, scheduled_at: scheduledAt })
    .eq('id', id);

  if (error) {
    redirect(`/activities/${id}?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/activities');
}

export async function deleteActivity(formData: FormData) {
  const id = formData.get('id') as string;

  const supabase = await createClient();
  const { data: removed, error } = await supabase.from('activities').delete().eq('id', id).select('id');
  if (error || !removed?.length) redirect(`/activities/${id}?error=${encodeURIComponent(deleteErrorMessage(error))}` as never);

  redirect('/activities');
}
