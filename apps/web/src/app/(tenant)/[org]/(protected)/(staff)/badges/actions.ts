'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { runRpc, safeBack, withParam } from '@/lib/calendar/actions-shared';

const s = (formData: FormData, key: string) => ((formData.get(key) as string) ?? '').trim();
const orNull = (formData: FormData, key: string) => s(formData, key) || null;

export async function saveBadge(formData: FormData) {
  const id = orNull(formData, 'id');
  const back = id ? `/badges/${id}` : '/badges/new';
  const duration = s(formData, 'durationDays');
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('save_badge', {
    p_org: s(formData, 'orgId'),
    p_id: id,
    p_name: s(formData, 'name'),
    p_description: orNull(formData, 'description'),
    p_icon: orNull(formData, 'icon'),
    p_color: s(formData, 'color') || '#f59e0b',
    p_rule_type: s(formData, 'ruleType'),
    p_threshold: Number(s(formData, 'threshold') || 0),
    p_param: orNull(formData, 'param'),
    p_duration_days: duration ? Number(duration) : null,
    p_is_active: formData.get('isActive') === 'on',
    p_sort_order: Number(s(formData, 'sortOrder') || 0),
  });
  if (error) redirect(withParam(back, 'error', error.message) as never);
  redirect(`/badges/${data as string}?ok=saved` as never);
}

export async function deleteBadge(formData: FormData) {
  return runRpc('delete_badge', { p_org: s(formData, 'orgId'), p_id: s(formData, 'id') }, '/badges', 'deleted');
}

export async function awardBadge(formData: FormData) {
  const back = safeBack(formData.get('back'), '/badges');
  return runRpc(
    'award_badge',
    { p_badge: s(formData, 'badgeId'), p_student: s(formData, 'studentId'), p_revoke: formData.get('revoke') === '1' },
    back,
    formData.get('revoke') === '1' ? 'revoked' : 'awarded',
  );
}

export async function awardToCircle(formData: FormData) {
  const back = safeBack(formData.get('back'), '/badges');
  return runRpc('award_badge_to_circle', { p_badge: s(formData, 'badgeId'), p_circle: s(formData, 'circleId') }, back, 'circle');
}

export async function evaluateAll(formData: FormData) {
  return runRpc('evaluate_org_badges', { p_org: s(formData, 'orgId') }, '/badges', 'evaluated');
}
