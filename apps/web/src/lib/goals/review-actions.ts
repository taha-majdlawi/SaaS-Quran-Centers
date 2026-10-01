'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { safeBack, withParam } from '@/lib/calendar/actions-shared';

const s = (formData: FormData, key: string) => ((formData.get(key) as string) ?? '').trim();

export async function approveReview(formData: FormData) {
  const back = safeBack(formData.get('back'), '/reviews');
  const supabase = await createClient();
  const { error } = await supabase.rpc('approve_review_plan', { p_org: s(formData, 'orgId'), p_student: s(formData, 'studentId') });
  if (error) redirect(withParam(back, 'error', error.message) as never);
  redirect(back as never);
}

export async function approveAllReviews(formData: FormData) {
  const back = safeBack(formData.get('back'), '/reviews');
  const supabase = await createClient();
  const { error } = await supabase.rpc('approve_review_plans', { p_org: s(formData, 'orgId'), p_circle: s(formData, 'circleId') || null });
  if (error) redirect(withParam(back, 'error', error.message) as never);
  redirect(back as never);
}

export async function skipReview(formData: FormData) {
  const back = safeBack(formData.get('back'), '/reviews');
  const supabase = await createClient();
  const { error } = await supabase.rpc('skip_review_plan', { p_org: s(formData, 'orgId'), p_student: s(formData, 'studentId') });
  if (error) redirect(withParam(back, 'error', error.message) as never);
  redirect(back as never);
}
