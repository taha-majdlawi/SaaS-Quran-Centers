'use server';

import { runRpc, safeBack } from '@/lib/calendar/actions-shared';

const s = (formData: FormData, key: string) => ((formData.get(key) as string) ?? '').trim();

// Family side of the calendar. Every rule (whose child, seats, deadline, waiting
// list) is enforced by the RPCs; these only forward the request.

export async function familyRegister(formData: FormData) {
  return runRpc(
    'register_for_entry',
    { p_org: s(formData, 'orgId'), p_entry: s(formData, 'entryId'), p_student: s(formData, 'studentId'), p_note: null },
    safeBack(formData.get('back'), '/my/calendar'),
    'registered',
  );
}

export async function familyUnregister(formData: FormData) {
  return runRpc('unregister_from_entry', { p_registration: s(formData, 'registrationId') }, safeBack(formData.get('back'), '/my/calendar'), 'removed');
}

export async function familyJoinWaitlist(formData: FormData) {
  return runRpc(
    'join_waitlist',
    { p_org: s(formData, 'orgId'), p_entry: s(formData, 'entryId'), p_student: s(formData, 'studentId') },
    safeBack(formData.get('back'), '/my/calendar'),
    'waiting',
  );
}

export async function familyLeaveWaitlist(formData: FormData) {
  return runRpc(
    'leave_waitlist',
    { p_org: s(formData, 'orgId'), p_entry: s(formData, 'entryId'), p_student: s(formData, 'studentId') },
    safeBack(formData.get('back'), '/my/calendar'),
    'left',
  );
}
