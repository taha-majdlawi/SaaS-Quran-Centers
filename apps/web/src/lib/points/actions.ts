'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { safeBack, withParam } from '@/lib/calendar/actions-shared';
import { fmt } from '@/lib/i18n/config';
import { staffStrings } from '@/lib/i18n/server';

// The points system (0096). Every value is checked and written by the database functions; these
// only pass the form on and come back to the page with ?ok= or ?error=.

const s = (formData: FormData, key: string) => ((formData.get(key) as string) ?? '').trim();
const int = (formData: FormData, key: string) => {
  const v = s(formData, key);
  return v === '' ? null : Math.trunc(Number(v));
};

async function finish(back: string, error: { message: string } | null, okMessage: string): Promise<never> {
  if (error) redirect(withParam(back, 'error', error.message) as never);
  redirect(withParam(back, 'ok', okMessage) as never);
}

export async function savePointsMode(formData: FormData) {
  const back = safeBack(formData.get('back'), '/points');
  const supabase = await createClient();
  const { error } = await supabase.rpc('set_points_mode', {
    p_org: s(formData, 'orgId'),
    p_mode: s(formData, 'mode'),
    p_suggest: formData.get('suggest') === 'on',
  });
  await finish(back, error, (await staffStrings()).points.modeSaved);
}

export async function saveAttendancePoints(formData: FormData) {
  const back = safeBack(formData.get('back'), '/points');
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('set_attendance_points', {
    p_org: s(formData, 'orgId'),
    p_present: int(formData, 'present') ?? 0,
    p_absent: int(formData, 'absent') ?? 0,
    p_late: int(formData, 'late') ?? 0,
    p_excused: int(formData, 'excused') ?? 0,
    p_from: s(formData, 'from') || null,
  });
  await finish(back, error, fmt((await staffStrings()).points.attSaved, { n: (data as number | null) ?? 0 }));
}

export async function savePointReason(formData: FormData) {
  const back = safeBack(formData.get('back'), '/points');
  const supabase = await createClient();
  const { error } = await supabase.rpc('save_point_reason', {
    p_org: s(formData, 'orgId'),
    p_id: s(formData, 'id') || null,
    p_name: s(formData, 'name'),
    p_points: int(formData, 'points'),
    p_kind: s(formData, 'kind'),
    p_active: s(formData, 'id') ? formData.get('active') === 'on' : true,
    p_sort: null,
  });
  await finish(back, error, (await staffStrings()).points.reasonSaved);
}

export async function deletePointReason(formData: FormData) {
  const back = safeBack(formData.get('back'), '/points');
  const supabase = await createClient();
  const { error } = await supabase.rpc('delete_point_reason', { p_org: s(formData, 'orgId'), p_id: s(formData, 'id') });
  await finish(back, error, (await staffStrings()).points.reasonDeleted);
}

export async function recomputePoints(formData: FormData) {
  const back = safeBack(formData.get('back'), '/points');
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('recompute_all_points', { p_org: s(formData, 'orgId') });
  await finish(back, error, fmt((await staffStrings()).points.repaired, { n: (data as number | null) ?? 0 }));
}

export async function awardPoints(formData: FormData) {
  const back = safeBack(formData.get('back'), '/students');
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('teacher_award_points', {
    p_org: s(formData, 'orgId'),
    p_student: s(formData, 'studentId'),
    p_reason: s(formData, 'reason'),
    p_note: s(formData, 'note') || null,
    p_date: null,
    // one per form: a double submit is the same entry, not two
    p_client_ref: s(formData, 'ref') || null,
  });
  const points = (data as { points?: number } | null)?.points ?? 0;
  await finish(back, error, fmt((await staffStrings()).points.awarded, { points: points > 0 ? `+${points}` : points }));
}

export async function undoPointEntry(formData: FormData) {
  const back = safeBack(formData.get('back'), '/students');
  const supabase = await createClient();
  const { error } = await supabase.rpc('delete_point_adjustment', { p_org: s(formData, 'orgId'), p_id: s(formData, 'id') });
  await finish(back, error, (await staffStrings()).points.undone);
}

export async function saveOpeningBalance(formData: FormData) {
  const back = safeBack(formData.get('back'), '/students');
  const supabase = await createClient();
  const { error } = await supabase.rpc('set_opening_balance', {
    p_org: s(formData, 'orgId'),
    p_student: s(formData, 'studentId'),
    p_points: int(formData, 'points') ?? 0,
    p_note: s(formData, 'note') || null,
  });
  await finish(back, error, (await staffStrings()).points.openingSaved);
}
