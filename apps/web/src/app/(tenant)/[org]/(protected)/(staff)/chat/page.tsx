import { getOrgContext } from '@/lib/tenant/get-org-context';
import { ChatListView } from '@/components/chat-views';

export default async function ChatPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  return <ChatListView orgId={org.id} base="/chat" />;
}
