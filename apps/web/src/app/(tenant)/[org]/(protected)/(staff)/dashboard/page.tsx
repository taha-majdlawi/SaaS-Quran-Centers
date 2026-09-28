import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { fmtDay, pct } from '@/lib/reports/format';
import { teacherCheckIn } from '@/lib/insights/actions';
import { SubmitButton } from '@/components/submit-button';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

interface Risk { id: string; name: string; circle: string | null; last_at: string | null; idle_days: number; tag: string }
interface Perf { teacher_id: string; name: string | null; circles: number; students: number; recitations: number; reciting_students: number; check_ins: number }
interface Trend { date: string; recitations: number; attendance: number }

interface Attention {
  serd_submitted: number;
  market_pending: number;
  deletion_pending: number;
  inactive_total: number;
  inactive_students: { id: string; name: string; circle: string | null; last_at: string | null }[];
  upcoming: { id: string; title: string; start_date: string; starts_at: string | null; registered: number; capacity: number | null }[];
  week: { recitations: number; points: number; reciting_students: number; attendance_rate: number | null };
}

// Replaces wep-eqraa-center/admin/dashboard - same KPI-counter idea, now
// scoped by organization_id via RLS instead of "the one Supabase project".
export default async function DashboardPage({ params, searchParams }: { params: Promise<{ org: string }>; searchParams: Promise<{ ok?: string; error?: string }> }) {
  const { org: slug } = await params;
  const { ok, error } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();

  const [{ count: studentCount }, { count: teacherCount }, { count: circleCount }] = await Promise.all([
    supabase
      .from('students_profile')
      .select('*', { count: 'exact', head: true })
      .eq('organization_id', org.id),
    supabase
      .from('organization_members')
      .select('*', { count: 'exact', head: true })
      .eq('organization_id', org.id)
      .eq('role', 'teacher'),
    supabase.from('circles').select('*', { count: 'exact', head: true }).eq('organization_id', org.id),
  ]);

  const { data: todayData } = await supabase.rpc('get_teacher_today', { p_org: org.id });
  const today = todayData as {
    is_working_day: boolean;
    circles: { id: string; name: string; students: number; recited: number; present: number; absent: number }[];
  } | null;

  // Admin only: what needs a decision or a call today (one RPC)
  const { data: attentionData } = org.myRole === 'admin' ? await supabase.rpc('admin_attention', { p_org: org.id }) : { data: null };
  const att = attentionData as Attention | null;
  const { data: pendingData } = org.myRole === 'admin' ? await supabase.rpc('admin_pending_reviews', { p_org: org.id }) : { data: null };
  const pendingReviews = (pendingData ?? { gatherings: 0, external: 0 }) as { gatherings: number; external: number };
  const waiting = att
    ? [
        { label: S.dash.serdWaiting, value: att.serd_submitted, href: '/serd?status=submitted' },
        { label: S.dash.marketWaiting, value: att.market_pending, href: '/market' },
        { label: S.dash.gatheringsWaiting, value: pendingReviews.gatherings, href: '/gatherings' },
        { label: S.dash.externalWaiting, value: pendingReviews.external, href: '/external-recitations' },
      ].filter((w) => w.value > 0)
    : [];

  const isAdmin = org.myRole === 'admin';
  const [{ data: riskData }, { data: perfData }, { data: trendData }, { data: checkData }] = await Promise.all([
    isAdmin ? supabase.rpc('admin_dropout_risk', { p_org: org.id, p_limit: 8 }) : Promise.resolve({ data: null }),
    isAdmin ? supabase.rpc('admin_teacher_performance', { p_org: org.id, p_days: 7 }) : Promise.resolve({ data: null }),
    isAdmin ? supabase.rpc('admin_daily_trend', { p_org: org.id, p_days: 14 }) : Promise.resolve({ data: null }),
    org.myRole === 'teacher' ? supabase.rpc('teacher_today_attendance', { p_org: org.id }) : Promise.resolve({ data: null }),
  ]);
  const risk = (riskData ?? []) as Risk[];
  const perf = (perfData ?? []) as Perf[];
  const trend = (trendData ?? []) as Trend[];
  const checkedIn = new Set(((checkData ?? []) as { circle_id: string }[]).map((c) => c.circle_id));
  const maxTrend = Math.max(1, ...trend.map((t) => t.recitations));

  const stats = [
    { label: S.dash.students, value: studentCount ?? 0 },
    { label: S.dash.teachers, value: teacherCount ?? 0 },
    { label: S.dash.circles, value: circleCount ?? 0 },
  ];

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold">{S.dash.title}</h1>
      {ok && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{ok}</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      <form action={'/search' as never} className="mb-6 flex max-w-xl gap-2">
        <input name="q" placeholder={S.dash.searchPlaceholder} className="flex-1 rounded border bg-white px-3 py-2 text-sm" />
        <button className="rounded bg-brand px-4 py-2 text-sm text-white">{S.dash.search}</button>
      </form>
      <div className="grid grid-cols-3 gap-4">
        {stats.map((s) => (
          <div key={s.label} className="rounded-lg border bg-white p-6">
            <p className="text-sm text-gray-500">{s.label}</p>
            <p className="text-3xl font-bold text-brand">{s.value}</p>
          </div>
        ))}
      </div>

      {att && (
        <div className="mt-8 grid gap-4 lg:grid-cols-2">
          <section className="rounded-lg border bg-white p-4">
            <h2 className="mb-3 font-semibold">{S.dash.attention}</h2>
            {waiting.length ? (
              <ul className="flex flex-col gap-2 text-sm">
                {waiting.map((w) => (
                  <li key={w.label}>
                    <a href={w.href as never} className="flex items-center justify-between rounded bg-amber-50 px-3 py-2 hover:bg-amber-100">
                      <span>{w.label}</span>
                      <b className="text-amber-800">{w.value}</b>
                    </a>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-gray-500">{S.dash.nothingWaiting}</p>
            )}
            <h3 className="mb-2 mt-5 text-sm font-semibold">
              {S.dash.inactive} {att.inactive_total > 0 && <span className="text-gray-400">({att.inactive_total})</span>}
            </h3>
            {att.inactive_students.length ? (
              <ul className="flex flex-col gap-1 text-sm">
                {att.inactive_students.map((s) => (
                  <li key={s.id} className="flex justify-between">
                    <a href={`/students/${s.id}/report` as never} className="text-brand hover:underline">
                      {s.name}
                    </a>
                    <span className="text-xs text-gray-400">
                      {s.circle ?? '—'} · {s.last_at ? fmtDay(s.last_at, T.labels.dateLocale) : S.dash.notYet}
                    </span>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-gray-500">{S.dash.allActive}</p>
            )}
          </section>

          <section className="rounded-lg border bg-white p-4">
            <h2 className="mb-3 font-semibold">{S.dash.thisWeek}</h2>
            <div className="grid grid-cols-2 gap-3 text-sm">
              <div>
                <p className="text-gray-500">{S.dash.recitations}</p>
                <p className="text-xl font-bold text-brand">{att.week.recitations}</p>
              </div>
              <div>
                <p className="text-gray-500">{S.dash.recitingStudents}</p>
                <p className="text-xl font-bold text-brand">{att.week.reciting_students}</p>
              </div>
              <div>
                <p className="text-gray-500">{S.dash.points}</p>
                <p className="text-xl font-bold text-brand">{att.week.points}</p>
              </div>
              <div>
                <p className="text-gray-500">{S.dash.attendance}</p>
                <p className="text-xl font-bold text-brand">{pct(att.week.attendance_rate)}</p>
              </div>
            </div>
            <h3 className="mb-2 mt-5 text-sm font-semibold">{S.dash.upcoming}</h3>
            {att.upcoming.length ? (
              <ul className="flex flex-col gap-1 text-sm">
                {att.upcoming.map((e) => (
                  <li key={e.id} className="flex justify-between">
                    <a href={`/calendar/${e.id}` as never} className="text-brand hover:underline">
                      {e.title}
                    </a>
                    <span className="text-xs text-gray-500">
                      {fmtDay(e.start_date, T.labels.dateLocale)} · {fmt(S.dash.registered, { n: e.registered })}
                      {e.capacity ? `/${e.capacity}` : ''}
                    </span>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-gray-500">{S.dash.noUpcoming}</p>
            )}
          </section>
        </div>
      )}

      {isAdmin && (
        <div className="mt-8 grid gap-4 lg:grid-cols-2">
          <section className="rounded-lg border bg-white p-4">
            <h2 className="mb-3 font-semibold">{S.dash.risk}</h2>
            {risk.length ? (
              <ul className="flex flex-col gap-1.5 text-sm">
                {risk.map((r) => (
                  <li key={r.id} className="flex items-center justify-between gap-2">
                    <a href={`/students/${r.id}/report` as never} className="text-brand hover:underline">{r.name}</a>
                    <span className="text-xs text-gray-500">
                      <span className="me-2 rounded bg-amber-100 px-1.5 py-0.5 text-amber-800">{S.dash.riskTags[r.tag] ?? r.tag}</span>
                      {r.circle} · {fmt(S.dash.idleDays, { n: r.idle_days })}
                    </span>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-gray-500">{S.dash.noRisk}</p>
            )}
          </section>
          <section className="rounded-lg border bg-white p-4">
            <h2 className="mb-3 font-semibold">{S.dash.trend}</h2>
            <div className="flex h-28 items-end gap-1">
              {trend.map((t) => (
                <div key={t.date} className="group relative flex-1" title={fmt(S.dash.trendTip, { date: fmtDay(t.date, T.labels.dateLocale), n: t.recitations, a: t.attendance })}>
                  <div className="w-full rounded-t bg-brand/70" style={{ height: `${Math.max(3, (t.recitations / maxTrend) * 100)}%` }} />
                </div>
              ))}
            </div>
            <div className="mt-1 flex justify-between text-[11px] text-gray-400">
              <span>{trend[0] ? fmtDay(trend[0].date, T.labels.dateLocale) : ''}</span>
              <span>{trend.length ? fmtDay(trend[trend.length - 1].date, T.labels.dateLocale) : ''}</span>
            </div>
          </section>
          <section className="rounded-lg border bg-white p-4 lg:col-span-2">
            <h2 className="mb-3 font-semibold">{S.dash.perf}</h2>
            <div className="overflow-auto">
              <table className="w-full text-sm">
                <thead className="text-start text-xs text-gray-500">
                  <tr>{S.dash.perfCols.map((h) => <th key={h} className="p-1 text-start">{h}</th>)}</tr>
                </thead>
                <tbody className="divide-y">
                  {perf.map((p) => (
                    <tr key={p.teacher_id}>
                      <td className="p-1">{p.name ?? '—'}</td><td className="p-1">{p.circles}</td><td className="p-1">{p.students}</td>
                      <td className="p-1 font-semibold text-brand">{p.recitations}</td><td className="p-1">{p.reciting_students}</td><td className="p-1">{p.check_ins}</td>
                    </tr>
                  ))}
                  {!perf.length && <tr><td colSpan={6} className="p-4 text-center text-gray-400">{S.dash.noTeachers}</td></tr>}
                </tbody>
              </table>
            </div>
          </section>
        </div>
      )}

      {today && today.circles.length > 0 && (
        <div className="mt-8">
          <h2 className="mb-3 font-semibold">{S.dash.today}</h2>
          {!today.is_working_day && (
            <p className="mb-3 rounded bg-amber-50 px-3 py-2 text-sm text-amber-800">{S.dash.dayOff}</p>
          )}
          <div className="grid gap-3 sm:grid-cols-2">
            {today.circles.map((c) => (
              <div key={c.id} className="rounded-lg border bg-white p-4">
                <p className="font-semibold">{c.name}</p>
                <p className="mt-1 text-sm text-gray-600">
                  {fmt(S.dash.circleToday, { students: c.students, recited: c.recited, present: c.present })}
                  {c.absent > 0 && fmt(S.dash.absentN, { n: c.absent })}
                </p>
                {org.myRole === 'teacher' && (
                  checkedIn.has(c.id) ? (
                    <p className="mt-2 text-xs text-green-700">{S.dash.checkedIn}</p>
                  ) : (
                    <form action={teacherCheckIn} className="mt-2">
                      <input type="hidden" name="orgId" value={org.id} />
                      <input type="hidden" name="circleId" value={c.id} />
                      <input type="hidden" name="back" value="/dashboard" />
                      <SubmitButton className="rounded border px-3 py-1 text-xs text-brand hover:bg-gray-50" pendingText="...">{S.dash.checkIn}</SubmitButton>
                    </form>
                  )
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
