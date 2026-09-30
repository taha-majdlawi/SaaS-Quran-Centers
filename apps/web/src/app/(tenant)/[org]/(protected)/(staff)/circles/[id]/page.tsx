import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { RangeForm } from '@/components/report-views';
import { ActionLink, Chip, CountList, DailyBars, Facts, Panel, ProfileHeader, RecitationTable, gradeLabelMap, Stat, StatGrid, relDay, type RecRow } from '@/components/profile-views';
import { defaultRange, fmtDay, pct } from '@/lib/reports/format';
import { getI18n } from '@/lib/i18n/server';

interface CircleProfile {
  from: string;
  to: string;
  circle: { id: string; name: string; status: string; capacity: number | null; schedule: Record<string, unknown> | null; created_at: string; stage: string | null };
  teacher: { member_id: string; name: string | null; phone: string | null } | null;
  assistants: { member_id: string; name: string | null }[];
  totals: {
    students: number;
    recitations: number;
    reciting_students: number;
    points: number;
    present: number;
    late: number;
    absent: number;
    excused: number;
    attendance_rate: number | null;
    serd_approved: number;
    teacher_days: number;
  };
  students: { id: string; name: string; code: string; status: string; total_points: number; parts_count: number | null; recitations: number; points: number; attendance_rate: number | null; last_recited: string | null }[];
  by_type: { type: string; count: number }[];
  daily: { date: string; recitations: number }[];
  recent: RecRow[];
}

const td = 'px-3 py-2';
const th = 'px-3 py-2 text-start font-semibold';

