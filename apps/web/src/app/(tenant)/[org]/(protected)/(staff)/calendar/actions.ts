'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { runRpc, safeBack, withParam } from '@/lib/calendar/actions-shared';

const s = (formData: FormData, key: string) => ((formData.get(key) as string) ?? '').trim();
const orNull = (formData: FormData, key: string) => s(formData, key) || null;

export async function saveEntry(formData: FormData) {
  const id = orNull(formData, 'id');
  const back = id ? `/calendar/${id}/edit` : '/calendar/new';
  const supabase = await createClient();
  const capacity = s(formData, 'capacity');
  const { data, error } = await supabase.rpc('admin_save_calendar_entry', {
    p_org: s(formData, 'orgId'),
    p_id: id,
    p_type: s(formData, 'typeId'),
    p_title: s(formData, 'title'),
    p_description: orNull(formData, 'description'),
    p_start: orNull(formData, 'startDate'),
    p_end: orNull(formData, 'endDate'),
    // '' = follow the type's default; the checkbox is only posted when overriding.
    p_is_working_day: formData.get('workingOverride') === 'on' ? formData.get('isWorkingDay') === 'on' : null,
    p_audience: s(formData, 'audience') || 'all',
    p_circle: orNull(formData, 'circleId'),
    p_stage: orNull(formData, 'stageId'),
    p_starts_at: orNull(formData, 'startsAt'),
    p_location: orNull(formData, 'location'),
    p_capacity: capacity ? Number(capacity) : null,
    p_registration_open: formData.get('registrationOpen') === 'on',
    p_deadline: orNull(formData, 'deadline'),
  });
  if (error) redirect(withParam(back, 'error', error.message) as never);
  redirect(`/calendar/${data as string}?ok=saved` as never);
}

export async function deleteEntry(formData: FormData) {
  return runRpc('admin_delete_calendar_entry', { p_org: s(formData, 'orgId'), p_id: s(formData, 'id') }, '/calendar', 'deleted');
}

export async function saveType(formData: FormData) {
  return runRpc(
    'admin_save_calendar_type',
    {
      p_org: s(formData, 'orgId'),
      p_id: orNull(formData, 'id'),
      p_name: s(formData, 'name'),
      p_default_is_working: formData.get('defaultIsWorking') === 'on',
      p_color: s(formData, 'color') || '#64748b',
      p_sort_order: Number(s(formData, 'sortOrder') || 0),
      p_is_active: formData.get('isActive') === 'on',
      p_supports_registration: formData.get('supportsRegistration') === 'on',
      p_requires_consent: formData.get('requiresConsent') === 'on',
    },
    '/calendar/types',
    'saved',
  );
}

export async function deleteType(formData: FormData) {
  return runRpc('admin_delete_calendar_type', { p_org: s(formData, 'orgId'), p_id: s(formData, 'id') }, '/calendar/types', 'saved');
}

// ---- roster (staff) --------------------------------------------------------

export async function staffRegister(formData: FormData) {
  const back = safeBack(formData.get('back'), '/calendar');
  return runRpc(
    'register_for_entry',
    { p_org: s(formData, 'orgId'), p_entry: s(formData, 'entryId'), p_student: s(formData, 'studentId'), p_note: null },
    back,
    'registered',
  );
}

export async function staffUnregister(formData: FormData) {
  const back = safeBack(formData.get('back'), '/calendar');
  return runRpc('unregister_from_entry', { p_registration: s(formData, 'registrationId') }, back, 'removed');
}

export async function recordConsent(formData: FormData) {
  const back = safeBack(formData.get('back'), '/calendar');
  return runRpc(
    'staff_record_consent',
    { p_registration: s(formData, 'registrationId'), p_decision: s(formData, 'decision') },
    back,
    'consent',
  );
}

export async function setResult(formData: FormData) {
  const back = safeBack(formData.get('back'), '/calendar');
  const rank = s(formData, 'rank');
  return runRpc(
    'set_registration_result',
    { p_registration: s(formData, 'registrationId'), p_rank: rank ? Number(rank) : null, p_note: orNull(formData, 'note') },
    back,
    'result',
  );
}
