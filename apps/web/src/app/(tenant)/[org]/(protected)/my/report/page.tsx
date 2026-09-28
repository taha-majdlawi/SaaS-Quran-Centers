import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { RangeForm, StudentReportView } from '@/components/report-views';
import { defaultRange, type StudentReport } from '@/lib/reports/format';
import { getI18n } from '@/lib/i18n/server';

export default async function MyReportPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ student?: string; from?: string; to?: string }>;
}) {
  const { org: slug } = await params;
  const { student, from, to } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const { t: tr } = await getI18n();

  // RLS shows a student only their own row and a guardian only their children
  const { data: students } = await supabase
    .from('students_profile')
    .select('id, full_name')
    .eq('organization_id', org.id)
    .order('full_name');
  const list = students ?? [];
  const chosen = list.find((s) => s.id === student)?.id ?? list[0]?.id;

  const range = defaultRange();
  const f = from || range.from;
  const t = to || range.to;
  const { data, error } = chosen
    ? await supabase.rpc('student_report', { p_org: org.id, p_student: chosen, p_from: f, p_to: t })
    : { data: null, error: null };
  const r = data as StudentReport | null;

  return (
    <div className="mx-auto max-w-3xl p-6">
      <a href="/my" className="text-sm text-brand hover:underline print:hidden">
        {tr.portal.backHome}
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">{tr.report.title}</h1>
      <RangeForm
        from={f}
        to={t}
        extra={
          list.length > 1 ? (
            <label className="text-sm text-gray-700">
              {tr.report.student}
              <select name="student" defaultValue={chosen} className="mt-1 block rounded border px-3 py-2 text-sm">
                {list.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.full_name}
                  </option>
                ))}
              </select>
            </label>
          ) : null
        }
      />
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error.message}</p>}
      {r ? <StudentReportView r={r} certificatesBase="/my/certificates" /> : !error && <p className="text-gray-500">{tr.portal.noStudent}</p>}
    </div>
  );
}
