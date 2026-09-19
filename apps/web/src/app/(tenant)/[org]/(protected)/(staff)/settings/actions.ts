'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export async function updateOrgSettings(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const name = (formData.get('name') as string)?.trim();
  const primaryColor = formData.get('primaryColor') as string;
  const secondaryColor = formData.get('secondaryColor') as string;
  const timezone = (formData.get('timezone') as string)?.trim();

  const supabase = await createClient();
  const { error } = await supabase
    .from('organizations')
    .update({ name, primary_color: primaryColor, secondary_color: secondaryColor, timezone })
    .eq('id', orgId);

  if (error) {
    redirect(`/settings?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/settings?saved=1');
}

/** Working days: attendance % is measured against these, not against 7. */
export async function saveWeekdays(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const supabase = await createClient();

  const rows = Array.from({ length: 7 }, (_, dow) => {
    const working = formData.get(`working_${dow}`) === 'on';
    return {
      organization_id: orgId,
      dow,
      label: (formData.get(`label_${dow}`) as string) || String(dow),
      is_working: working,
      // A serd day must be a working day (DB check constraint).
      is_serd_day: working && formData.get(`serd_${dow}`) === 'on',
    };
  });

  const { error } = await supabase.from('center_weekdays').upsert(rows, { onConflict: 'organization_id,dow' });
  if (error) redirect(`/settings?error=${encodeURIComponent(error.message)}` as never);
  redirect('/settings?saved=1');
}

const TEXT_SETTINGS = [
  'backdate_days',
  'phone_country_code',
  'whatsapp_group_link',
  'center_location_label',
  'prayer_lat',
  'prayer_lng',
  'prayer_calc_method',
  'prayer_madhab',
] as const;

const FLAG_SETTINGS = ['flag_market_enabled', 'flag_leaderboard_enabled', 'flag_teacher_manage_students'] as const;

/** Per-center switches and values that eqraa hard-codes. */
export async function saveCenterSettings(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const supabase = await createClient();

  const rows = [
    ...TEXT_SETTINGS.map((key) => ({
      organization_id: orgId,
      key,
      value: ((formData.get(key) as string) ?? '').trim(),
      updated_at: new Date().toISOString(),
    })),
    ...FLAG_SETTINGS.map((key) => ({
      organization_id: orgId,
      key,
      value: formData.get(key) === 'on' ? 'true' : 'false',
      updated_at: new Date().toISOString(),
    })),
  ];

  const backdate = Number(rows.find((r) => r.key === 'backdate_days')?.value);
  if (!Number.isInteger(backdate) || backdate < 0 || backdate > 365) {
    redirect(`/settings?error=${encodeURIComponent('مدة الرجوع بتاريخ التسميع بين 0 و365 يومًا')}` as never);
  }

  const { error } = await supabase.from('organization_settings').upsert(rows, { onConflict: 'organization_id,key' });
  if (error) redirect(`/settings?error=${encodeURIComponent(error.message)}` as never);
  redirect('/settings?saved=1');
}
