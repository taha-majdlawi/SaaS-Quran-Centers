import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { PrintButton } from '@/components/print-button';
import { WeeklyReportView, shiftDay, type WeeklyReport } from '@/components/weekly-report-view';
import { getI18n } from '@/lib/i18n/server';

// The family's weekly report (0077): opened from the weekly notification.
export default async function MyWeeklyPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ student?: string; end?: string }>;
}) {
  const { org: slug } = await params;
  const { student, end } = await searchParams;
  const org = await getOrgContext(slug);
  const { t } = await getI18n();
  const supabase = await createClient();
  // RLS shows a student only their own row and a guardian only their children
  const { data: students } = await supabase.from('students_profile').select('id, full_name').eq('organization_id', org.id).order('full_name');
  const list = students ?? [];
  const chosen = list.find((s) => s.id === student)?.id ?? list[0]?.id;
  const { data, error } = chosen
    ? await supabase.rpc('student_weekly_report', { p_org: org.id, p_student: chosen, p_week_end: end || null })
    : { data: null, error: null };
  const r = data as WeeklyReport | null;
  const today = new Date().toISOString().slice(0, 10);

  return (
    <div className="mx-auto max-w-3xl p-6">
      <div className="mb-4 flex items-center justify-between gap-2 print:hidden">
        <a href="/my" className="text-sm text-brand hover:underline">{t.portal.backHome}</a>
        <PrintButton label={t.report.print} />
      </div>
      <h1 className="mb-3 text-2xl font-bold">{t.staff.weekly.title}</h1>
      {list.length > 1 && (
        <div className="mb-4 flex flex-wrap gap-2 print:hidden">
          {list.map((s) => (
            <a key={s.id} href={`/my/weekly?student=${s.id}` as never} className={`rounded-full px-3 py-1 text-sm ${s.id === chosen ? 'bg-brand text-white' : 'border bg-white'}`}>
              {s.full_name}
            </a>
          ))}
        </div>
      )}
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error.message}</p>}
      {r && (
        <WeeklyReportView
          r={r}
          orgId={org.id}
          nav={{
            prev: `/my/weekly?student=${chosen}&end=${shiftDay(r.to, -7)}`,
            next: r.to < today ? `/my/weekly?student=${chosen}&end=${shiftDay(r.to, 7)}` : null,
          }}
        />
      )}
    </div>
  );
}
