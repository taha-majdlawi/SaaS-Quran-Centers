import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';

interface MemberRow {
  user_id: string;
  full_name: string | null;
  email: string | null;
}

interface ThreadRow {
  id: string;
  title: string | null;
  created_at: string;
  chat_thread_participants: { user_id: string }[];
}

export default async function ChatPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const [{ data: myThreadIds }, { data: members }] = await Promise.all([
    supabase.from('chat_thread_participants').select('thread_id').eq('user_id', user!.id),
    supabase.rpc('list_org_members', { org_id: org.id }),
  ]);

  const threadIds = (myThreadIds ?? []).map((t) => t.thread_id);

  const { data: threads } = threadIds.length
    ? await supabase
        .from('chat_threads')
        .select('id, title, created_at, chat_thread_participants(user_id)')
        .in('id', threadIds)
        .order('created_at', { ascending: false })
    : { data: [] as ThreadRow[] };

  const nameByUserId = new Map(
    ((members ?? []) as MemberRow[]).map((m) => [m.user_id, m.full_name ?? m.email ?? '—']),
  );

  const backHref = org.myRole === 'student' || org.myRole === 'guardian' ? '/my' : '/dashboard';

  return (
    <div className="p-6">
      <a href={backHref} className="mb-4 inline-block text-sm text-brand hover:underline">
        ← رجوع
      </a>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">المحادثات</h1>
        <a href="/chat/new" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
          + محادثة جديدة
        </a>
      </div>
      <ul className="flex flex-col gap-2">
        {((threads ?? []) as unknown as ThreadRow[]).map((t) => {
          const otherIds = t.chat_thread_participants.map((p) => p.user_id).filter((id) => id !== user!.id);
          const otherNames = otherIds.map((id) => nameByUserId.get(id) ?? '—').join('، ') || (t.title ?? 'محادثة');
          return (
            <li key={t.id}>
              <a href={`/chat/${t.id}`} className="block rounded-lg border bg-white p-4 text-sm hover:bg-gray-50">
                <span className="font-semibold">{otherNames}</span>
                <span className="mr-2 text-xs text-gray-400">
                  {new Date(t.created_at).toLocaleDateString('ar')}
                </span>
              </a>
            </li>
          );
        })}
        {!threads?.length && (
          <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا يوجد محادثات بعد</p>
        )}
      </ul>
    </div>
  );
}
