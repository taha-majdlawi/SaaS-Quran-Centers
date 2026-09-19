import { getOrgContext } from '@/lib/tenant/get-org-context';
import { AnnouncementsList } from '@/components/announcements-view';

export default async function AnnouncementsPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ ok?: string }>;
}) {
  const { org: slug } = await params;
  const { ok } = await searchParams;
  const org = await getOrgContext(slug);
  return <AnnouncementsList orgId={org.id} manage ok={ok} />;
}
