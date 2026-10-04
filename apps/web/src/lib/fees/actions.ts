'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { runRpc, safeBack, withParam } from '@/lib/calendar/actions-shared';
import { staffStrings } from '@/lib/i18n/server';

// Student fees (0081): every write is an admin RPC that also checks the feature is on.

const s = (formData: FormData, key: string) => ((formData.get(key) as string) ?? '').trim();
const orNull = (formData: FormData, key: string) => s(formData, key) || null;
const num = (formData: FormData, key: string) => (s(formData, key) === '' ? null : Number(s(formData, key)));

export async function enableFees(formData: FormData) {
  return runRpc('set_fee_settings', { p_org: s(formData, 'orgId'), p_enabled: true }, '/fees', 'enabled');
}

export async function saveFeeSettings(formData: FormData) {
  return runRpc(
    'set_fee_settings',
    {
      p_org: s(formData, 'orgId'),
      p_enabled: true,
      p_currency: s(formData, 'currency'),
      p_due_day: num(formData, 'dueDay'),
      p_reminder_days: num(formData, 'reminderDays'),
    },
    '/fees?tab=settings',
    'settings',
  );
}

export async function disableFees(formData: FormData) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('set_fee_settings', { p_org: s(formData, 'orgId'), p_enabled: false });
  if (error) redirect(withParam('/fees?tab=settings', 'error', error.message) as never);
  redirect('/settings' as never);
}

export async function saveFeePlan(formData: FormData) {
  return runRpc(
    'save_fee_plan',
    {
      p_org: s(formData, 'orgId'),
      p_id: orNull(formData, 'id'),
      p_name: s(formData, 'name'),
      p_amount: Number(s(formData, 'amount')),
      p_period: s(formData, 'period'),
      p_active: formData.get('active') === 'on',
    },
    '/fees?tab=plans',
    'plan',
  );
}

export async function deleteFeePlan(formData: FormData) {
  return runRpc('delete_fee_plan', { p_org: s(formData, 'orgId'), p_id: s(formData, 'id') }, '/fees?tab=plans', 'deleted');
}

export async function issueFeeCharges(formData: FormData) {
  return runRpc(
    'issue_fee_charges',
    { p_org: s(formData, 'orgId'), p_plan: s(formData, 'planId'), p_title: s(formData, 'title'), p_due_date: orNull(formData, 'dueDate') },
    '/fees?tab=plans',
    'issued',
  );
}

/** The plan (or none) for the ticked students, or for one student from their account page. */
export async function assignFeePlan(formData: FormData) {
  const back = safeBack(formData.get('back'), '/fees');
  const students = (formData.getAll('students') as string[]).filter(Boolean);
  if (!students.length) redirect(withParam(back, 'error', (await staffStrings()).fees.pickStudents) as never);
  return runRpc(
    'set_students_fee_plan',
    {
      p_org: s(formData, 'orgId'),
      p_students: students,
      p_plan: orNull(formData, 'planId'),
      p_discount: num(formData, 'discount') ?? 0,
      p_exempt: formData.get('exempt') === 'on',
      p_note: orNull(formData, 'note'),
    },
    back,
    'assigned',
  );
}

export async function addFeeCharge(formData: FormData) {
  const id = s(formData, 'studentId');
  return runRpc(
    'add_fee_charge',
    { p_org: s(formData, 'orgId'), p_student: id, p_title: s(formData, 'title'), p_amount: Number(s(formData, 'amount')), p_due_date: orNull(formData, 'dueDate') },
    `/fees/${id}`,
    'charge',
  );
}

export async function setFeeChargeStatus(formData: FormData) {
  return runRpc(
    'set_fee_charge_status',
    { p_org: s(formData, 'orgId'), p_charge: s(formData, 'id'), p_status: s(formData, 'status') },
    `/fees/${s(formData, 'studentId')}`,
    'status',
  );
}

export async function recordFeePayment(formData: FormData) {
  const id = s(formData, 'studentId');
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('record_fee_payment', {
    p_org: s(formData, 'orgId'),
    p_student: id,
    p_amount: Number(s(formData, 'amount')),
    p_method: s(formData, 'method') || 'cash',
    p_paid_on: orNull(formData, 'paidOn'),
    p_note: orNull(formData, 'note'),
    // a double click sends the same form twice: one payment, one receipt
    p_client_ref: orNull(formData, 'clientRef'),
  });
  if (error) redirect(withParam(`/fees/${id}`, 'error', error.message) as never);
  redirect(`/fees/${id}?ok=payment&receipt=${(data as { id: string }).id}` as never);
}

export async function voidFeePayment(formData: FormData) {
  return runRpc(
    'void_fee_payment',
    { p_org: s(formData, 'orgId'), p_payment: s(formData, 'id'), p_reason: orNull(formData, 'reason') },
    `/fees/${s(formData, 'studentId')}`,
    'voided',
  );
}
