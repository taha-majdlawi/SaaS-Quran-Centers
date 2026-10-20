import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { getI18n } from '@/lib/i18n/server';
import { PointsBreakdownCard, type PointsBreakdown } from '@/components/points-breakdown';

// "How did I earn my points" for the student / guardian (0096): every source of the total.
export default async function MyPointsPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ s?: string }>;
}) {
  const { org: slug } = await params;
  const { s } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const { t } = await getI18n();

  const { data: students } = await supabase.from('students_profile').select('id, full_name').eq('organization_id', org.id).order('full_name');
  const list = (students ?? []) as { id: string; full_name: string }[];
  const current = list.find((x) => x.id === s) ?? list[0];
  const { data, error } = current
    ? await supabase.rpc('get_student_points_breakdown', { p_org: org.id, p_student: current.id })
    : { data: null, error: null };

  return (
    <div className="mx-auto max-w-3xl p-6">
      <a href="/my" className="text-sm text-brand hover:underline">
        {t.portal.backToProfile}
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">{t.staff.points.bdMine}</h1>
      {list.length > 1 && (
        <div className="mb-4 flex flex-wrap gap-2 text-sm">
          {list.map((x) => (
            <a key={x.id} href={`/my/points?s=${x.id}` as never} className={`rounded-full border px-3 py-1 ${x.id === current?.id ? 'bg-brand text-white' : 'bg-white'}`}>
              {x.full_name}
            </a>
          ))}
        </div>
      )}
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error.message}</p>}
      {data ? (
        <PointsBreakdownCard data={data as PointsBreakdown} T={t} lang={t.labels.dateLocale} mine />
      ) : (
        !error && <p className="text-sm text-gray-400">{t.staff.points.noPoints}</p>
      )}
    </div>
  );
}
