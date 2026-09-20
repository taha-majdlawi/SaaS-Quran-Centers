'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { safeBack, withParam } from '@/lib/calendar/actions-shared';

const s = (formData: FormData, key: string) => ((formData.get(key) as string) ?? '').trim();

// ---- chat (shared by the staff and portal pages) ---------------------------

const IMAGE_TYPES: Record<string, string> = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };

export async function sendChat(formData: FormData) {
  const back = safeBack(formData.get('back'), '/chat');
  const supabase = await createClient();
  const orgId = s(formData, 'orgId');

  // optional picture: uploaded first into <org>/<me>/, then referenced by the message
  let imagePath: string | null = null;
  const file = formData.get('image');
  if (file instanceof File && file.size > 0) {
    const ext = IMAGE_TYPES[file.type];
    if (!ext) redirect(withParam(back, 'error', 'الصور المسموحة: JPG أو PNG أو WebP') as never);
    if (file.size > 5 * 1024 * 1024) redirect(withParam(back, 'error', 'حجم الصورة الأقصى 5 ميغابايت') as never);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) redirect('/login' as never);
    const path = `${orgId}/${user.id}/${crypto.randomUUID()}.${ext}`;
    const { error: upError } = await supabase.storage.from('chat-images').upload(path, file, { contentType: file.type });
    if (upError) redirect(withParam(back, 'error', 'تعذّر رفع الصورة') as never);
    imagePath = path;
  }

  const { error } = await supabase.rpc('send_chat_message', {
    p_org: orgId,
    p_other: s(formData, 'otherId'),
    p_body: s(formData, 'body'),
    // a fresh ref per submit: a double click / retry never sends twice
    p_client_ref: s(formData, 'ref') || crypto.randomUUID(),
    p_image_path: imagePath,
  });
  if (error) redirect(withParam(back, 'error', error.message) as never);
  redirect(back as never);
}

export async function editChat(formData: FormData) {
  const back = safeBack(formData.get('back'), '/chat');
  const supabase = await createClient();
  const { error } = await supabase.rpc('edit_chat_message', { p_message: s(formData, 'id'), p_body: s(formData, 'body') });
  if (error) redirect(withParam(back, 'error', error.message) as never);
  redirect(back as never);
}

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
