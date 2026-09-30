'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { staffStrings } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

const N = async () => (await staffStrings()).notif;

const s = (formData: FormData, key: string) => ((formData.get(key) as string) ?? '').trim();

function to(tab: string, kind: 'ok' | 'error', message: string): never {
  redirect(`/notifications?tab=${tab}&${kind}=${encodeURIComponent(message)}` as never);
}

export async function saveTemplate(formData: FormData) {
  const supabase = await createClient();
  const lead = s(formData, 'lead');
  const { error } = await supabase.rpc('admin_save_notification_template', {
    p_org: s(formData, 'orgId'),
    p_event: s(formData, 'event'),
    p_title: s(formData, 'title'),
    p_body: s(formData, 'body'),
    p_lead: lead === '' ? null : Number(lead),
    p_audience: s(formData, 'audience') || 'source',
    p_enabled: formData.get('enabled') === 'on',
  });
  if (error) to('templates', 'error', error.message);
  to('templates', 'ok', (await N()).okTemplate);
}

export async function resetTemplate(formData: FormData) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_reset_notification_template', { p_org: s(formData, 'orgId'), p_event: s(formData, 'event') });
  if (error) to('templates', 'error', error.message);
  to('templates', 'ok', (await N()).okReset);
}

export async function saveNotificationSettings(formData: FormData) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_save_notification_settings', {
    p_org: s(formData, 'orgId'),
    p_quiet_from: s(formData, 'quiet_from'),
    p_quiet_to: s(formData, 'quiet_to'),
    p_day_start: s(formData, 'day_start_time'),
    p_grace: Number(s(formData, 'late_grace_hours')),
    p_idle: Number(s(formData, 'idle_days')),
    p_paused: formData.get('is_paused') === 'on',
    p_idle_teacher: Number(s(formData, 'idle_teacher_days')) || null,
    p_absence_count: Number(s(formData, 'absence_alert_count')) || null,
    p_absence_window: Number(s(formData, 'absence_alert_window')) || null,
    p_checkin_time: s(formData, 'checkin_reminder_time') || null,
  });
  if (error) to('settings', 'error', error.message);
  to('settings', 'ok', (await N()).okSettings);
}

export async function sendBroadcast(formData: FormData) {
  const supabase = await createClient();
  const mode = s(formData, 'mode');
  const audience = s(formData, 'audience') || 'all';
  let userIds: string[] | null = null;
  if (mode === 'self') {
    const { data } = await supabase.auth.getUser();
    userIds = data.user ? [data.user.id] : null;
  } else if (audience === '__people__') {
    userIds = formData.getAll('user').map(String);
    if (!userIds.length) to('send', 'error', (await N()).pickOne);
  }
  const { data, error } = await supabase.rpc('admin_send_notification', {
    p_org: s(formData, 'orgId'),
    p_title: s(formData, 'title'),
    p_body: s(formData, 'body'),
    p_audience: audience === '__people__' ? 'all' : audience,
    p_circle: s(formData, 'circle') || null,
    p_user_ids: userIds,
    p_deep_link: s(formData, 'deep_link') || null,
  });
  if (error) to('send', 'error', error.message);
  const r = data as { sent: number; no_device: number };
  to('send', 'ok', fmt((await N()).okSent, { n: r.sent }) + (r.no_device ? fmt((await N()).okNoDevice, { n: r.no_device }) : ''));
}

export async function sendTestPush(formData: FormData) {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('send_test_push', {
    p_org: s(formData, 'orgId'),
    p_user: s(formData, 'userId') || null,
  });
  if (error) to('devices', 'error', error.message);
  to('devices', 'ok', fmt((await N()).okTest, { n: Number(data) || 1 }));
}

export async function saveAttendanceReminderSetting(formData: FormData) {
  const supabase = await createClient();
  const hour = Math.min(20, Math.max(0, Number(formData.get('hour')) || 11));
  const orgId = s(formData, 'orgId');
  const { error } = await supabase.from('organization_settings').upsert(
    [
      { organization_id: orgId, key: 'attendance_reminder_enabled', value: formData.get('enabled') === 'on' ? 'true' : 'false' },
      { organization_id: orgId, key: 'attendance_reminder_hour', value: String(hour) },
    ],
    { onConflict: 'organization_id,key' },
  );
  if (error) to('settings', 'error', error.message);
  to('settings', 'ok', (await N()).okAttendance);
}

export async function saveDigestSetting(formData: FormData) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('set_digest_settings', {
    p_org: s(formData, 'orgId'),
    p_enabled: formData.get('enabled') === 'on',
    p_dow: Number(formData.get('dow')),
    p_hour: Number(formData.get('hour')),
  });
  if (error) to('settings', 'error', error.message);
  to('settings', 'ok', (await N()).okDigest);
}
