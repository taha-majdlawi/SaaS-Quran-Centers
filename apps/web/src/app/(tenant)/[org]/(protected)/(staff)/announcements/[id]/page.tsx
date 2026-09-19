import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { AnnouncementForm } from '@/components/announcement-form';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import type { AnnouncementRow } from '@/components/announcements-view';
import { deleteAnnouncement } from '@/lib/comms/actions';

export default async function EditAnnouncementPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug, id } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const isAdmin = org.myRole === 'admin';

  const { data } = await supabase.rpc('list_announcements', { p_org: org.id });
  const item = ((data ?? []) as AnnouncementRow[]).find((a) => a.id === id);
  if (!item || !item.can_edit) notFound();

  let query = supabase.from('circles').select('id, name').eq('organization_id', org.id).order('name');
  if (!isAdmin) {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    query = query.eq('teacher_id', user?.id ?? '');
  }
  const { data: circles } = await query;

  return (
    <div>
      <a href="/announcements" className="text-sm text-brand hover:underline">
        ← الإعلانات
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">تعديل إعلان</h1>
      <AnnouncementForm orgId={org.id} circles={circles ?? []} isAdmin={isAdmin} item={item} error={error} />
      <form action={deleteAnnouncement} className="mt-4">
        <input type="hidden" name="orgId" value={org.id} />
        <input type="hidden" name="id" value={id} />
        <ConfirmSubmitButton confirmMessage="حذف الإعلان؟" pendingText="..." className="rounded border border-red-200 px-4 py-2 text-sm text-red-600">
          حذف
        </ConfirmSubmitButton>
      </form>
    </div>
  );
}
