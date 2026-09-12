'use server';

import { redirect } from 'next/navigation';
import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

function readCircleFields(formData: FormData) {
  const capacity = formData.get('capacity') as string;
  return {
    name: (formData.get('name') as string)?.trim(),
    stage_id: (formData.get('stageId') as string) || null,
    teacher_id: (formData.get('teacherId') as string) || null,
    capacity: capacity ? Number(capacity) : null,
  };
}

export async function createCircle(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const fields = readCircleFields(formData);

  const supabase = await createClient();
  const { error } = await supabase.from('circles').insert({ organization_id: orgId, ...fields });

  if (error) {
    redirect(`/circles/new?error=${encodeURIComponent(error.message)}` as never);
  }

  revalidatePath('/circles');
  redirect('/circles');
}

export async function updateCircle(formData: FormData) {
  const id = formData.get('id') as string;
  const status = formData.get('status') as string;
  const fields = readCircleFields(formData);

  const supabase = await createClient();
  const { error } = await supabase
    .from('circles')
    .update({ ...fields, status })
    .eq('id', id);

  if (error) {
    redirect(`/circles/${id}?error=${encodeURIComponent(error.message)}` as never);
  }

  revalidatePath('/circles');
  redirect('/circles');
}

export async function deleteCircle(formData: FormData) {
  const id = formData.get('id') as string;

  const supabase = await createClient();
  await supabase.from('circles').delete().eq('id', id);

  revalidatePath('/circles');
  redirect('/circles');
}
