import { getOrgContext } from '@/lib/tenant/get-org-context';
import { NotificationsView } from '@/components/notifications-view';

export default async function MyNotificationsPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  return (
    <div className="mx-auto max-w-2xl p-6">
      <a href="/my" className="text-sm text-brand hover:underline">
        ← ملفي
      </a>
      <div className="mt-2">
        <NotificationsView orgId={org.id} portal />
      </div>
    </div>
  );
}
