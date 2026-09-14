import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';

export default async function CalendarPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data: events } = await supabase
    .from('center_calendar')
    .select('id, title, starts_at, location, requires_guardian_consent')
    .eq('organization_id', org.id)
    .order('starts_at');

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">التقويم</h1>
        <a href="/calendar/new" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
          + فعالية جديدة
        </a>
      </div>

      <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
        <thead className="bg-gray-50 text-right">
          <tr>
            <th className="px-4 py-2">العنوان</th>
            <th className="px-4 py-2">التاريخ</th>
            <th className="px-4 py-2">المكان</th>
            <th className="px-4 py-2">موافقة ولي أمر</th>
            <th className="px-4 py-2"></th>
          </tr>
        </thead>
        <tbody>
          {(events ?? []).map((e) => (
            <tr key={e.id} className="border-t">
              <td className="px-4 py-2">{e.title}</td>
              <td className="px-4 py-2">{new Date(e.starts_at).toLocaleString('ar')}</td>
              <td className="px-4 py-2">{e.location ?? '—'}</td>
              <td className="px-4 py-2">{e.requires_guardian_consent ? 'مطلوبة' : '—'}</td>
              <td className="px-4 py-2 text-left">
                <a href={`/calendar/${e.id}`} className="text-brand hover:underline">
                  تفاصيل
                </a>
              </td>
            </tr>
          ))}
          {!events?.length && (
            <tr>
              <td colSpan={5} className="px-4 py-6 text-center text-gray-400">
                لا يوجد فعاليات بعد
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
