import { getOrgContext } from '@/lib/tenant/get-org-context';
import { ChatThreadView } from '@/components/chat-views';

export default async function ChatWithPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; userId: string }>;
  searchParams: Promise<{ error?: string; edit?: string }>;
}) {
  const { org: slug, userId } = await params;
  const { error, edit } = await searchParams;
  const org = await getOrgContext(slug);
  return <ChatThreadView orgId={org.id} otherId={userId} base="/chat" error={error} editing={edit} />;
}
