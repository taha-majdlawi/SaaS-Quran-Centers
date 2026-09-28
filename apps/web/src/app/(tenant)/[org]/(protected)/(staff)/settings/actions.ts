'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { safeLogoUrl } from '@/lib/tenant/public-site';
import { staffStrings } from '@/lib/i18n/server';
import { LOCALES } from '@/lib/i18n/config';

export async function saveAttendanceReminder(formData: FormData) {
  const supabase = await createClient();
  const orgId = formData.get('orgId') as string;
  const hour = Math.min(20, Math.max(0, Number(formData.get('hour')) || 11));
  const { error } = await supabase.from('organization_settings').upsert(
    [
      { organization_id: orgId, key: 'attendance_reminder_enabled', value: formData.get('enabled') === 'on' ? 'true' : 'false' },
      { organization_id: orgId, key: 'attendance_reminder_hour', value: String(hour) },
    ],
    { onConflict: 'organization_id,key' },
  );
  if (error) redirect(`/settings?error=${encodeURIComponent(error.message)}` as never);
  redirect('/settings?saved=1');
}

export async function saveDigestSettings(formData: FormData) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('set_digest_settings', {
    p_org: formData.get('orgId') as string,
    p_enabled: formData.get('enabled') === 'on',
    p_dow: Number(formData.get('dow')),
    p_hour: Number(formData.get('hour')),
  });
  if (error) redirect(`/settings?error=${encodeURIComponent(error.message)}` as never);
  redirect('/settings?saved=1');
}

export async function updateOrgSettings(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const name = (formData.get('name') as string)?.trim();
  const rawLogo = ((formData.get('logoUrl') as string) ?? '').trim();
  const logoUrl = safeLogoUrl(rawLogo);
  const primaryColor = formData.get('primaryColor') as string;
  const secondaryColor = formData.get('secondaryColor') as string;
  const timezone = (formData.get('timezone') as string)?.trim();

  if (rawLogo && !logoUrl) {
    redirect(`/settings?error=${encodeURIComponent((await staffStrings()).settings.logoHttps)}` as never);
  }

  const supabase = await createClient();
  const { error } = await supabase
    .from('organizations')
    .update({ name, logo_url: logoUrl, primary_color: primaryColor, secondary_color: secondaryColor, timezone })
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
  'quran_default_reciter',
  'default_language',
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
    // several checkboxes -> one comma-separated value (empty = every reciter)
    {
      organization_id: orgId,
      key: 'quran_reciters',
      value: (formData.getAll('quran_reciters') as string[]).join(','),
      updated_at: new Date().toISOString(),
    },
    ...FLAG_SETTINGS.map((key) => ({
      organization_id: orgId,
      key,
      value: formData.get(key) === 'on' ? 'true' : 'false',
      updated_at: new Date().toISOString(),
    })),
  ];

  // only a language the site ships; anything else falls back to Arabic
  const lang = rows.find((r) => r.key === 'default_language');
  if (lang && !(LOCALES as readonly string[]).includes(lang.value)) lang.value = 'ar';

  const backdate = Number(rows.find((r) => r.key === 'backdate_days')?.value);
  if (!Number.isInteger(backdate) || backdate < 0 || backdate > 365) {
    redirect(`/settings?error=${encodeURIComponent((await staffStrings()).settings.backdateRange)}` as never);
  }

  const { error } = await supabase.from('organization_settings').upsert(rows, { onConflict: 'organization_id,key' });
  if (error) redirect(`/settings?error=${encodeURIComponent(error.message)}` as never);
  redirect('/settings?saved=1');
}
