'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { runRpc, safeBack, withParam } from '@/lib/calendar/actions-shared';

const s = (formData: FormData, key: string) => ((formData.get(key) as string) ?? '').trim();
const orNull = (formData: FormData, key: string) => s(formData, key) || null;

export async function saveItem(formData: FormData) {
  const id = orNull(formData, 'id');
  const back = id ? `/market/${id}` : '/market/new';
  const stock = s(formData, 'stock');
  const supabase = await createClient();
  const { error } = await supabase.rpc('save_market_item', {
    p_org: s(formData, 'orgId'),
    p_id: id,
    p_name: s(formData, 'name'),
    p_description: orNull(formData, 'description'),
    p_image_url: orNull(formData, 'imageUrl'),
    p_price: Number(s(formData, 'price')),
    p_stock: stock === '' ? null : Number(stock),
    p_is_active: formData.get('isActive') === 'on',
  });
  if (error) redirect(withParam(back, 'error', error.message) as never);
  redirect('/market?ok=item' as never);
}

export async function deleteItem(formData: FormData) {
  return runRpc('delete_market_item', { p_org: s(formData, 'orgId'), p_id: s(formData, 'id') }, '/market', 'deleted');
}

export async function saveConfig(formData: FormData) {
  return runRpc(
    'set_market_config',
    {
      p_org: s(formData, 'orgId'),
      p_points_per_unit: Number(s(formData, 'pointsPerUnit')),
      p_unit_value: Number(s(formData, 'unitValue')),
      p_symbol: s(formData, 'symbol'),
    },
    '/market',
    'config',
  );
}

export async function setPurchase(formData: FormData) {
  return runRpc(
    'admin_set_purchase_status',
    { p_purchase: s(formData, 'id'), p_status: s(formData, 'status') },
    safeBack(formData.get('back'), '/market'),
    'purchase',
  );
}
