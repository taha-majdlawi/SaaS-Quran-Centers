import { getOrgContext } from '@/lib/tenant/get-org-context';
import { ChatListView } from '@/components/chat-views';

export default async function MyChatPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  return (
    <div className="mx-auto max-w-2xl p-6">
      <a href="/my" className="text-sm text-brand hover:underline">
        ← ملفي
      </a>
      <div className="mt-2">
        <ChatListView orgId={org.id} base="/my/chat" />
      </div>
    </div>
  );
}
