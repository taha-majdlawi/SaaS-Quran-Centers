import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { CenterReportView, RangeForm } from '@/components/report-views';
import { defaultRange, type CenterReport } from '@/lib/reports/format';
import { getI18n } from '@/lib/i18n/server';

export default async function ReportsPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ from?: string; to?: string }>;
}) {
  const { org: slug } = await params;
  const { from, to } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  if (!org.myPermissions.includes('reports')) notFound();

  const range = defaultRange();
  const f = from || range.from;
  const t = to || range.to;
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('center_report', { p_org: org.id, p_from: f, p_to: t });
  const r = data as CenterReport | null;

  return (
    <div className="max-w-5xl">
      <h1 className="mb-4 text-2xl font-bold">{S.reportsPage.title}</h1>
      <RangeForm from={f} to={t} />
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error.message}</p>}
      {r && <CenterReportView r={r} exportHref={`/reports/export?from=${f}&to=${t}`} />}
    </div>
  );
}
