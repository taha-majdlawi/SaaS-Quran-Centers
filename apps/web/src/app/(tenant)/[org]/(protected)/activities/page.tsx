import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';

export default async function ActivitiesPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data: activities } = await supabase
    .from('activities')
    .select('id, title, description, scheduled_at')
    .eq('organization_id', org.id)
    .order('scheduled_at', { ascending: false, nullsFirst: false });

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">الأنشطة</h1>
        <a href="/activities/new" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
          + نشاط جديد
        </a>
      </div>

      <div className="flex flex-col gap-3">
        {(activities ?? []).map((a) => (
          <div key={a.id} className="rounded-lg border bg-white p-4">
            <div className="mb-1 flex items-center justify-between">
              <h2 className="font-semibold">{a.title}</h2>
              <a href={`/activities/${a.id}`} className="text-sm text-brand hover:underline">
                تعديل
              </a>
            </div>
            {a.description && <p className="mb-2 whitespace-pre-wrap text-sm text-gray-600">{a.description}</p>}
            <p className="text-xs text-gray-400">
              {a.scheduled_at ? new Date(a.scheduled_at).toLocaleString('ar') : 'بدون موعد محدد'}
            </p>
          </div>
        ))}
        {!activities?.length && (
          <p className="rounded-lg border bg-white p-6 text-center text-gray-400">لا يوجد أنشطة بعد</p>
        )}
      </div>
    </div>
  );
}
