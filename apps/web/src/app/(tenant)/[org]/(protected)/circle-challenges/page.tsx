import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';

export default async function CircleChallengesPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data: challenges } = await supabase
    .from('circle_challenges')
    .select('id, title, metric, starts_on, ends_on')
    .eq('organization_id', org.id)
    .order('starts_on', { ascending: false });

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">منافسات الحلقات</h1>
        <a href="/circle-challenges/new" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
          + منافسة جديدة
        </a>
      </div>

      <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
        <thead className="bg-gray-50 text-right">
          <tr>
            <th className="px-4 py-2">العنوان</th>
            <th className="px-4 py-2">المعيار</th>
            <th className="px-4 py-2">الفترة</th>
            <th className="px-4 py-2"></th>
          </tr>
        </thead>
        <tbody>
          {(challenges ?? []).map((c) => (
            <tr key={c.id} className="border-t">
              <td className="px-4 py-2">{c.title}</td>
              <td className="px-4 py-2">{c.metric}</td>
              <td className="px-4 py-2">
                {c.starts_on} — {c.ends_on}
              </td>
              <td className="px-4 py-2 text-left">
                <a href={`/circle-challenges/${c.id}`} className="text-brand hover:underline">
                  النتائج
                </a>
              </td>
            </tr>
          ))}
          {!challenges?.length && (
            <tr>
              <td colSpan={4} className="px-4 py-6 text-center text-gray-400">
                لا يوجد منافسات بعد
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
