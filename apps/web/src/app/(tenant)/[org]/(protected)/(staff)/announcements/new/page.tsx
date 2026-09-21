import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { AnnouncementForm } from '@/components/announcement-form';

export default async function NewAnnouncementPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const isAdmin = org.myRole === 'admin';

  // A teacher may only address the families of a circle they teach.
  let query = supabase.from('circles').select('id, name').eq('organization_id', org.id).order('name');
  if (!isAdmin) {
    // the circles this person teaches, as primary or assistant
    const { data: mine } = await supabase.rpc('my_circle_ids', { p_org: org.id });
    query = query.in('id', ((mine ?? []) as { id: string }[]).map((c) => c.id));
  }
  const { data: circles } = await query;

  return (
    <div>
      <a href="/announcements" className="text-sm text-brand hover:underline">
        ← الإعلانات
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">إعلان جديد</h1>
      <AnnouncementForm orgId={org.id} circles={circles ?? []} isAdmin={isAdmin} error={error} />
    </div>
  );
}
