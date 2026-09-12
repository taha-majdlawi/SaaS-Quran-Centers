import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';

const AUDIENCE_LABELS: Record<string, string> = {
  all: 'الكل',
  teachers: 'المعلمون',
  students: 'الطلاب',
  guardians: 'أولياء الأمور',
};

export default async function AnnouncementsPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data: announcements } = await supabase
    .from('announcements')
    .select('id, title, body, audience, published_at')
    .eq('organization_id', org.id)
    .order('published_at', { ascending: false });

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">الإعلانات</h1>
        <a href="/announcements/new" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
          + إعلان جديد
        </a>
      </div>

      <div className="flex flex-col gap-3">
        {(announcements ?? []).map((a) => (
          <div key={a.id} className="rounded-lg border bg-white p-4">
            <div className="mb-1 flex items-center justify-between">
              <h2 className="font-semibold">{a.title}</h2>
              <a href={`/announcements/${a.id}`} className="text-sm text-brand hover:underline">
                تعديل
              </a>
            </div>
            <p className="mb-2 whitespace-pre-wrap text-sm text-gray-600">{a.body}</p>
            <p className="text-xs text-gray-400">
              {AUDIENCE_LABELS[a.audience] ?? a.audience} —{' '}
              {a.published_at ? new Date(a.published_at).toLocaleDateString('ar') : '—'}
            </p>
          </div>
        ))}
        {!announcements?.length && (
          <p className="rounded-lg border bg-white p-6 text-center text-gray-400">لا يوجد إعلانات بعد</p>
        )}
      </div>
    </div>
  );
}
