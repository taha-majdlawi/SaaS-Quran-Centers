'use server';

import { runRpc, safeBack } from '@/lib/calendar/actions-shared';

const s = (formData: FormData, key: string) => ((formData.get(key) as string) ?? '').trim();

// Family side of the market. Balance, stock, "is the market on" and whose child
// it is are all enforced by the RPCs.
export async function buy(formData: FormData) {
  return runRpc(
    'purchase_market_item',
    { p_org: s(formData, 'orgId'), p_student: s(formData, 'studentId'), p_item: s(formData, 'itemId') },
    safeBack(formData.get('back'), '/my/market'),
    'bought',
  );
}

export async function cancelPurchase(formData: FormData) {
  return runRpc('cancel_my_purchase', { p_purchase: s(formData, 'id') }, safeBack(formData.get('back'), '/my/market'), 'cancelled');
}
