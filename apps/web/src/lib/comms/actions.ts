'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { safeBack, withParam } from '@/lib/calendar/actions-shared';

const s = (formData: FormData, key: string) => ((formData.get(key) as string) ?? '').trim();

// ---- chat: sending / editing / live updates happen in the browser (components/chat-conversation.tsx) ----

export async function muteChat(formData: FormData) {
  const back = safeBack(formData.get('back'), '/chat');
  const supabase = await createClient();
  await supabase.rpc('set_thread_muted', { p_thread: s(formData, 'threadId'), p_muted: formData.get('muted') === '1' });
  redirect(back as never);
}

// ---- notifications ----------------------------------------------------------

export async function markAllRead(formData: FormData) {
  const back = safeBack(formData.get('back'), '/notifications');
  const supabase = await createClient();
  await supabase.rpc('mark_notifications_read', { p_org: s(formData, 'orgId'), p_ids: null });
  redirect(back as never);
}

export async function setPref(formData: FormData) {
  const back = safeBack(formData.get('back'), '/notifications');
  const supabase = await createClient();
  await supabase.rpc('set_notification_pref', {
    p_org: s(formData, 'orgId'),
    p_event: s(formData, 'event'),
    p_enabled: formData.get('enabled') === '1',
  });
  redirect(back as never);
}

// ---- announcements ----------------------------------------------------------

export async function saveAnnouncement(formData: FormData) {
  const id = s(formData, 'id') || null;
  const back = safeBack(formData.get('back'), '/announcements');
  const supabase = await createClient();
  const { error } = await supabase.rpc('save_announcement', {
    p_org: s(formData, 'orgId'),
    p_id: id,
    p_title: s(formData, 'title'),
    p_body: s(formData, 'body'),
    p_audience: s(formData, 'audience') || 'all',
    p_circle: s(formData, 'circleId') || null,
    p_pinned: formData.get('pinned') === 'on',
    p_publish: formData.get('publish') === 'on',
    p_expires: s(formData, 'expiresOn') || null,
  });
  if (error) redirect(withParam(id ? `/announcements/${id}` : '/announcements/new', 'error', error.message) as never);
  redirect(withParam(back, 'ok', 'saved') as never);
}

export async function deleteAnnouncement(formData: FormData) {
  const supabase = await createClient();
  await supabase.rpc('delete_announcement', { p_org: s(formData, 'orgId'), p_id: s(formData, 'id') });
  redirect('/announcements?ok=deleted' as never);
}
