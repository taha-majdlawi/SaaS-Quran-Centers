import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { CenterReportView, RangeForm } from '@/components/report-views';
import { defaultRange, previousRange, type CenterReport } from '@/lib/reports/format';
import { getI18n } from '@/lib/i18n/server';

export default async function ReportsPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ from?: string; to?: string; compare?: string | string[] }>;
}) {
  const { org: slug } = await params;
  const { from, to, compare } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  if (!org.myPermissions.includes('reports')) notFound();

  const range = defaultRange();
  const f = from || range.from;
  const t = to || range.to;
  const supabase = await createClient();
  // on by default; the form sends compare=0 always and compare=1 when ticked
  const cmp = ([] as string[]).concat(compare ?? []);
  const comparing = cmp.includes('1') || cmp.length === 0;
  const pr = previousRange(f, t);
  const [{ data, error }, { data: prevData }] = await Promise.all([
    supabase.rpc('center_report', { p_org: org.id, p_from: f, p_to: t }),
    comparing ? supabase.rpc('center_report', { p_org: org.id, p_from: pr.from, p_to: pr.to }) : Promise.resolve({ data: null }),
  ]);
  const r = data as CenterReport | null;
  const prev = prevData as CenterReport | null;

  return (
    <div className="max-w-5xl">
      <h1 className="mb-4 text-2xl font-bold">{S.reportsPage.title}</h1>
      <RangeForm
        from={f}
        to={t}
        extra={
          <label className="flex items-center gap-2 self-center text-sm text-gray-700">
            <input type="hidden" name="compare" value="0" />
            <input type="checkbox" name="compare" value="1" defaultChecked={comparing} />
            {S.compare.toggle}
          </label>
        }
      />
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error.message}</p>}
      {r && <CenterReportView r={r} prev={prev} exportHref={`/reports/export?from=${f}&to=${t}`} />}
    </div>
  );
}
