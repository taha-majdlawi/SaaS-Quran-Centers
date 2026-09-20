import { getOrgContext } from '@/lib/tenant/get-org-context';
import { ChatThreadView } from '@/components/chat-views';

export default async function ChatWithPage({
  params,
}: {
  params: Promise<{ org: string; userId: string }>;
}) {
  const { org: slug, userId } = await params;
  const org = await getOrgContext(slug);
  return <ChatThreadView orgId={org.id} otherId={userId} base="/chat" />;
}
