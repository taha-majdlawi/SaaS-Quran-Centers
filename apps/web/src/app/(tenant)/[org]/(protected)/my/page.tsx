import { ReciteFab } from '@/components/recite-fab';
import { GoalCard, type GoalProgress } from '@/components/goal-card';
import { WirdCard, type Wird } from '@/components/wird-card';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SerdSummaryCard, type SerdSummary } from '@/components/serd-summary-card';
import type { AnnouncementRow } from '@/components/announcements-view';
import { ProgressRing } from '@/components/portal/progress-ring';
import { PrayerTimesCard } from '@/components/portal/prayer-times-card';
import { RecitationItem } from '@/components/portal/recitations-search-list';
import { fmtDay, type CalRange } from '@/lib/calendar/format';
import type { BadgeProgress } from '@/lib/engagement/format';
import { addDays, computeGoals, dailyInspiration, fmtDate, localDate, recitationLabels, type Dashboard } from '@/lib/portal/format';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';

interface StudentRow {
  id: string;
  student_code: string;
  full_name: string;
}

const PRAYER_KEYS = ['prayer_lat', 'prayer_lng', 'prayer_calc_method', 'prayer_madhab'];

// The entire web dashboard under (staff) is off-limits to student/guardian
// accounts (see (staff)/layout.tsx) - this is the one page they land on
// instead. Same sections as the mobile home (my_portal_screen.dart _HomeTab):
// the core numbers come from get_student_dashboard, and every extra section
// is its own existing feature call, so one failing (e.g. a module switched
// off) never blanks the rest.
export default async function MyPortalPage({
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
  const on = (m: string) => !org.disabledModules.includes(m);
  const { t, locale } = await getI18n();
  const p = t.portal;

  const [{ data: students }, { data: orgRow }] = await Promise.all([
    supabase.from('students_profile').select('id, student_code, full_name').eq('organization_id', org.id).order('full_name'),
    supabase.from('organizations').select('timezone').eq('id', org.id).single(),
  ]);
  const rows = (students ?? []) as StudentRow[];

  if (!rows.length) {
    return (
      <div className="mx-auto max-w-lg py-16 text-center text-gray-500">
        <p>{fmt(p.noProfile, { org: org.name })}</p>
        <p className="mt-2 text-sm">{p.noProfileHint}</p>
      </div>
    );
  }
  const current = rows.find((x) => x.id === s) ?? rows[0];
  const today = localDate((orgRow?.timezone as string | null) || 'UTC');

  const [dash, serd, ann, cal, badges, settings, goalRes, reviewRes] = await Promise.all([
    supabase.rpc('get_student_dashboard', { p_org: org.id, p_student_id: current.id }),
    supabase.rpc('serd_student_summary', { p_org: org.id, p_student: current.id }),
    on('announcements') ? supabase.rpc('list_announcements', { p_org: org.id }) : Promise.resolve({ data: [] }),
    on('calendar') ? supabase.rpc('calendar_range', { p_org: org.id, p_from: today, p_to: addDays(today, 7), p_circle: null }) : Promise.resolve({ data: null }),
    on('badges') ? supabase.rpc('get_student_badges', { p_org: org.id, p_student: current.id }) : Promise.resolve({ data: [] }),
    supabase.from('organization_settings').select('key, value').eq('organization_id', org.id).in('key', PRAYER_KEYS),
    supabase.rpc('student_goal_progress', { p_org: org.id, p_student: current.id }),
    supabase.rpc('student_wird', { p_org: org.id, p_student: current.id }),
  ]);
  const goal = goalRes.data as GoalProgress | null;

  const d = dash.data as Dashboard | null;
  const announcements = ((ann.data ?? []) as AnnouncementRow[]).filter((a) => !a.draft).slice(0, 2);
  const upcoming = ((cal.data as CalRange | null)?.entries ?? []).slice(0, 3);
  const earned = ((badges.data ?? []) as BadgeProgress[]).filter((b) => b.earned);
  const prayerSettings = Object.fromEntries(((settings.data ?? []) as { key: string; value: string }[]).map((r) => [r.key, r.value]));
  const inspiration = dailyInspiration(today);

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-4 p-6">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h1 className="text-2xl font-bold">
          {fmt(org.myRole === 'guardian' ? p.titleGuardian : p.titleStudent, { org: org.name })}
        </h1>
        <div className="flex flex-wrap gap-2">
          <a href={`/my/record?s=${current.id}` as never} className="rounded border px-4 py-2 text-sm text-brand">
            {p.nav.record}
          </a>
          {on('quran') && (
            <a href="/my/quran" className="rounded border px-4 py-2 text-sm text-brand">
              {p.nav.quran}
            </a>
          )}
          {on('recitations') && (
            <a href={`/my/recitations?s=${current.id}` as never} className="rounded border px-4 py-2 text-sm text-brand">
              {t.quran.recite.myTitle}
            </a>
          )}
          {on('announcements') && (
            <a href="/my/announcements" className="rounded border px-4 py-2 text-sm text-brand">
              {p.nav.announcements}
            </a>
          )}
          {on('chat') && (
            <a href="/my/chat" className="rounded border px-4 py-2 text-sm text-brand">
              {p.nav.chat}
            </a>
          )}
          <a href="/my/notifications" className="rounded border px-4 py-2 text-sm text-brand">
            {p.nav.notifications}
          </a>
          {on('badges') && (
            <a href="/my/badges" className="rounded border px-4 py-2 text-sm text-brand">
              {p.nav.badges}
            </a>
          )}
          {on('market') && (
            <a href="/my/market" className="rounded border px-4 py-2 text-sm text-brand">
              {p.nav.market}
            </a>
          )}
          {org.feesEnabled && (
            <a href={`/my/fees?s=${current.id}` as never} className="rounded border px-4 py-2 text-sm text-brand">
              {t.staff.fees.title}
            </a>
          )}
          <a href="/my/privacy" className="rounded border px-4 py-2 text-sm text-gray-500">
            {p.nav.privacy}
          </a>
          {on('reports') && (
            <a href="/my/report" className="rounded border px-4 py-2 text-sm text-brand">
              {p.nav.report}
            </a>
          )}
          {on('certificates') && (
            <a href="/my/certificates" className="rounded border px-4 py-2 text-sm text-brand">
              {p.nav.certificates}
            </a>
          )}
          {on('calendar') && (
            <a href="/my/calendar" className="rounded border px-4 py-2 text-sm text-brand">
              {p.nav.calendar}
            </a>
          )}
        </div>
      </div>

      {rows.length > 1 && (
        <div className="flex flex-wrap gap-2">
          {rows.map((x) => (
            <a
              key={x.id}
              href={`/my?s=${x.id}` as never}
              className={`rounded-full border px-4 py-1.5 text-sm ${x.id === current.id ? 'border-brand bg-brand text-white' : 'bg-white text-gray-700'}`}
            >
              {x.full_name}
            </a>
          ))}
        </div>
      )}

      {!d || !d.linked ? (
        <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-500">{p.studentMissing}</p>
      ) : (
        <StudentHome
          d={d}
          serd={serd.data as SerdSummary | null}
          announcements={announcements}
          upcoming={upcoming}
          earned={earned}
          prayerSettings={prayerSettings}
          inspiration={inspiration}
          recordHref={`/my/record?s=${current.id}`}
          goalCard={
            <>
              {goal && <GoalCard g={goal} orgId={org.id} studentId={current.id} back="/my" />}
              {on('wird') && (
                <WirdCard wird={reviewRes.data as Wird | null} base="/my/quran" canRecite={on('recitations')} studentId={current.id} locale={locale} W={t.wird} />
              )}
              <a href={`/my/weekly?student=${current.id}` as never} className="block rounded-lg border bg-white p-3 text-center text-sm font-semibold text-brand hover:bg-gray-50">
                📊 {t.staff.weekly.open}
              </a>
            </>
          }
          t={t}
        />
      )}
      {on('recitations') && <ReciteFab href={`/my/recite?s=${current.id}`} label={t.live.fab} />}
    </div>
  );
}

