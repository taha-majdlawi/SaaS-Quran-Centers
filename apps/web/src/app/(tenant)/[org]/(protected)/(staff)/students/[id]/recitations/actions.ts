'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { staffStrings } from '@/lib/i18n/server';

/**
 * Logs one or more surahs for a student in a single session. Points are never
 * computed here: log_recitation stamps them from the center's own grade table,
 * enforces "only your own circle", the back-date window and ayah bounds.
 */
export async function logRecitation(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const studentId = formData.get('studentId') as string;
  const type = formData.get('type') as string;
  const grade = formData.get('grade') as string;
  const notes = ((formData.get('notes') as string) ?? '').trim() || null;
  const date = (formData.get('date') as string) || '';
  const back = `/students/${studentId}/recitations`;

  const surahs = formData.getAll('surah') as string[];
  const froms = formData.getAll('ayahFrom') as string[];
  const tos = formData.getAll('ayahTo') as string[];

  const parts = surahs
    .map((s, i) => ({ surah: Number(s), from: Number(froms[i]), to: Number(tos[i]) }))
    .filter((p) => p.surah > 0);

  if (!parts.length) redirect(`${back}?error=${encodeURIComponent((await staffStrings()).recitations.needSurah)}` as never);
  if (!grade) redirect(`${back}?error=${encodeURIComponent((await staffStrings()).recitations.needGrade)}` as never);

  const supabase = await createClient();
  const group = parts.length > 1 ? crypto.randomUUID() : null;
  // Today keeps the real time; a back-dated entry is placed at midday.
  const recordedAt = date && date !== new Date().toISOString().slice(0, 10) ? `${date}T12:00:00Z` : null;

  let total = 0;
  for (const p of parts) {
    const { data, error } = await supabase.rpc('log_recitation', {
      p_org: orgId,
      p_student_id: studentId,
      p_type: type,
      p_surah: p.surah,
      p_ayah_from: p.from,
      p_ayah_to: p.to,
      p_grade: grade,
      p_notes: notes,
      p_client_ref: crypto.randomUUID(),
      p_recorded_at: recordedAt,
      p_session_group_id: group,
    });
    if (error) redirect(`${back}?error=${encodeURIComponent(error.message)}` as never);
    total += (data as { points_awarded?: number } | null)?.points_awarded ?? 0;
  }

  redirect(`${back}?saved=${total}` as never);
}

export async function setStudentPlan(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const studentId = formData.get('studentId') as string;
  const plan = ((formData.get('plan') as string) ?? '').trim();
  const back = `/students/${studentId}/recitations`;

  const supabase = await createClient();
  const { error } = await supabase.rpc('set_student_plan', {
    p_org: orgId,
    p_student: studentId,
    p_next_plan: plan,
  });
  if (error) redirect(`${back}?error=${encodeURIComponent(error.message)}` as never);
  redirect(`${back}?planSaved=1` as never);
}

export async function deleteRecitation(formData: FormData) {
  const id = formData.get('id') as string;
  const studentId = formData.get('studentId') as string;
  const back = `/students/${studentId}/recitations`;

  const supabase = await createClient();
  const { error } = await supabase.rpc('delete_recitation', { p_id: id });
  if (error) redirect(`${back}?error=${encodeURIComponent(error.message)}` as never);
  redirect(`${back}?deleted=1` as never);
}

export async function updateRecitation(formData: FormData) {
  const id = formData.get('id') as string;
  const studentId = formData.get('studentId') as string;
  const back = `/students/${studentId}/recitations`;

  const supabase = await createClient();
  const { error } = await supabase.rpc('update_recitation', {
    p_id: id,
    p_type: formData.get('type') as string,
    p_surah: Number(formData.get('surah')),
    p_ayah_from: Number(formData.get('ayahFrom')),
    p_ayah_to: Number(formData.get('ayahTo')),
    p_grade: formData.get('grade') as string,
    p_notes: ((formData.get('notes') as string) ?? '').trim() || null,
  });
  if (error) {
    redirect(`${back}/${id}?error=${encodeURIComponent(error.message)}` as never);
  }
  redirect(`${back}?updated=1` as never);
}
