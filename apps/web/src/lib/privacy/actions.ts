'use server';

import { runRpc } from '@/lib/calendar/actions-shared';

const s = (f: FormData, k: string) => ((f.get(k) as string) ?? '').trim();

export async function requestDeletion(formData: FormData) {
  await runRpc('request_account_deletion', { p_org: s(formData, 'orgId'), p_reason: s(formData, 'reason') || null }, '/my/privacy', 'requested');
}

export async function reviewDeletion(formData: FormData) {
  await runRpc('review_deletion_request', { p_org: s(formData, 'orgId'), p_id: s(formData, 'id'), p_status: s(formData, 'status') }, '/deletion-requests', 'reviewed');
}