function StudentHome({
  d,
  serd,
  announcements,
  upcoming,
  earned,
  prayerSettings,
  inspiration,
  recordHref,
  goalCard,
  t,
}: {
  d: Dashboard;
  serd: SerdSummary | null;
  announcements: AnnouncementRow[];
  upcoming: CalRange['entries'];
  earned: BadgeProgress[];
  prayerSettings: Record<string, string>;
  inspiration: ReturnType<typeof dailyInspiration>;
  recordHref: string;
  goalCard: React.ReactNode;
  t: Dictionary;
}) {
  const p = t.portal;
  const lang = t.labels.dateLocale;
  const { student, circle, stats, recent } = d;
  const change = stats.recitations_this_week - stats.recitations_last_week;
  const weekText = change > 0 ? fmt(p.weekBetter, { n: change }) : change < 0 ? fmt(p.weekWorse, { n: change }) : p.weekSame;
  const trend = change > 0 ? { icon: '↗', cls: 'text-green-600' } : change < 0 ? { icon: '↘', cls: 'text-red-600' } : { icon: '→', cls: 'text-gray-400' };
  const goals = computeGoals(student.total_parts_count, student.total_points, p);

  return (
    <>
      <div className="flex items-center justify-between gap-4 rounded-lg bg-brand p-5 text-white">
        <div>
          <h2 className="text-lg font-bold">{fmt(p.hello, { name: student.full_name.split(' ')[0] })}</h2>
          <p className="text-sm opacity-85">
            {circle ? `${circle.name}${circle.teacher ? ` · ${fmt(p.sheikh, { name: circle.teacher })}` : ''}` : p.noCircle}
          </p>
          <p className="mt-1 text-sm">
            <b className="text-xl">{student.total_points}</b> <span className="opacity-85">{p.points}</span>
          </p>
          <p className="text-xs opacity-70" dir="ltr">
            {student.student_code}
          </p>
        </div>
        <div className="flex flex-col items-center gap-1">
          <ProgressRing progress={student.total_parts_count / 30} label={`${student.total_parts_count}/30`} />
          <span className="text-sm font-bold">🔥 {stats.current_streak}</span>
        </div>
      </div>

      {announcements.length > 0 && (
        <a href="/my/announcements" className="block rounded-lg border border-amber-200 bg-amber-50 p-4 text-sm hover:bg-amber-100">
          <p className="font-bold">{p.announcements}</p>
          {announcements.map((a) => (
            <p key={a.id} className="mt-2 truncate font-semibold">
              {a.title}
            </p>
          ))}
        </a>
      )}

      <section className="rounded-lg border bg-white p-4 text-sm">
        <h3 className="mb-2 font-semibold text-gray-600">{p.progressTitle}</h3>
        <p className="font-semibold">{fmt(p.progress, { parts: student.total_parts_count, pct: student.total_progress })}</p>
        {student.next_plan && <p className="mt-3 rounded bg-amber-50 p-3">{fmt(p.nextPlan, { plan: student.next_plan })}</p>}
      </section>

      {goalCard}

      <section className="flex flex-col gap-4 rounded-lg border bg-white p-4 text-sm">
        {goals.map((g) => (
          <div key={g.label}>
            <div className="mb-1.5 flex items-center justify-between gap-2">
              <span className="font-bold">
                {g.icon} {g.label}
              </span>
              <span className="text-xs text-gray-500">
                {fmt(p.remaining, { n: g.remaining, unit: g.unit })}
              </span>
            </div>
            <div className="h-2 overflow-hidden rounded bg-gray-100">
              <div className="h-full bg-brand" style={{ width: `${Math.round(g.progress * 100)}%` }} />
            </div>
          </div>
        ))}
      </section>

      {upcoming.length > 0 && (
        <a href="/my/calendar" className="block rounded-lg border bg-white p-4 text-sm hover:bg-gray-50">
          <p className="font-bold">{p.upcoming}</p>
          {upcoming.map((e) => (
            <p key={e.id} className="mt-2 flex items-center gap-2">
              <span className="h-2 w-2 shrink-0 rounded-full" style={{ backgroundColor: e.type_color }} />
              <span className="flex-1 truncate">{e.title}</span>
              <span className="text-xs text-gray-500">{fmtDay(e.start_date, lang)}</span>
            </p>
          ))}
        </a>
      )}

      {inspiration && (
        // an ayah / hadith: Arabic, right to left, in every language
        <div dir="rtl" lang="ar" className="rounded-lg border bg-gray-50 p-4 text-center">
          <p className="font-bold leading-loose">{inspiration.text}</p>
          <p className="mt-1 text-xs text-gray-500">{inspiration.source}</p>
        </div>
      )}

      <PrayerTimesCard settings={prayerSettings} names={p.prayers} />

      <div className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-4">
        <Stat label={p.statAyahs} value={String(stats.ayahs_this_week)} />
        <Stat label={p.statAttendance} value={stats.weekly_attendance_rate == null ? '—' : `${stats.weekly_attendance_rate}%`} />
        <Stat label={p.statTotal} value={String(stats.total_recitations)} />
        <Stat label={p.statLast} value={fmtDate(stats.last_recitation_at, lang)} />
      </div>

      <section className="rounded-lg border bg-white p-4 text-sm">
        <h3 className="mb-2 font-semibold text-gray-600">{p.weekTitle}</h3>
        <p className="font-bold">
          <span className={`${trend.cls} me-1`} aria-hidden>
            {trend.icon}
          </span>
          {fmt(p.weekCount, { n: stats.recitations_this_week })}
        </p>
        <p className="text-gray-500">{weekText}</p>
        <hr className="my-3" />
        <p>{fmt(p.streak, { n: stats.current_streak, best: stats.longest_streak })}</p>
        {stats.current_streak > 0 && stats.current_streak === stats.longest_streak && (
          <p className="mt-3 rounded bg-orange-50 p-2 text-center font-bold">{p.streakRecord}</p>
        )}
      </section>

      {earned.length > 0 && (
        <a href="/my/badges" className="block rounded-lg border bg-white p-4 text-sm hover:bg-gray-50">
          <p className="flex justify-between font-bold">
            <span>{p.yourBadges}</span>
            <span className="font-normal text-gray-500">{earned.length}</span>
          </p>
          <div className="mt-3 flex flex-wrap gap-2">
            {earned.slice(0, 8).map((b) => (
              <span
                key={b.id}
                className="rounded-full px-3 py-1 text-xs font-bold"
                style={{ backgroundColor: `${b.color}26`, color: b.color }}
              >
                {b.icon} {b.name}
              </span>
            ))}
          </div>
        </a>
      )}

      <div>
        <h3 className="mb-2 text-sm font-semibold text-gray-600">{p.serd}</h3>
        <SerdSummaryCard summary={serd} />
      </div>

      <div>
        <div className="mb-2 flex items-center justify-between">
          <h3 className="text-sm font-semibold text-gray-600">{p.recent}</h3>
          <a href={recordHref as never} className="text-sm text-brand hover:underline">
            {p.fullRecord}
          </a>
        </div>
        {recent.length ? (
          <ul className="flex flex-col gap-2 text-sm">
            {recent.slice(0, 5).map((r) => (
              <RecitationItem key={r.id} r={r} labels={recitationLabels(t)} />
            ))}
          </ul>
        ) : (
          <p className="text-sm text-gray-400">{p.noRecitations}</p>
        )}
      </div>
    </>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded border bg-gray-50 p-3 text-center">
      <p className="text-lg font-bold">{value}</p>
      <p className="text-xs text-gray-500">{label}</p>
    </div>
  );
}
