import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SerdSummaryCard, type SerdSummary } from '@/components/serd-summary-card';
import { RecitationsSearchList } from '@/components/portal/recitations-search-list';
import { ATTENDANCE_STYLES, fmtDate, localDate, recitationLabels, type RecordDetail } from '@/lib/portal/format';
import { getI18n } from '@/lib/i18n/server';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';

const TABS = ['recitations', 'attendance', 'serd'] as const;
type Tab = (typeof TABS)[number];

// سجلّي: تسميع / حضور / سرد, one segment at a time - the mobile _RecordTab
// (my_portal_screen.dart). Recitations + attendance come from
// student_record_detail (0056); the month is the center's month.
export default async function MyRecordPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ s?: string; tab?: string }>;
}) {
  const { org: slug } = await params;
  const { s, tab: tabParam } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const tab: Tab = TABS.some((k) => k === tabParam) ? (tabParam as Tab) : 'recitations';
  const { t } = await getI18n();

  // RLS shows a student only their own row and a guardian only their children
  const [{ data: students }, { data: orgRow }] = await Promise.all([
    supabase.from('students_profile').select('id, full_name').eq('organization_id', org.id).order('full_name'),
    supabase.from('organizations').select('timezone').eq('id', org.id).single(),
  ]);
  const list = (students ?? []) as { id: string; full_name: string }[];
  const current = list.find((x) => x.id === s) ?? list[0];
  const tz = (orgRow?.timezone as string | null) || 'UTC';

  const [detail, serd, grades] = current
    ? await Promise.all([
        tab === 'serd' ? Promise.resolve({ data: null, error: null }) : supabase.rpc('student_record_detail', { p_org: org.id, p_student: current.id }),
        tab === 'serd' ? supabase.rpc('serd_student_summary', { p_org: org.id, p_student: current.id }) : Promise.resolve({ data: null }),
        supabase.from('recitation_grades').select('key, label').eq('organization_id', org.id),
      ])
    : [{ data: null, error: null }, { data: null }, { data: [] }];
  const rd = detail.data as RecordDetail | null;
  const gradeLabels = new Map(((grades.data ?? []) as { key: string; label: string }[]).map((g) => [g.key, g.label]));
  const href = (t: Tab, sid = current?.id) => `/my/record?s=${sid}&tab=${t}`;

  return (
    <div className="mx-auto max-w-3xl p-6">
      <a href="/my" className="text-sm text-brand hover:underline">
        {t.portal.backToProfile}
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">{t.record.title}</h1>

      {!current ? (
        <p className="text-gray-500">{t.portal.noStudent}</p>
      ) : (
        <>
          {list.length > 1 && (
            <div className="mb-4 flex flex-wrap gap-2">
              {list.map((x) => (
                <a
                  key={x.id}
                  href={href(tab, x.id) as never}
                  className={`rounded-full border px-4 py-1.5 text-sm ${x.id === current.id ? 'border-brand bg-brand text-white' : 'bg-white text-gray-700'}`}
                >
                  {x.full_name}
                </a>
              ))}
            </div>
          )}

          <nav className="mb-4 grid grid-cols-3 overflow-hidden rounded-lg border bg-white text-center text-sm">
            {TABS.map((key) => (
              <a
                key={key}
                href={href(key) as never}
                aria-current={tab === key ? 'page' : undefined}
                className={`py-2 font-semibold ${tab === key ? 'bg-brand text-white' : 'text-gray-600 hover:bg-gray-50'}`}
              >
                {t.record.tabs[key]}
              </a>
            ))}
          </nav>

          {detail.error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{detail.error.message}</p>}

          {tab === 'recitations' && rd && <RecitationsTab rd={rd} tz={tz} gradeLabels={gradeLabels} t={t} />}
          {tab === 'attendance' && rd && <AttendanceTab rows={rd.attendance} t={t} />}
          {tab === 'serd' && <SerdSummaryCard summary={serd.data as SerdSummary | null} />}
        </>
      )}
    </div>
  );
}

function RecitationsTab({ rd, tz, gradeLabels, t }: { rd: RecordDetail; tz: string; gradeLabels: Map<string, string>; t: Dictionary }) {
  const month = localDate(tz).slice(0, 7);
  const inMonth = (iso: string) => localDate(tz, new Date(iso)).slice(0, 7) === month;
  const monthly = rd.recitations.filter((r) => inMonth(r.created_at));
  const ayahs = monthly.filter((r) => r.type === 'new_memorization').reduce((sum, r) => sum + (r.ayah_to - r.ayah_from + 1), 0);
  // attendance.date is a plain date already in the center's calendar
  const monthAttendance = rd.attendance.filter((a) => a.date.slice(0, 7) === month);
  const rate = monthAttendance.length ? Math.round((monthAttendance.filter((a) => a.status === 'present').length / monthAttendance.length) * 100) : null;

  return (
    <div className="flex flex-col gap-4">
      <section className="rounded-lg border bg-white p-4 text-sm">
        <h2 className="mb-3 font-bold">{t.record.thisMonth}</h2>
        <div className="grid grid-cols-4 gap-2 text-center">
          {[
            [t.record.recitations, monthly.length],
            [t.record.ayahs, ayahs],
            [t.record.attendance, rate == null ? '—' : `${rate}%`],
            [t.record.points, rd.monthly_points],
          ].map(([label, value]) => (
            <div key={String(label)}>
              <p className="text-lg font-bold">{value}</p>
              <p className="text-xs text-gray-500">{label}</p>
            </div>
          ))}
        </div>
      </section>

      {rd.points_breakdown.length > 0 && (
        <section className="rounded-lg border bg-white p-4 text-sm">
          <h2 className="mb-3 font-bold">{t.record.breakdown}</h2>
          <ul className="flex flex-col gap-1.5">
            {rd.points_breakdown.map((r) => (
              <li key={`${r.grade}-${r.points_each}`} className="flex justify-between">
                <span>{gradeLabels.get(r.grade) ?? r.grade}</span>
                <b dir="ltr">
                  {r.count} × {r.points_each} = {r.total}
                </b>
              </li>
            ))}
          </ul>
        </section>
      )}

      {rd.recitations.length ? (
        <RecitationsSearchList recitations={rd.recitations} labels={recitationLabels(t)} />
      ) : (
        <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">{t.portal.noRecitations}</p>
      )}
    </div>
  );
}

function AttendanceTab({ rows, t }: { rows: RecordDetail['attendance']; t: Dictionary }) {
  if (!rows.length) return <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">{t.record.noAttendance}</p>;
  return (
    <ul className="flex flex-col gap-2 text-sm">
      {rows.map((a) => (
        <li key={a.date} className="flex items-center justify-between rounded-lg border bg-white px-4 py-2.5">
          <span>{fmtDate(`${a.date}T00:00:00`, t.labels.dateLocale)}</span>
          <span className={`rounded-full px-3 py-0.5 text-xs font-semibold ${ATTENDANCE_STYLES[a.status] ?? 'bg-gray-100 text-gray-600'}`}>
            {t.labels.attendance[a.status] ?? a.status}
          </span>
        </li>
      ))}
    </ul>
  );
}
