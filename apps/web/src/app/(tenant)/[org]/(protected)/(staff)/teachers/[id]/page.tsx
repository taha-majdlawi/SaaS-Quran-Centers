import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { RangeForm } from '@/components/report-views';
import { ActionLink, Chip, CountList, DailyBars, Facts, Panel, ProfileHeader, Delta, RecitationTable, gradeLabelMap, Stat, StatGrid, relDay, type RecRow } from '@/components/profile-views';
import { defaultRange, fmtDay, pct, previousRange } from '@/lib/reports/format';
import { getI18n } from '@/lib/i18n/server';

interface TeacherProfile {
  from: string;
  to: string;
  teacher: {
    member_id: string;
    user_id: string;
    role: string;
    status: string;
    joined: string;
    name: string | null;
    phone: string | null;
    email: string | null;
    last_active: string | null;
  };
  circles: { id: string; name: string; status: string; kind: 'primary' | 'assistant'; stage: string | null; students: number; recitations: number; points: number; attendance_rate: number | null }[];
  totals: { students: number; recitations: number; reciting_students: number; points: number; serd: number; present: number; late: number; absent: number; excused: number };
  by_type: { type: string; count: number }[];
  daily: { date: string; recitations: number }[];
  recent: RecRow[];
  attendance: { date: string; circle: string; status: string; checked_in_at: string | null; note: string | null; set_by_admin: boolean }[];
  serd: { date: string; student_id: string | null; student: string; juz: number[]; score: number | null; status: string }[];
}

const td = 'px-3 py-2';
const th = 'px-3 py-2 text-start font-semibold';

