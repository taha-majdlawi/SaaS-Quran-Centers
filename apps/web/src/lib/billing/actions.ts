'use server';

import { runRpc } from '@/lib/calendar/actions-shared';

const s = (f: FormData, k: string) => ((f.get(k) as string) ?? '').trim();

// ---- center admin (/billing). Every RPC re-checks is_org_admin itself.

export async function submitPayment(formData: FormData) {
  await runRpc(
    'billing_submit_request',
    {
      p_org: s(formData, 'orgId'),
      p_plan: s(formData, 'plan'),
      p_period: s(formData, 'period'),
      p_method: s(formData, 'method'),
      p_reference: s(formData, 'reference') || null,
      p_note: s(formData, 'note') || null,
    },
    '/billing',
    'submitted',
  );
}

export async function cancelPayment(formData: FormData) {
  await runRpc('billing_cancel_request', { p_id: s(formData, 'id') }, '/billing', 'cancelled');
}

// ---- platform owner (admin.{domain}/billing). Every RPC re-checks is_platform_owner itself.

export async function reviewPayment(formData: FormData) {
  await runRpc(
    'platform_review_billing_request',
    { p_id: s(formData, 'id'), p_decision: s(formData, 'decision'), p_note: s(formData, 'note') || null },
    '/billing',
    s(formData, 'decision') === 'approve' ? 'approved' : 'rejected',
  );
}

export async function recordPayment(formData: FormData) {
  await runRpc(
    'platform_record_payment',
    {
      p_org: s(formData, 'org'),
      p_plan: s(formData, 'plan'),
      p_period: s(formData, 'period'),
      p_amount_cents: Math.round(Number(s(formData, 'amount') || '0') * 100),
      p_method: s(formData, 'method'),
      p_note: s(formData, 'note') || null,
    },
    '/billing',
    'recorded',
  );
}

export async function saveBillingSettings(formData: FormData) {
  await runRpc(
    'platform_set_billing_settings',
    {
      p_enforce: formData.get('enforce') === 'on',
      p_grace_days: Number(s(formData, 'graceDays') || '0'),
      p_instructions: s(formData, 'instructions'),
    },
    '/billing',
    'saved',
  );
}
