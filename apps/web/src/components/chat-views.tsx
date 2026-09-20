import { createClient } from '@/lib/supabase/server';
import { ScrollToEnd } from '@/components/scroll-to-end';
import { ChatImagePicker } from '@/components/chat-image-picker';
import { SubmitButton } from '@/components/submit-button';
import { ChatAutoRefresh } from '@/components/chat-auto-refresh';
import { editChat, muteChat, sendChat } from '@/lib/comms/actions';

export const ROLE_LABELS: Record<string, string> = { admin: 'مدير', teacher: 'معلم', student: 'طالب', guardian: 'ولي أمر' };

interface ThreadRow {
  thread_id: string;
  other_id: string;
  other_name: string;
  other_role: string;
  last_message_at: string | null;
  last_body: string | null;
  last_mine: boolean | null;
  unread: number;
  muted: boolean;
  can_reply: boolean;
}

interface Contact {
  user_id: string;
  name: string;
  role: string;
  detail: string | null;
}

interface Message {
  id: string;
  mine: boolean;
  body: string;
  image_path: string | null;
  created_at: string;
  edited_at: string | null;
  read_at: string | null;
}

const time = (iso: string) =>
  new Date(iso).toLocaleString('ar', { hour: '2-digit', minute: '2-digit', day: 'numeric', month: 'short' });

/** Conversations + who I may start a new one with. `base` is '/chat' or '/my/chat'. */
export async function ChatListView({ orgId, base }: { orgId: string; base: string }) {
  const supabase = await createClient();
  const [{ data: threads }, { data: contacts }] = await Promise.all([
    supabase.rpc('chat_threads_list', { p_org: orgId }),
    supabase.rpc('chat_contacts', { p_org: orgId }),
  ]);
  const list = (threads ?? []) as ThreadRow[];
  const people = (contacts ?? []) as Contact[];
  const withThread = new Set(list.map((t) => t.other_id));

  return (
    <div className="max-w-2xl">
      <h1 className="mb-4 text-2xl font-bold">المحادثات</h1>
      <div className="mb-8 flex flex-col gap-2">
        {list.map((t) => (
          <a key={t.thread_id} href={`${base}/${t.other_id}` as never} className="flex items-center justify-between gap-3 rounded-lg border bg-white p-3 hover:bg-gray-50">
            <div className="min-w-0">
              <p className="font-semibold">
                {t.other_name} <span className="text-xs font-normal text-gray-500">{ROLE_LABELS[t.other_role]}</span>
                {t.muted && <span className="mr-1 text-xs text-gray-400">🔕</span>}
              </p>
              <p className="truncate text-sm text-gray-500">
                {t.last_mine ? 'أنت: ' : ''}
                {t.last_body}
              </p>
            </div>
            <div className="shrink-0 text-left text-xs text-gray-400">
              {t.last_message_at && time(t.last_message_at)}
              {t.unread > 0 && <span className="mr-2 rounded-full bg-brand px-2 py-0.5 text-white">{t.unread}</span>}
            </div>
          </a>
        ))}
        {!list.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا توجد محادثات بعد</p>}
      </div>

      <h2 className="mb-2 font-semibold">محادثة جديدة</h2>
      <div className="flex flex-col gap-1">
        {people
          .filter((c) => !withThread.has(c.user_id))
          .map((c) => (
            <a key={c.user_id} href={`${base}/${c.user_id}` as never} className="flex items-center justify-between rounded border bg-white px-3 py-2 text-sm hover:bg-gray-50">
              <span>
                {c.name} <span className="text-xs text-gray-500">{ROLE_LABELS[c.role]}</span>
              </span>
              {c.detail && <span className="text-xs text-gray-400">{c.detail}</span>}
            </a>
          ))}
        {!people.length && <p className="text-sm text-gray-400">لا يوجد من يمكنك مراسلته حاليًا</p>}
      </div>
    </div>
  );
}

