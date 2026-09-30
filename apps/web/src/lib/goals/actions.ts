'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { safeBack, withParam } from '@/lib/calendar/actions-shared';
import { staffStrings } from '@/lib/i18n/server';

const s = (formData: FormData, key: string) => ((formData.get(key) as string) ?? '').trim();

export async function saveStudentGoal(formData: FormData) {
  const back = safeBack(formData.get('back'), '/students');
  const supabase = await createClient();
  const { error } = await supabase.rpc('set_student_goal', {
    p_org: s(formData, 'orgId'),
    p_student: s(formData, 'studentId'),
    p_pages_per_day: Number(s(formData, 'pagesPerDay')),
    p_target_pages: Number(s(formData, 'targetPages')) || 604,
    p_start_date: s(formData, 'startDate') || null,
    p_note: s(formData, 'note') || null,
  });
  if (error) redirect(withParam(back, 'error', error.message) as never);
  redirect(withParam(back, 'ok', (await staffStrings()).goal.saved) as never);
}

export async function clearStudentGoal(formData: FormData) {
  const back = safeBack(formData.get('back'), '/students');
  const supabase = await createClient();
  const { error } = await supabase.rpc('clear_student_goal', { p_org: s(formData, 'orgId'), p_student: s(formData, 'studentId') });
  if (error) redirect(withParam(back, 'error', error.message) as never);
  redirect(withParam(back, 'ok', (await staffStrings()).goal.cleared) as never);
}
