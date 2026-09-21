import { getOrgContext } from '@/lib/tenant/get-org-context';
import { NotificationsView } from '@/components/notifications-view';
import { PushPanel } from '@/components/push-panel';

export default async function NotificationsPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ pushSent?: string; pushError?: string }>;
}) {
  const { org: slug } = await params;
  const { pushSent, pushError } = await searchParams;
  const org = await getOrgContext(slug);
  return (
    <>
      {org.myRole === 'admin' && <PushPanel orgId={org.id} sent={pushSent} error={pushError} />}
      <NotificationsView orgId={org.id} portal={false} />
    </>
  );
}
