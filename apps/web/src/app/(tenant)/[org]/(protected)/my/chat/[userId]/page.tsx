import { getOrgContext } from '@/lib/tenant/get-org-context';
import { ChatThreadView } from '@/components/chat-views';

export default async function MyChatWithPage({
  params,
}: {
  params: Promise<{ org: string; userId: string }>;
}) {
  const { org: slug, userId } = await params;
  const org = await getOrgContext(slug);
  return (
    <div className="mx-auto max-w-2xl p-6">
      <ChatThreadView orgId={org.id} otherId={userId} base="/my/chat" />
    </div>
  );
}
