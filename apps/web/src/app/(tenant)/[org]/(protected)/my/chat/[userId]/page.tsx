import { getOrgContext } from '@/lib/tenant/get-org-context';
import { ChatThreadView } from '@/components/chat-views';

export default async function MyChatWithPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; userId: string }>;
  searchParams: Promise<{ error?: string; edit?: string }>;
}) {
  const { org: slug, userId } = await params;
  const { error, edit } = await searchParams;
  const org = await getOrgContext(slug);
  return (
    <div className="mx-auto max-w-2xl p-6">
      <ChatThreadView orgId={org.id} otherId={userId} base="/my/chat" error={error} editing={edit} />
    </div>
  );
}
