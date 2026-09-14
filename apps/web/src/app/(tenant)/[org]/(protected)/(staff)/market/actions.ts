'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export async function createItem(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const name = (formData.get('name') as string)?.trim();
  const cost = Number(formData.get('cost') || 0);
  const stockRaw = formData.get('stock') as string;
  const stock = stockRaw ? Number(stockRaw) : null;

  const supabase = await createClient();
  const { error } = await supabase.from('market_items').insert({ organization_id: orgId, name, cost, stock });

  if (error) redirect(`/market/new?error=${encodeURIComponent(error.message)}` as never);

  redirect('/market');
}

export async function updateItem(formData: FormData) {
  const id = formData.get('id') as string;
  const name = (formData.get('name') as string)?.trim();
  const cost = Number(formData.get('cost') || 0);
  const stockRaw = formData.get('stock') as string;
  const stock = stockRaw ? Number(stockRaw) : null;
  const isActive = formData.get('isActive') === 'on';

  const supabase = await createClient();
  const { error } = await supabase
    .from('market_items')
    .update({ name, cost, stock, is_active: isActive })
    .eq('id', id);

  if (error) redirect(`/market/${id}?error=${encodeURIComponent(error.message)}` as never);

  redirect('/market');
}

export async function deleteItem(formData: FormData) {
  const id = formData.get('id') as string;

  const supabase = await createClient();
  await supabase.from('market_items').delete().eq('id', id);

  redirect('/market');
}

export async function recordPurchase(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const studentId = formData.get('studentId') as string;
  const itemId = formData.get('itemId') as string;

  const supabase = await createClient();

  const { data: item } = await supabase.from('market_items').select('cost').eq('id', itemId).maybeSingle();
  if (!item) redirect(`/market?error=${encodeURIComponent('العنصر غير موجود')}` as never);

  const { data: wallet } = await supabase
    .from('student_wallets')
    .select('balance')
    .eq('student_id', studentId)
    .maybeSingle();

  const balance = wallet?.balance ?? 0;
  if (balance < item!.cost) {
    redirect(`/market?error=${encodeURIComponent('رصيد الطالب غير كافٍ لهذا العنصر')}` as never);
  }

  const { error: purchaseError } = await supabase.from('market_purchases').insert({
    organization_id: orgId,
    student_id: studentId,
    item_id: itemId,
    cost: item!.cost,
    status: 'fulfilled',
  });

  if (purchaseError) redirect(`/market?error=${encodeURIComponent(purchaseError.message)}` as never);

  await supabase
    .from('student_wallets')
    .upsert({ student_id: studentId, organization_id: orgId, balance: balance - item!.cost });

  redirect('/market?purchased=1');
}

export async function adjustPoints(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const studentId = formData.get('studentId') as string;
  const amount = Number(formData.get('amount') || 0);

  const supabase = await createClient();
  const { data: wallet } = await supabase
    .from('student_wallets')
    .select('balance')
    .eq('student_id', studentId)
    .maybeSingle();

  const newBalance = (wallet?.balance ?? 0) + amount;

  const { error } = await supabase
    .from('student_wallets')
    .upsert({ student_id: studentId, organization_id: orgId, balance: newBalance });

  if (error) redirect(`/market?error=${encodeURIComponent(error.message)}` as never);

  redirect('/market?adjusted=1');
}
