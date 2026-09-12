'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

function readStageFields(formData: FormData) {
  const sortOrder = formData.get('sortOrder') as string;
  return {
    name: (formData.get('name') as string)?.trim(),
    code: (formData.get('code') as string)?.trim() || null,
    sort_order: sortOrder ? Number(sortOrder) : 0,
  };
}

export async function createStage(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const fields = readStageFields(formData);

  const supabase = await createClient();
  const { error } = await supabase.from('stages').insert({ organization_id: orgId, ...fields });

  if (error) {
    const message = error.code === '23505' ? 'الاسم أو الكود مستخدم من قبل بهذا المركز' : error.message;
    redirect(`/stages/new?error=${encodeURIComponent(message)}` as never);
  }

  redirect('/stages');
}

export async function updateStage(formData: FormData) {
  const id = formData.get('id') as string;
  const fields = readStageFields(formData);

  const supabase = await createClient();
  const { error } = await supabase.from('stages').update(fields).eq('id', id);

  if (error) {
    const message = error.code === '23505' ? 'الاسم أو الكود مستخدم من قبل بهذا المركز' : error.message;
    redirect(`/stages/${id}?error=${encodeURIComponent(message)}` as never);
  }

  redirect('/stages');
}

export async function deleteStage(formData: FormData) {
  const id = formData.get('id') as string;

  const supabase = await createClient();
  await supabase.from('stages').delete().eq('id', id);

  redirect('/stages');
}
