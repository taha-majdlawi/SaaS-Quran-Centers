import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { PrintButton } from '@/components/print-button';
import { WeeklyReportView, shiftDay, type WeeklyReport } from '@/components/weekly-report-view';
import { getI18n } from '@/lib/i18n/server';

// What the family receives each week, as the staff see it (0077).
export default async function StudentWeeklyPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ end?: string }>;
}) {
  const { org: slug, id } = await params;
  const { end } = await searchParams;
  const org = await getOrgContext(slug);
  const { t } = await getI18n();
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('student_weekly_report', { p_org: org.id, p_student: id, p_week_end: end || null });
  const r = data as WeeklyReport | null;
  const today = new Date().toISOString().slice(0, 10);

  return (
    <div className="max-w-3xl">
      <div className="mb-4 flex items-center justify-between gap-2 print:hidden">
        <a href={`/students/${id}` as never} className="text-sm text-brand hover:underline">{t.staff.profile.backProfile}</a>
        <PrintButton label={t.report.print} />
      </div>
      <h1 className="mb-3 text-2xl font-bold">{t.staff.weekly.title}</h1>
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error.message}</p>}
      {r && (
        <WeeklyReportView
          r={r}
          orgId={org.id}
          nav={{
            prev: `/students/${id}/weekly?end=${shiftDay(r.to, -7)}`,
            next: r.to < today ? `/students/${id}/weekly?end=${shiftDay(r.to, 7)}` : null,
          }}
        />
      )}
    </div>
  );
}
