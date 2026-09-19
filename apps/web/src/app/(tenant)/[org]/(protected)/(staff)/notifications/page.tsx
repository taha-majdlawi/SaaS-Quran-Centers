import { getOrgContext } from '@/lib/tenant/get-org-context';
import { NotificationsView } from '@/components/notifications-view';

export default async function NotificationsPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  return <NotificationsView orgId={org.id} portal={false} />;
}
