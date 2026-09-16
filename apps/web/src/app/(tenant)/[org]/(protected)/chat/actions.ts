'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export async function createThread(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const otherUserId = formData.get('userId') as string;

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect('/login' as never);

  const { data: thread, error } = await supabase
    .from('chat_threads')
    .insert({ organization_id: orgId, is_group: false, created_by: user.id })
    .select('id')
    .single();

  if (error || !thread) {
    redirect(`/chat/new?error=${encodeURIComponent(error?.message ?? 'فشل إنشاء المحادثة')}` as never);
  }

  // chat_participants_insert (migration 0020) rejects the second row unless
  // otherUserId is an admin or a chat_contacts match for the caller - clean
  // up the now-orphaned thread rather than leaving an empty one behind, same
  // as apps/mobile's ChatRepository.createThread.
  const { error: participantsError } = await supabase.from('chat_thread_participants').insert([
    { thread_id: thread.id, user_id: user.id },
    { thread_id: thread.id, user_id: otherUserId },
  ]);

  if (participantsError) {
    await supabase.from('chat_threads').delete().eq('id', thread.id);
    redirect(`/chat/new?error=${encodeURIComponent('لا يمكنك مراسلة هذا العضو')}` as never);
  }

  redirect(`/chat/${thread.id}` as never);
}

export async function sendMessage(formData: FormData) {
  const threadId = formData.get('threadId') as string;
  const body = (formData.get('body') as string)?.trim();

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect('/login' as never);

  if (body) {
    await supabase.from('chat_messages').insert({ thread_id: threadId, sender_id: user.id, body });
  }

  redirect(`/chat/${threadId}` as never);
}
