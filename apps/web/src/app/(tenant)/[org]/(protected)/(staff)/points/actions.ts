'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export async function savePointsConfig(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const rules = {
    new_memorization: Number(formData.get('newMemorization') || 0),
    recent_review: Number(formData.get('recentReview') || 0),
    distant_review: Number(formData.get('distantReview') || 0),
  };
  const currencyName = (formData.get('currencyName') as string)?.trim() || 'نقاط';
  const exchangeRate = Number(formData.get('exchangeRate') || 1);

  const supabase = await createClient();

  const [{ error: pointsError }, { error: currencyError }] = await Promise.all([
    supabase.from('points_config').upsert({ organization_id: orgId, rules, updated_at: new Date().toISOString() }),
    supabase
      .from('currency_config')
      .upsert({
        organization_id: orgId,
        currency_name: currencyName,
        exchange_rate: exchangeRate,
        updated_at: new Date().toISOString(),
      }),
  ]);

  if (pointsError || currencyError) {
    const message = pointsError?.message ?? currencyError?.message ?? 'حدث خطأ';
    redirect(`/points?error=${encodeURIComponent(message)}` as never);
  }

  redirect('/points?saved=1');
}
