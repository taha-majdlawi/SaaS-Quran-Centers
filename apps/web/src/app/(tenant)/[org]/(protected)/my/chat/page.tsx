import { getOrgContext } from '@/lib/tenant/get-org-context';
import { ChatListView } from '@/components/chat-views';
import { getI18n } from '@/lib/i18n/server';

export default async function MyChatPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const { t } = await getI18n();
  return (
    <div className="mx-auto max-w-2xl p-6">
      <a href="/my" className="text-sm text-brand hover:underline">
        {t.portal.backToProfile}
      </a>
      <div className="mt-2">
        <ChatListView orgId={org.id} base="/my/chat" />
      </div>
    </div>
  );
}