/** One conversation. Opening it marks the other side's messages as read. */
export async function ChatThreadView({
  orgId,
  otherId,
  base,
  error,
  editing,
}: {
  orgId: string;
  otherId: string;
  base: string;
  error?: string;
  editing?: string;
}) {
  const supabase = await createClient();
  const path = `${base}/${otherId}`;

  const [{ data: threadId }, { data: contacts }, { data: threads }] = await Promise.all([
    supabase.rpc('chat_thread_with', { p_org: orgId, p_other: otherId }),
    supabase.rpc('chat_contacts', { p_org: orgId }),
    supabase.rpc('chat_threads_list', { p_org: orgId }),
  ]);
  const thread = ((threads ?? []) as ThreadRow[]).find((t) => t.other_id === otherId);
  const contact = ((contacts ?? []) as Contact[]).find((c) => c.user_id === otherId);
  const name = thread?.other_name ?? contact?.name ?? '—';
  const canReply = thread ? thread.can_reply : !!contact;

  let messages: Message[] = [];
  if (threadId) {
    await supabase.rpc('mark_thread_read', { p_thread: threadId });
    const { data } = await supabase.rpc('chat_thread_messages', { p_org: orgId, p_thread: threadId, p_after: null, p_limit: 80 });
    messages = (data ?? []) as Message[];
  }

  // pictures are private: each viewer gets short-lived signed links
  const paths = messages.map((m) => m.image_path).filter((p): p is string => !!p);
  const signed = new Map<string, string>();
  if (paths.length) {
    const { data } = await supabase.storage.from('chat-images').createSignedUrls(paths, 3600);
    for (const r of data ?? []) if (r.path && r.signedUrl) signed.set(r.path, r.signedUrl);
  }

  return (
    <div className="max-w-2xl">
      <ChatAutoRefresh />
      <div className="mb-3 flex items-center justify-between">
        <a href={base as never} className="text-sm text-brand hover:underline">
          ← المحادثات
        </a>
        {threadId && (
          <form action={muteChat}>
            <input type="hidden" name="threadId" value={threadId as string} />
            <input type="hidden" name="muted" value={thread?.muted ? '0' : '1'} />
            <input type="hidden" name="back" value={path} />
            <button className="text-xs text-gray-500 hover:underline">{thread?.muted ? '🔔 تفعيل التنبيهات' : '🔕 كتم'}</button>
          </form>
        )}
      </div>
      <h1 className="mb-3 text-xl font-bold">
        {name} {thread && <span className="text-sm font-normal text-gray-500">{ROLE_LABELS[thread.other_role]}</span>}
      </h1>
      {error && <p className="mb-3 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <div className="mb-4 flex min-h-64 flex-col gap-2 rounded-lg border bg-gray-50 p-3">
        {messages.map((m) => (
          <div key={m.id} className={`flex ${m.mine ? 'justify-start' : 'justify-end'}`}>
            <div className={`max-w-[80%] rounded-lg px-3 py-2 text-sm ${m.mine ? 'bg-brand text-white' : 'bg-white'}`}>
              {editing === m.id && m.mine ? (
                <form action={editChat} className="flex flex-col gap-2">
                  <input type="hidden" name="id" value={m.id} />
                  <input type="hidden" name="back" value={path} />
                  <textarea name="body" defaultValue={m.body} rows={2} className="rounded border px-2 py-1 text-gray-900" />
                  <SubmitButton className="rounded bg-white px-2 py-1 text-xs font-semibold text-brand" pendingText="...">
                    حفظ
                  </SubmitButton>
                </form>
              ) : (
                <>
                  {m.image_path && signed.get(m.image_path) && (
                    <a href={signed.get(m.image_path)} target="_blank" rel="noreferrer">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img src={signed.get(m.image_path)} alt="صورة" className="mb-1 max-h-64 rounded" />
                    </a>
                  )}
                  {m.body && <p className="whitespace-pre-wrap">{m.body}</p>}
                </>
              )}
              <p className={`mt-1 text-[10px] ${m.mine ? 'text-white/70' : 'text-gray-400'}`}>
                {time(m.created_at)}
                {m.edited_at && ' · عُدّلت'}
                {m.mine && m.read_at && ' · ✓✓'}
                {m.mine && m.body && editing !== m.id && Date.now() - new Date(m.created_at).getTime() < 30 * 60 * 1000 && (
                  <a href={`${path}?edit=${m.id}` as never} className="mr-2 underline">
                    تعديل
                  </a>
                )}
              </p>
            </div>
          </div>
        ))}
        {!messages.length && <p className="m-auto text-sm text-gray-400">ابدأ المحادثة</p>}
        <ScrollToEnd count={messages.length} />
      </div>

      {canReply ? (
        <form action={sendChat} className="flex flex-wrap items-end gap-2">
          <input type="hidden" name="orgId" value={orgId} />
          <input type="hidden" name="otherId" value={otherId} />
          <input type="hidden" name="back" value={path} />
          <input type="hidden" name="ref" value={crypto.randomUUID()} />
          <textarea name="body" rows={2} maxLength={2000} placeholder="اكتب رسالتك..." className="min-w-48 flex-1 rounded border px-3 py-2 text-sm" />
          <ChatImagePicker />
          <SubmitButton className="rounded bg-brand px-5 py-2 text-sm font-semibold text-white disabled:opacity-50" pendingText="...">
            إرسال
          </SubmitButton>
        </form>
      ) : (
        <p className="rounded bg-gray-100 px-3 py-2 text-center text-sm text-gray-500">لا يمكنك مراسلة هذا المستخدم حاليًا</p>
      )}
    </div>
  );
}