export default async function CircleProfilePage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ from?: string; to?: string }>;
}) {
  const { org: slug, id } = await params;
  const { from, to } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T, locale } = await getI18n();
  const S = T.staff;
  const P = S.profile;
  const lang = T.labels.dateLocale;
  const range = defaultRange();
  const f = from || range.from;
  const t = to || range.to;
  const supabase = await createClient();

  const grades = gradeLabelMap((await supabase.from('recitation_grades').select('key, label').eq('organization_id', org.id)).data);
  const { data, error } = await supabase.rpc('circle_profile', { p_org: org.id, p_circle: id, p_from: f, p_to: t });
  if (error && /غير موجود|not found/i.test(error.message)) notFound();
  const r = data as CircleProfile | null;
  if (!r) return <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error?.message ?? P.notAllowed}</p>;
  const c = r.circle;
  const tt = r.totals;
  const isAdmin = org.myRole === 'admin';
  const sep = T.labels.listSep;
  const active = r.students.filter((s) => s.status === 'active').length;

  return (
    <div className="max-w-6xl">
      <ProfileHeader
        name={c.name}
        subtitle={
          <>
            {P.teacher}:{' '}
            {r.teacher ? <a href={`/teachers/${r.teacher.member_id}` as never} className="text-brand hover:underline">{r.teacher.name ?? '—'}</a> : '—'}
            {r.assistants.length > 0 && (
              <>
                {' · '}
                {P.assistants}:{' '}
                {r.assistants.map((a, i) => (
                  <span key={a.member_id}>
                    {i > 0 && sep}
                    <a href={`/teachers/${a.member_id}` as never} className="text-brand hover:underline">{a.name ?? '—'}</a>
                  </span>
                ))}
              </>
            )}
          </>
        }
        chips={
          <>
            <Chip tone={c.status === 'active' ? 'green' : 'gray'}>{S.circles.status[c.status] ?? c.status}</Chip>
            {c.stage && <Chip>{c.stage}</Chip>}
            <Chip tone="brand">
              {P.students}: {active}
              {c.capacity ? ` / ${c.capacity}` : ''}
            </Chip>
          </>
        }
        actions={
          <>
            <ActionLink href={`/attendance?circleId=${c.id}`} primary>{S.nav.items.attendance}</ActionLink>
            {isAdmin && <ActionLink href={`/circles/${c.id}/edit`}>{P.edit}</ActionLink>}
          </>
        }
      />

      <h2 className="mb-3 text-lg font-bold">{P.achievements}</h2>
      <RangeForm from={f} to={t} />

      <StatGrid>
        <Stat label={P.recitations} value={tt.recitations} />
        <Stat label={P.recitingStudents} value={`${tt.reciting_students} / ${tt.students}`} />
        <Stat label={P.points} value={tt.points} />
        <Stat label={P.attendanceRate} value={pct(tt.attendance_rate)} />
        <Stat label={P.serdApproved} value={tt.serd_approved} />
        <Stat label={P.teacherDays} value={tt.teacher_days} />
      </StatGrid>

      <Panel title={P.students} className="mb-6" flush>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className={th}>#</th>
                <th className={th}>{P.colStudent}</th>
                <th className={th}>{P.colTotal}</th>
                <th className={th}>{P.parts}</th>
                <th className={th}>{P.colPeriod}</th>
                <th className={th}>{P.colPeriodPoints}</th>
                <th className={th}>{P.colAtt}</th>
                <th className={th}>{P.colLast}</th>
              </tr>
            </thead>
            <tbody>
              {r.students.map((s, i) => {
                const stale = !s.last_recited || Date.now() - new Date(s.last_recited).getTime() > 7 * 86400000;
                return (
                  <tr key={s.id} className={`border-t ${s.status !== 'active' ? 'text-gray-400' : ''}`}>
                    <td className={td}>{i + 1}</td>
                    <td className={td}>
                      <a href={`/students/${s.id}` as never} className="font-medium text-brand hover:underline">{s.name}</a>
                      <span className="text-xs text-gray-400"> · {s.code}</span>
                      {s.status !== 'active' && <> <Chip>{S.students.status[s.status] ?? s.status}</Chip></>}
                    </td>
                    <td className={td}>{s.total_points}</td>
                    <td className={td}>{s.parts_count ?? 0}</td>
                    <td className={td}>{s.recitations}</td>
                    <td className={td}>{s.points}</td>
                    <td className={td}>{pct(s.attendance_rate)}</td>
                    <td className={`${td} ${stale && s.status === 'active' ? 'text-amber-700' : ''}`}>{relDay(s.last_recited, P, lang)}</td>
                  </tr>
                );
              })}
              {!r.students.length && (
                <tr>
                  <td colSpan={8} className={`${td} py-6 text-center text-gray-400`}>{P.none}</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </Panel>

      <div className="mb-6 grid gap-4 lg:grid-cols-3">
        <Panel title={P.daily} className="lg:col-span-2">
          <DailyBars daily={r.daily} lang={lang} />
        </Panel>
        <Panel title={P.types}>
          <CountList items={r.by_type.map((b) => ({ label: T.labels.recitationType[b.type] ?? b.type, count: b.count }))} />
        </Panel>
      </div>

      <div className="mb-6 grid gap-4 lg:grid-cols-3">
        <Panel title={P.attendance}>
          <CountList items={(['present', 'late', 'absent', 'excused'] as const).map((k) => ({ label: T.labels.attendance[k], count: tt[k] }))} />
        </Panel>
        <Panel title={P.about} className="lg:col-span-2">
          <Facts
            rows={[
              [P.teacher, r.teacher ? <a href={`/teachers/${r.teacher.member_id}` as never} className="text-brand hover:underline">{r.teacher.name ?? '—'}</a> : null],
              [`${P.teacher} · ${P.phone}`, r.teacher?.phone ? <a href={`tel:${r.teacher.phone}`} dir="ltr" className="text-brand hover:underline">{r.teacher.phone}</a> : null],
              [P.stage, c.stage],
              [P.capacity, c.capacity],
              [P.created, fmtDay(c.created_at, lang)],
            ]}
          />
        </Panel>
      </div>

      <Panel title={P.recentInCircle} className="mb-6" flush>
        <RecitationTable rows={r.recent} labels={P} typeLabels={T.labels.recitationType} locale={locale} lang={lang} showStudent showBy empty={P.none} gradeLabels={grades} />
      </Panel>
    </div>
  );
}
