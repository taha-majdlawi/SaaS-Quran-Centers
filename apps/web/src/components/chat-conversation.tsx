'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { ChatImagePicker } from '@/components/chat-image-picker';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';

/** The composer's strings plus the date locale (t.chat.ui + t.labels.dateLocale). */
export type ChatLabels = Dictionary['chat']['ui'] & { lang: string };

export interface ChatMsg {
  id: string;
  mine: boolean;
  body: string;
  image_path: string | null;
  created_at: string;
  edited_at: string | null;
  read_at: string | null;
  deleted_at: string | null;
  /** short-lived link to the picture (private bucket) */
  url?: string | null;
}

const time = (iso: string, lang: string) =>
  new Date(iso).toLocaleString(lang, { hour: '2-digit', minute: '2-digit', day: 'numeric', month: 'short' });

const IMAGE_TYPES: Record<string, string> = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };

/**
 * The conversation, live, WITHOUT reloading the page: new messages arrive over
 * Supabase Realtime (RLS still decides what this browser may receive), sending
 * and editing are direct calls from the browser (same anon-key + RLS trust
 * model as everywhere else), and a slow fallback poll only asks for messages
 * newer than the last one seen. Nothing here re-renders the server page.
 */
export function ChatConversation({
  orgId,
  otherId,
  userId,
  initialThreadId,
  initialMessages,
  canReply,
  labels: L,
}: {
  orgId: string;
  otherId: string;
  userId: string;
  initialThreadId: string | null;
  initialMessages: ChatMsg[];
  canReply: boolean;
  labels: ChatLabels;
}) {
  const supabase = useMemo(() => createClient(), []);
  const [messages, setMessages] = useState<ChatMsg[]>(initialMessages);
  const [threadId, setThreadId] = useState<string | null>(initialThreadId);
  const [text, setText] = useState('');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState('');
  const [editing, setEditing] = useState<string | null>(null);
  const [editText, setEditText] = useState('');
  const [pickerKey, setPickerKey] = useState(0);
  const formRef = useRef<HTMLFormElement>(null);
  const endRef = useRef<HTMLDivElement>(null);
  const refToSend = useRef<string>(crypto.randomUUID());
  const urls = useRef<Map<string, string>>(new Map(initialMessages.filter((m) => m.image_path && m.url).map((m) => [m.image_path!, m.url!])));
  const stick = useRef(true); // follow new messages only while the reader is at the bottom

  const sign = useCallback(
    async (rows: ChatMsg[]) => {
      const missing = rows.map((m) => m.image_path).filter((p): p is string => !!p && !urls.current.has(p));
      if (missing.length) {
        const { data } = await supabase.storage.from('chat-images').createSignedUrls(missing, 3600);
        for (const r of data ?? []) if (r.path && r.signedUrl) urls.current.set(r.path, r.signedUrl);
      }
      return rows.map((m) => ({ ...m, url: m.image_path ? urls.current.get(m.image_path) ?? null : null }));
    },
    [supabase],
  );

  const merge = useCallback(
    async (rows: ChatMsg[]) => {
      if (!rows.length) return;
      const signed = await sign(rows);
      setMessages((prev) => {
        const byId = new Map(prev.map((m) => [m.id, m]));
        for (const m of signed) byId.set(m.id, { ...byId.get(m.id), ...m });
        return [...byId.values()].sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
      });
      if (threadId && signed.some((m) => !m.mine)) void supabase.rpc('mark_thread_read', { p_thread: threadId });
    },
    [sign, supabase, threadId],
  );

  /** Only what is newer than the last message we hold. */
  const fetchNew = useCallback(async () => {
    if (!threadId) return;
    const last = messages.length ? messages[messages.length - 1].created_at : null;
    const { data } = await supabase.rpc('chat_thread_messages', { p_org: orgId, p_thread: threadId, p_after: last, p_limit: 50 });
    await merge((data ?? []) as ChatMsg[]);
  }, [messages, merge, orgId, supabase, threadId]);
  const fetchNewRef = useRef(fetchNew);
  fetchNewRef.current = fetchNew;

  // live: new / edited / read messages of this thread
  useEffect(() => {
    if (!threadId) return;
    const channel = supabase
      .channel(`web-chat-${threadId}`)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'chat_messages', filter: `thread_id=eq.${threadId}` }, (payload) => {
        const row = payload.new as { id?: string; sender_id?: string; body?: string; image_path?: string | null; created_at?: string; edited_at?: string | null; read_at?: string | null; deleted_at?: string | null };
        if (!row?.id || !row.created_at) return;
        void merge([
          {
            id: row.id,
            mine: row.sender_id === userId,
            body: row.body ?? '',
            image_path: row.image_path ?? null,
            created_at: row.created_at,
            edited_at: row.edited_at ?? null,
            read_at: row.read_at ?? null,
            deleted_at: row.deleted_at ?? null,
          },
        ]);
      })
      .subscribe();
    // slow safety net for a dropped socket (asks only for newer messages; skipped while the tab is hidden)
    const poll = setInterval(() => {
      if (document.visibilityState === 'visible') void fetchNewRef.current();
    }, 30000);
    return () => {
      clearInterval(poll);
      void supabase.removeChannel(channel);
    };
  }, [threadId, supabase, merge, userId]);

  // keep the newest message in view (unless the reader scrolled up)
  useEffect(() => {
    if (stick.current) endRef.current?.scrollIntoView({ block: 'end' });
  }, [messages.length]);

  const send = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (sending) return;
    const form = new FormData(e.currentTarget);
    const file = form.get('image');
    const body = text.trim();
    const hasFile = file instanceof File && file.size > 0;
    if (!body && !hasFile) return;
    setSending(true);
    setError('');
    try {
      let imagePath: string | null = null;
      if (hasFile) {
        const ext = IMAGE_TYPES[file.type];
        if (!ext) throw new Error(L.imageTypes);
        if (file.size > 5 * 1024 * 1024) throw new Error(L.imageSize);
        imagePath = `${orgId}/${userId}/${crypto.randomUUID()}.${ext}`;
        const { error: upError } = await supabase.storage.from('chat-images').upload(imagePath, file, { contentType: file.type });
        if (upError) throw new Error(L.uploadFailed);
      }
      const { data, error: rpcError } = await supabase.rpc('send_chat_message', {
        p_org: orgId,
        p_other: otherId,
        p_body: body,
        p_client_ref: refToSend.current,
        p_image_path: imagePath,
      });
      if (rpcError) throw new Error(rpcError.message);
      refToSend.current = crypto.randomUUID();
      setText('');
      setPickerKey((k) => k + 1); // clears the picture preview
      stick.current = true;
      const newThread = (data as { thread_id?: string } | null)?.thread_id ?? null;
      if (!threadId && newThread) setThreadId(newThread);
      // fetch just my new message (the thread may be brand new: ask by id)
      const tid = threadId ?? newThread;
      if (tid) {
        const last = messages.length ? messages[messages.length - 1].created_at : null;
        const { data: fresh } = await supabase.rpc('chat_thread_messages', { p_org: orgId, p_thread: tid, p_after: last, p_limit: 50 });
        await merge((fresh ?? []) as ChatMsg[]);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : L.sendFailed);
    } finally {
      setSending(false);
    }
  };

  const saveEdit = async (id: string) => {
    const body = editText.trim();
    if (!body) return;
    const { error: rpcError } = await supabase.rpc('edit_chat_message', { p_message: id, p_body: body });
    if (rpcError) {
      setError(rpcError.message);
      return;
    }
    setMessages((prev) => prev.map((m) => (m.id === id ? { ...m, body, edited_at: new Date().toISOString() } : m)));
    setEditing(null);
  };

  const deleteMessage = async (id: string) => {
    if (!confirm(L.deleteConfirm)) return;
    const { data, error: rpcError } = await supabase.rpc('delete_chat_message', { p_message: id });
    if (rpcError) {
      setError(rpcError.message);
      return;
    }
    const imagePath = (data as { image_path?: string } | null)?.image_path;
    if (imagePath) void supabase.storage.from('chat-images').remove([imagePath]);
    setMessages((prev) => prev.map((m) => (m.id === id ? { ...m, body: '', image_path: null, url: null, deleted_at: new Date().toISOString() } : m)));
  };

  return (
    <>
      <div
        className="mb-4 flex max-h-[60vh] min-h-64 flex-col gap-2 overflow-y-auto rounded-lg border bg-gray-50 p-3"
        onScroll={(e) => {
          const el = e.currentTarget;
          stick.current = el.scrollHeight - el.scrollTop - el.clientHeight < 80;
        }}
      >
        {messages.map((m) => (
          <div key={m.id} className={`flex ${m.mine ? 'justify-start' : 'justify-end'}`}>
            <div className={`max-w-[80%] rounded-lg px-3 py-2 text-sm ${m.mine ? 'bg-brand text-white' : 'bg-white'}`}>
              {editing === m.id ? (
                <div className="flex flex-col gap-2">
                  <textarea value={editText} onChange={(e) => setEditText(e.target.value)} rows={2} className="rounded border px-2 py-1 text-gray-900" />
                  <div className="flex gap-2">
                    <button type="button" onClick={() => saveEdit(m.id)} className="rounded bg-white px-2 py-1 text-xs font-semibold text-brand">
                      {L.save}
                    </button>
                    <button type="button" onClick={() => setEditing(null)} className="rounded px-2 py-1 text-xs underline">
                      {L.cancel}
                    </button>
                  </div>
                </div>
              ) : m.deleted_at ? (
                <p className={`flex items-center gap-1 text-sm italic ${m.mine ? 'text-white/70' : 'text-gray-400'}`}>{L.deleted}</p>
              ) : (
                <>
                  {m.image_path && m.url && (
                    <a href={m.url} target="_blank" rel="noreferrer">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img src={m.url} alt={L.image} className="mb-1 max-h-64 rounded" onLoad={() => stick.current && endRef.current?.scrollIntoView({ block: 'end' })} />
                    </a>
                  )}
                  {m.body && <p className="whitespace-pre-wrap">{m.body}</p>}
                </>
              )}
              <p className={`mt-1 text-[10px] ${m.mine ? 'text-white/70' : 'text-gray-400'}`}>
                {time(m.created_at, L.lang)}
                {!m.deleted_at && m.edited_at && L.edited}
                {!m.deleted_at && m.mine && m.read_at && ' · ✓✓'}
                {!m.deleted_at && m.mine && m.body && editing !== m.id && Date.now() - new Date(m.created_at).getTime() < 30 * 60 * 1000 && (
                  <button
                    type="button"
                    onClick={() => {
                      setEditing(m.id);
                      setEditText(m.body);
                    }}
                    className="ms-2 underline"
                  >
                    {L.edit}
                  </button>
                )}
                {!m.deleted_at && m.mine && editing !== m.id && (
                  <button type="button" onClick={() => deleteMessage(m.id)} className="ms-2 underline">
                    {L.delete}
                  </button>
                )}
              </p>
            </div>
          </div>
        ))}
        {!messages.length && <p className="m-auto text-sm text-gray-400">{L.start}</p>}
        <div ref={endRef} />
      </div>

      {error && <p className="mb-3 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      {canReply ? (
        <form ref={formRef} onSubmit={send} className="flex flex-wrap items-end gap-2">
          <textarea
            value={text}
            onChange={(e) => {
              setText(e.target.value);
              refToSend.current = crypto.randomUUID();
            }}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && !e.shiftKey && !e.nativeEvent.isComposing) {
                e.preventDefault();
                formRef.current?.requestSubmit();
              }
            }}
            rows={2}
            maxLength={2000}
            placeholder={L.placeholder}
            className="min-w-48 flex-1 rounded border px-3 py-2 text-sm"
          />
          <ChatImagePicker key={pickerKey} labels={L} />
          <button type="submit" disabled={sending} className="rounded bg-brand px-5 py-2 text-sm font-semibold text-white disabled:opacity-50">
            {sending ? '...' : L.send}
          </button>
        </form>
      ) : (
        <p className="rounded bg-gray-100 px-3 py-2 text-center text-sm text-gray-500">{L.cantReply}</p>
      )}
    </>
  );
}
