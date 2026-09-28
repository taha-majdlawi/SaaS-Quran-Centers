import { createClient } from '@/lib/supabase/server';
import { ChatConversation, type ChatMsg } from '@/components/chat-conversation';
import { muteChat } from '@/lib/comms/actions';
import { getI18n } from '@/lib/i18n/server';
import { ar } from '@/lib/i18n/dictionaries/ar';

export const ROLE_LABELS: Record<string, string> = ar.shell.roles;

interface ThreadRow {
  thread_id: string;
  other_id: string;
  other_name: string;
  other_role: string;
  last_message_at: string | null;
  last_body: string | null;
  last_deleted: boolean;
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

const time = (iso: string, lang: string) =>
  new Date(iso).toLocaleString(lang, { hour: '2-digit', minute: '2-digit', day: 'numeric', month: 'short' });

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
  const { t: dict } = await getI18n();
  const C = dict.chat;
  const roles = dict.shell.roles;

  return (
    <div className="max-w-2xl">
      <h1 className="mb-4 text-2xl font-bold">{C.title}</h1>
      <div className="mb-8 flex flex-col gap-2">
        {list.map((t) => (
          <a key={t.thread_id} href={`${base}/${t.other_id}` as never} className="flex items-center justify-between gap-3 rounded-lg border bg-white p-3 hover:bg-gray-50">
            <div className="min-w-0">
              <p className="font-semibold">
                {t.other_name} <span className="text-xs font-normal text-gray-500">{roles[t.other_role]}</span>
                {t.muted && <span className="ms-1 text-xs text-gray-400">🔕</span>}
              </p>
              <p className={`truncate text-sm ${t.last_deleted ? 'italic text-gray-400' : 'text-gray-500'}`}>
                {t.last_deleted ? C.deletedLast : `${t.last_mine ? C.you : ''}${t.last_body ?? ''}`}
              </p>
            </div>
            <div className="shrink-0 text-end text-xs text-gray-400">
              {t.last_message_at && time(t.last_message_at, dict.labels.dateLocale)}
              {t.unread > 0 && <span className="ms-2 rounded-full bg-brand px-2 py-0.5 text-white">{t.unread}</span>}
            </div>
          </a>
        ))}
        {!list.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">{C.none}</p>}
      </div>

      <h2 className="mb-2 font-semibold">{C.newChat}</h2>
      <div className="flex flex-col gap-1">
        {people
          .filter((c) => !withThread.has(c.user_id))
          .map((c) => (
            <a key={c.user_id} href={`${base}/${c.user_id}` as never} className="flex items-center justify-between rounded border bg-white px-3 py-2 text-sm hover:bg-gray-50">
              <span>
                {c.name} <span className="text-xs text-gray-500">{roles[c.role]}</span>
              </span>
              {c.detail && <span className="text-xs text-gray-400">{c.detail}</span>}
            </a>
          ))}
        {!people.length && <p className="text-sm text-gray-400">{C.noContacts}</p>}
      </div>
    </div>
  );
}

/** One conversation. Opening it marks the other side's messages as read; the live part is a client component. */
export async function ChatThreadView({ orgId, otherId, base }: { orgId: string; otherId: string; base: string }) {
  const supabase = await createClient();

  const [{ data: threadId }, { data: contacts }, { data: threads }, {
    data: { user },
  }] = await Promise.all([
    supabase.rpc('chat_thread_with', { p_org: orgId, p_other: otherId }),
    supabase.rpc('chat_contacts', { p_org: orgId }),
    supabase.rpc('chat_threads_list', { p_org: orgId }),
    supabase.auth.getUser(),
  ]);
  const thread = ((threads ?? []) as ThreadRow[]).find((t) => t.other_id === otherId);
  const contact = ((contacts ?? []) as Contact[]).find((c) => c.user_id === otherId);
  const name = thread?.other_name ?? contact?.name ?? '—';
  const canReply = thread ? thread.can_reply : !!contact;
  const { t: dict } = await getI18n();

  let messages: ChatMsg[] = [];
  if (threadId) {
    await supabase.rpc('mark_thread_read', { p_thread: threadId });
    const { data } = await supabase.rpc('chat_thread_messages', { p_org: orgId, p_thread: threadId, p_after: null, p_limit: 80 });
    messages = (data ?? []) as ChatMsg[];
  }

  // pictures are private: each viewer gets short-lived signed links
  const paths = messages.map((m) => m.image_path).filter((p): p is string => !!p);
  if (paths.length) {
    const { data } = await supabase.storage.from('chat-images').createSignedUrls(paths, 3600);
    const signed = new Map<string, string>();
    for (const r of data ?? []) if (r.path && r.signedUrl) signed.set(r.path, r.signedUrl);
    messages = messages.map((m) => ({ ...m, url: m.image_path ? signed.get(m.image_path) ?? null : null }));
  }

  return (
    <div className="max-w-2xl">
      <div className="mb-3 flex items-center justify-between">
        <a href={base as never} className="text-sm text-brand hover:underline">
          {dict.chat.back}
        </a>
        {threadId && (
          <form action={muteChat}>
            <input type="hidden" name="threadId" value={threadId as string} />
            <input type="hidden" name="muted" value={thread?.muted ? '0' : '1'} />
            <input type="hidden" name="back" value={`${base}/${otherId}`} />
            <button className="text-xs text-gray-500 hover:underline">{thread?.muted ? dict.chat.unmute : dict.chat.mute}</button>
          </form>
        )}
      </div>
      <h1 className="mb-3 text-xl font-bold">
        {name} {thread && <span className="text-sm font-normal text-gray-500">{dict.shell.roles[thread.other_role]}</span>}
      </h1>

      <ChatConversation
        orgId={orgId}
        otherId={otherId}
        userId={user?.id ?? ''}
        initialThreadId={(threadId as string | null) ?? null}
        initialMessages={messages}
        canReply={canReply}
        labels={{ ...dict.chat.ui, lang: dict.labels.dateLocale }}
      />
    </div>
  );
}
