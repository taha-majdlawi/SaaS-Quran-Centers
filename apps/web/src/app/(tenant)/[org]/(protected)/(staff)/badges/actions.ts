'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export async function createBadge(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const name = (formData.get('name') as string)?.trim();
  const description = (formData.get('description') as string)?.trim() || null;

  const supabase = await createClient();
  const { error } = await supabase.from('badges').insert({ organization_id: orgId, name, description });

  if (error) {
    redirect(`/badges/new?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/badges');
}

export async function updateBadge(formData: FormData) {
  const id = formData.get('id') as string;
  const name = (formData.get('name') as string)?.trim();
  const description = (formData.get('description') as string)?.trim() || null;

  const supabase = await createClient();
  const { error } = await supabase.from('badges').update({ name, description }).eq('id', id);

  if (error) {
    redirect(`/badges/${id}?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/badges');
}

export async function deleteBadge(formData: FormData) {
  const id = formData.get('id') as string;

  const supabase = await createClient();
  await supabase.from('badges').delete().eq('id', id);

  redirect('/badges');
}

export async function awardBadge(formData: FormData) {
  const badgeId = formData.get('badgeId') as string;
  const studentId = formData.get('studentId') as string;

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { error } = await supabase
    .from('student_badges')
    .insert({ badge_id: badgeId, student_id: studentId, awarded_by: user?.id });

  if (error) {
    const message = error.code === '23505' ? 'الطالب حاصل على هذي الشارة من قبل' : error.message;
    redirect(`/badges?error=${encodeURIComponent(message)}` as never);
  }

  redirect('/badges?awarded=1');
}
