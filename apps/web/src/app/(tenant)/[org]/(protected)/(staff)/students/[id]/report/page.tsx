import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { RangeForm, StudentReportView } from '@/components/report-views';
import { defaultRange, type StudentReport } from '@/lib/reports/format';
import { getI18n } from '@/lib/i18n/server';

export default async function StudentReportPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ from?: string; to?: string }>;
}) {
  const { org: slug, id } = await params;
  const { from, to } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const range = defaultRange();
  const f = from || range.from;
  const t = to || range.to;

  const supabase = await createClient();
  const { data, error } = await supabase.rpc('student_report', { p_org: org.id, p_student: id, p_from: f, p_to: t });
  const r = data as StudentReport | null;

  return (
    <div className="max-w-4xl">
      <a href="/students" className="text-sm text-brand hover:underline print:hidden">
        {S.students.backStudents}
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">{S.students.reportTitle}</h1>
      <RangeForm from={f} to={t} />
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error.message}</p>}
      {r && <StudentReportView r={r} certificatesBase="/certificates" />}
    </div>
  );
}