export default async function TeacherProfilePage({
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
  const [{ data, error }, { data: prevData }, { data: me }] = await Promise.all([
    supabase.rpc('teacher_profile', { p_org: org.id, p_id: id, p_from: f, p_to: t }),
    supabase.rpc('teacher_profile', { p_org: org.id, p_id: id, p_from: previousRange(f, t).from, p_to: previousRange(f, t).to }),
    supabase.auth.getUser(),
  ]);
  if (error && /غير موجود|not found/i.test(error.message)) notFound();
  const r = data as TeacherProfile | null;
  if (!r) return <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error?.message ?? P.notAllowed}</p>;
  const x = r.teacher;
  const tt = r.totals;
  const pt = (prevData as { totals: typeof r.totals } | null)?.totals;
  const C = S.compare;
  const isAdmin = org.myRole === 'admin';
  const ATT: Record<string, string> = S.teachers.attStatus;
  const attTone = (s: string) => (s === 'present' ? 'green' : s === 'late' ? 'amber' : s === 'absent' ? 'red' : 'gray') as 'green' | 'amber' | 'red' | 'gray';
  const sep = T.labels.listSep;

  return (
    <div className="max-w-6xl">
      <ProfileHeader
        name={x.name ?? x.email ?? '—'}
        subtitle={
          <>
            {T.shell.roles[x.role] ?? x.role}
            {r.circles.length > 0 && (
              <>
                {' · '}
                {r.circles.map((c, i) => (
                  <span key={c.id}>
                    {i > 0 && sep}
                    <a href={`/circles/${c.id}` as never} className="text-brand hover:underline">{c.name}</a>
                  </span>
                ))}
              </>
            )}
          </>
        }
        chips={
          <>
            <Chip tone={x.status === 'active' ? 'green' : 'red'}>{S.teachers.memberStatus[x.status] ?? x.status}</Chip>
            <Chip>{P.lastActive}: {relDay(x.last_active, P, lang)}</Chip>
          </>
        }
        actions={
          <>
            {me.user?.id !== x.user_id && <ActionLink href={`/chat/${x.user_id}`} primary>{P.message}</ActionLink>}
            {isAdmin && <ActionLink href={`/teachers/${x.member_id}/edit`}>{P.edit}</ActionLink>}
          </>
        }
      />

      <div className="mb-6 grid gap-4 lg:grid-cols-3">
        <Panel title={P.contact}>
          <Facts
            rows={[
              [P.email, x.email ? <a href={`mailto:${x.email}`} dir="ltr" className="text-brand hover:underline">{x.email}</a> : null],
              [P.phone, x.phone ? <a href={`tel:${x.phone}`} dir="ltr" className="text-brand hover:underline">{x.phone}</a> : null],
              [P.joined, fmtDay(x.joined, lang)],
              [P.lastActive, x.last_active ? fmtDay(x.last_active, lang) : P.never],
            ]}
          />
        </Panel>
        <Panel title={P.circles} className="lg:col-span-2" flush>
          <table className="w-full text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className={th}>{P.colCircle}</th>
                <th className={th}>{P.stage}</th>
                <th className={th}>{P.students}</th>
                <th className={th}>{P.colPeriod}</th>
                <th className={th}>{P.attendanceRate}</th>
              </tr>
            </thead>
            <tbody>
              {r.circles.map((c) => (
                <tr key={c.id} className="border-t">
                  <td className={td}>
                    <a href={`/circles/${c.id}` as never} className="font-medium text-brand hover:underline">{c.name}</a>{' '}
                    {c.kind === 'assistant' && <Chip>{P.assistant}</Chip>}
                  </td>
                  <td className={td}>{c.stage ?? '—'}</td>
                  <td className={td}>{c.students}</td>
                  <td className={td}>{c.recitations}</td>
                  <td className={td}>{pct(c.attendance_rate)}</td>
                </tr>
              ))}
              {!r.circles.length && (
                <tr>
                  <td colSpan={5} className={`${td} py-6 text-center text-gray-400`}>{P.noCircles}</td>
                </tr>
              )}
            </tbody>
          </table>
        </Panel>
      </div>

      <h2 className="mb-3 text-lg font-bold">{P.achievements}</h2>
      <RangeForm from={f} to={t} />

      <StatGrid>
        <Stat label={P.students} value={tt.students} />
        <Stat label={P.recitations} value={tt.recitations} change={pt && <Delta now={tt.recitations} prev={pt.recitations} labels={C} />} />
        <Stat label={P.recitingStudents} value={tt.reciting_students} change={pt && <Delta now={tt.reciting_students} prev={pt.reciting_students} labels={C} />} />
        <Stat label={P.points} value={tt.points} change={pt && <Delta now={tt.points} prev={pt.points} labels={C} />} />
        <Stat label={P.serdExamined} value={tt.serd} change={pt && <Delta now={tt.serd} prev={pt.serd} labels={C} />} />
        <Stat label={P.daysPresent} value={tt.present + tt.late} hint={tt.absent ? `${ATT.absent}: ${tt.absent}` : undefined} />
      </StatGrid>

      <div className="mb-6 grid gap-4 lg:grid-cols-3">
        <Panel title={P.daily} className="lg:col-span-2">
          <DailyBars daily={r.daily} lang={lang} />
        </Panel>
        <Panel title={P.types}>
          <CountList items={r.by_type.map((b) => ({ label: T.labels.recitationType[b.type] ?? b.type, count: b.count }))} />
        </Panel>
      </div>

      <Panel title={P.recentByTeacher} className="mb-6" flush>
        <RecitationTable rows={r.recent} labels={P} typeLabels={T.labels.recitationType} locale={locale} lang={lang} showStudent empty={P.none} gradeLabels={grades} />
      </Panel>

      <div className="mb-6 grid gap-4 lg:grid-cols-2">
        <Panel title={P.teacherAttendance} flush>
          <ul className="divide-y text-sm">
            {r.attendance.map((a, i) => (
              <li key={i} className="flex items-center justify-between gap-2 px-4 py-2">
                <span>
                  {fmtDay(a.date, lang)} · {a.circle}
                  {a.note && <span className="text-xs text-gray-400"> · {a.note}</span>}
                </span>
                <span className="flex items-center gap-2 text-xs text-gray-500">
                  {a.checked_in_at && P.checkedIn.replace('{time}', new Date(a.checked_in_at).toLocaleTimeString(lang, { hour: '2-digit', minute: '2-digit' }))}
                  {a.set_by_admin && <span>{P.byAdmin}</span>}
                  <Chip tone={attTone(a.status)}>{ATT[a.status] ?? a.status}</Chip>
                </span>
              </li>
            ))}
            {!r.attendance.length && <li className="px-4 py-6 text-center text-gray-400">{P.none}</li>}
          </ul>
        </Panel>
        <Panel title={P.serdTitle} flush>
          <ul className="divide-y text-sm">
            {r.serd.map((q, i) => (
              <li key={i} className="flex items-center justify-between gap-2 px-4 py-2">
                <span>
                  {fmtDay(q.date, lang)} ·{' '}
                  {q.student_id ? <a href={`/students/${q.student_id}` as never} className="text-brand hover:underline">{q.student}</a> : q.student}
                  <span className="text-xs text-gray-400"> · {q.juz.join(sep)}</span>
                </span>
                <span className="text-xs text-gray-500">
                  {q.score != null ? `${q.score}%` : '—'} · {T.labels.serdStatus[q.status === 'approved' || q.status === 'rejected' ? q.status : 'submitted']}
                </span>
              </li>
            ))}
            {!r.serd.length && <li className="px-4 py-6 text-center text-gray-400">{P.none}</li>}
          </ul>
        </Panel>
      </div>
    </div>
  );
}
