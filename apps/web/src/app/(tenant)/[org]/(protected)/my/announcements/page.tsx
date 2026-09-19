import { getOrgContext } from '@/lib/tenant/get-org-context';
import { AnnouncementsList } from '@/components/announcements-view';

export default async function MyAnnouncementsPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  return (
    <div className="mx-auto max-w-2xl p-6">
      <a href="/my" className="text-sm text-brand hover:underline">
        ← ملفي
      </a>
      <div className="mt-2">
        <AnnouncementsList orgId={org.id} manage={false} />
      </div>
    </div>
  );
}
