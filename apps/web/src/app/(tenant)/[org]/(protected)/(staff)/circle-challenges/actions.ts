'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { runRpc, withParam } from '@/lib/calendar/actions-shared';

const s = (formData: FormData, key: string) => ((formData.get(key) as string) ?? '').trim();

export async function saveChallenge(formData: FormData) {
  const id = s(formData, 'id') || null;
  const back = id ? `/circle-challenges/${id}` : '/circle-challenges/new';
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('admin_save_challenge', {
    p_org: s(formData, 'orgId'),
    p_id: id,
    p_title: s(formData, 'title'),
    p_description: s(formData, 'description') || null,
    p_metric: s(formData, 'metric'),
    p_starts: s(formData, 'startsOn') || null,
    p_ends: s(formData, 'endsOn') || null,
  });
  if (error) redirect(withParam(back, 'error', error.message) as never);
  redirect(`/circle-challenges/${data as string}?ok=saved` as never);
}

export async function deleteChallenge(formData: FormData) {
  return runRpc('admin_delete_challenge', { p_org: s(formData, 'orgId'), p_id: s(formData, 'id') }, '/circle-challenges', 'deleted');
}
