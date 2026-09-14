import { notFound } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { sendMessage } from '../actions';

interface MessageRow {
  id: string;
  sender_id: string;
  body: string | null;
  created_at: string;
}

export default async function ChatThreadPage({ params }: { params: Promise<{ org: string; id: string }> }) {
  const { id } = await params;
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: messages } = await supabase
    .from('chat_messages')
    .select('id, sender_id, body, created_at')
    .eq('thread_id', id)
    .order('created_at');

  if (!messages) notFound();

  return (
    <div className="flex max-w-2xl flex-col gap-4">
      <a href="/chat" className="text-sm text-brand hover:underline">
        ← رجوع للمحادثات
      </a>

      <div className="flex flex-col gap-2 rounded-lg border bg-white p-4">
        {(messages as MessageRow[]).map((m) => {
          const mine = m.sender_id === user!.id;
          return (
            <div key={m.id} className={`flex ${mine ? 'justify-start' : 'justify-end'}`}>
              <div
                className={`max-w-xs rounded-lg px-3 py-2 text-sm ${
                  mine ? 'bg-brand text-white' : 'bg-gray-100 text-gray-800'
                }`}
              >
                <p>{m.body}</p>
                <p className={`mt-1 text-xs ${mine ? 'text-white/70' : 'text-gray-400'}`}>
                  {new Date(m.created_at).toLocaleTimeString('ar')}
                </p>
              </div>
            </div>
          );
        })}
        {!messages.length && <p className="text-center text-sm text-gray-400">لا يوجد رسائل بعد</p>}
      </div>

      <form action={sendMessage} className="flex gap-2">
        <input type="hidden" name="threadId" value={id} />
        <input
          name="body"
          required
          placeholder="اكتب رسالة..."
          className="flex-1 rounded border px-3 py-2 text-sm"
        />
        <SubmitButton
          className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="..."
        >
          إرسال
        </SubmitButton>
      </form>
    </div>
  );
}
