'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { readParts } from '@/lib/serd/format';

const fail = (path: string, message: string): never =>
  redirect(`${path}${path.includes('?') ? '&' : '?'}error=${encodeURIComponent(message)}` as never);

function readErrors(formData: FormData) {
  const out: { type_id: string; count: number }[] = [];
  for (const [key, value] of formData.entries()) {
    if (!key.startsWith('err_')) continue;
    const count = Number(value);
    if (Number.isFinite(count) && count > 0) out.push({ type_id: key.slice(4), count: Math.floor(count) });
  }
  return out;
}

/** Teacher/admin grades a recital. Score, weights and permissions are all decided in SQL. */
export async function submitSerd(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const sessionId = ((formData.get('sessionId') as string) ?? '') || null;
  const back = sessionId ? `/serd/new?session=${sessionId}` : '/serd/new';
  const parts = readParts(formData);
  if (!parts.length) fail(back, 'اختر جزءًا واحدًا على الأقل');

  const supabase = await createClient();
  const { data, error } = await supabase.rpc('teacher_submit_serd', {
    p_org: orgId,
    p_student: ((formData.get('studentId') as string) ?? '') || null,
    p_student_name: ((formData.get('studentName') as string) ?? '').trim() || null,
    p_parts: parts,
    p_date: ((formData.get('date') as string) ?? '') || null,
    p_notes: ((formData.get('notes') as string) ?? '').trim() || null,
    p_errors: readErrors(formData),
    p_client_ref: crypto.randomUUID(),
    p_session_id: sessionId,
  });
  if (error) fail(back, error.message);

  const score = (data as { score_percent?: number } | null)?.score_percent;
  redirect(`/serd?saved=${score ?? ''}` as never);
}

export async function scheduleSerd(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const parts = readParts(formData);
  if (!parts.length) fail('/serd/schedule', 'اختر جزءًا واحدًا على الأقل');

  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_schedule_serd', {
    p_org: orgId,
    p_student: formData.get('studentId') as string,
    p_parts: parts,
    p_date: ((formData.get('date') as string) ?? '') || null,
    p_notes: ((formData.get('notes') as string) ?? '').trim() || null,
    p_teacher: ((formData.get('teacherId') as string) ?? '') || null,
  });
  if (error) fail('/serd/schedule', error.message);
  redirect('/serd?scheduled=1' as never);
}

export async function reviewSerd(formData: FormData) {
  const supabase = await createClient();
  const decision = formData.get('decision') as string;
  const { error } = await supabase.rpc('admin_review_serd', {
    p_session: formData.get('id') as string,
    p_decision: decision,
    p_student: ((formData.get('studentId') as string) ?? '') || null,
    p_reason: ((formData.get('reason') as string) ?? '').trim() || null,
  });
  if (error) fail('/serd', error.message);
  redirect(`/serd?reviewed=${decision}` as never);
}

export async function deleteSerd(formData: FormData) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_delete_serd', { p_session: formData.get('id') as string });
  if (error) fail('/serd', error.message);
  redirect('/serd?deleted=1' as never);
}

// ---- settings (admin) ------------------------------------------------------

const denominators = (formData: FormData, key: string) =>
  (formData.getAll(key) as string[]).map(Number).filter((n) => [2, 4, 8].includes(n));

export async function saveSerdSettings(formData: FormData) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('set_serd_settings', {
    p_org: formData.get('orgId') as string,
    p_pass_percent: Number(formData.get('passPercent')),
    p_points_per_juz: Number(formData.get('pointsPerJuz')),
    p_denominators: [1, ...denominators(formData, 'den')],
  });
  if (error) fail('/serd/settings', error.message);
  redirect('/serd/settings?saved=1' as never);
}

export async function saveErrorType(formData: FormData) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('save_serd_error_type', {
    p_org: formData.get('orgId') as string,
    p_id: ((formData.get('id') as string) ?? '') || null,
    p_name: formData.get('name') as string,
    p_errors_per_unit: Number(formData.get('errorsPerUnit')),
    p_percent_per_unit: Number(formData.get('percentPerUnit')),
    p_is_active: formData.get('isActive') === 'on',
    p_sort_order: Number(formData.get('sortOrder') ?? 0),
  });
  if (error) fail('/serd/settings', error.message);
  redirect('/serd/settings?saved=1' as never);
}

export async function deleteErrorType(formData: FormData) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('delete_serd_error_type', {
    p_org: formData.get('orgId') as string,
    p_id: formData.get('id') as string,
  });
  if (error) fail('/serd/settings', error.message);
  redirect('/serd/settings?saved=1' as never);
}

export async function saveStagePolicy(formData: FormData) {
  const supabase = await createClient();
  const pass = ((formData.get('passPercent') as string) ?? '').trim();
  const { error } = await supabase.rpc('set_serd_stage_policy', {
    p_org: formData.get('orgId') as string,
    p_stage: formData.get('stageId') as string,
    p_denominators: denominators(formData, 'den'),
    p_pass_percent: pass === '' ? null : Number(pass),
  });
  if (error) fail('/serd/settings', error.message);
  redirect('/serd/settings?saved=1' as never);
}
