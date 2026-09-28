'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { staffStrings } from '@/lib/i18n/server';

const KEY_PATTERN = /^[a-z0-9_]{1,40}$/;

/**
 * Saves the center's recitation grades: every row's label / points / active
 * flag, plus an optional new grade. Points are frozen on each recitation when
 * it is logged, so changing them here never rewrites history (eqraa rule).
 */
export async function saveGrades(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const supabase = await createClient();

  const rows: {
    organization_id: string;
    key: string;
    label: string;
    points: number;
    sort_order: number;
    is_active: boolean;
  }[] = [];

  const keys = formData.getAll('key') as string[];
  keys.forEach((key, i) => {
    const label = ((formData.getAll('label')[i] as string) ?? '').trim();
    if (!label) return;
    rows.push({
      organization_id: orgId,
      key,
      label,
      points: Math.max(0, Number(formData.getAll('points')[i] || 0)),
      sort_order: Number(formData.getAll('sort')[i] || i + 1),
      is_active: formData.get(`active_${key}`) === 'on',
    });
  });

  const newKey = ((formData.get('newKey') as string) ?? '').trim().toLowerCase();
  const newLabel = ((formData.get('newLabel') as string) ?? '').trim();
  if (newKey || newLabel) {
    if (!KEY_PATTERN.test(newKey) || !newLabel) {
      redirect(
        `/points?error=${encodeURIComponent((await staffStrings()).points.badKey)}` as never,
      );
    }
    rows.push({
      organization_id: orgId,
      key: newKey,
      label: newLabel,
      points: Math.max(0, Number(formData.get('newPoints') || 0)),
      sort_order: rows.length + 1,
      is_active: true,
    });
  }

  if (rows.length) {
    const { error } = await supabase.from('recitation_grades').upsert(rows, { onConflict: 'organization_id,key' });
    if (error) redirect(`/points?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/points?saved=1');
}
