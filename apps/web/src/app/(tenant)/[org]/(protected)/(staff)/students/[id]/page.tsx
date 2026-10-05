import { RecitationList, recitationAudio, type Recitation } from '@/components/recitation-list';
import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { RangeForm } from '@/components/report-views';
import { ActionLink, Chip, CountList, Facts, Panel, ProfileHeader, RecitationTable, gradeLabelMap, Stat, StatGrid, relDay } from '@/components/profile-views';
import { addStudentNote } from '@/lib/insights/actions';
import { GoalCard, type GoalProgress } from '@/components/goal-card';
import { TodayReview, type ReviewPlan } from '@/components/review-plans';
import { defaultRange, fmtDay, pct, type StudentReport } from '@/lib/reports/format';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

interface StudentProfile {
  id: string;
  name: string;
  code: string;
  status: string;
  birth_date: string | null;
  phone: string | null;
  whatsapp: string | null;
  address: string | null;
  next_plan: string | null;
  joined: string;
  total_points: number;
  parts_count: number | null;
  saved_parts: number[] | null;
  circle: { id: string; name: string; stage: string | null } | null;
  teacher: { member_id: string; name: string | null } | null;
  guardian: { member_id: string; name: string | null; phone: string | null; email: string | null } | null;
  has_login: boolean;
  last_recited: string | null;
  recitations_total: number;
  rank: number | null;
  circle_size: number;
  last_days: { date: string; att: string | null; rec: number }[];
}

const STATUS_TONE: Record<string, 'green' | 'amber' | 'gray' | 'red'> = { active: 'green', paused: 'amber', graduated: 'gray', withdrawn: 'red' };

export default async function StudentProfilePage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ from?: string; to?: string; error?: string; ok?: string }>;
}) {
  const { org: slug, id } = await params;
  const { from, to, error, ok } = await searchParams;
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
  const [{ data: pData, error: pError }, { data: rData, error: rError }, { data: notesData }, { data: goalData }, { data: reviewData }] = await Promise.all([
    supabase.rpc('student_profile', { p_org: org.id, p_student: id }),
    supabase.rpc('student_report', { p_org: org.id, p_student: id, p_from: f, p_to: t }),
    supabase.rpc('list_student_notes', { p_org: org.id, p_student: id }),
    supabase.rpc('student_goal_progress', { p_org: org.id, p_student: id }),
    supabase.rpc('my_review_plan', { p_org: org.id, p_student: id }),
  ]);
  const goal = goalData as GoalProgress | null;
  // recorded recitations and mushaf tests (only for whoever may review this student; others get none)
  const { data: recData } = await supabase.rpc('student_recitations', { p_org: org.id, p_student: id, p_limit: 5 });
  const recorded = (recData ?? []) as Recitation[];
  const recordedAudio = await recitationAudio(recorded);
  const { data: gradeRows } = await supabase.from('recitation_grades').select('key, label').eq('organization_id', org.id).eq('is_active', true).order('sort_order');
  if (pError && /غير موجود|not found/i.test(pError.message)) notFound();
  const p = pData as StudentProfile | null;
  if (!p) return <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{pError?.message ?? P.notAllowed}</p>;
  const r = rData as StudentReport | null;
  const notes = (notesData ?? []) as { id: string; body: string; visibility: string; created_at: string; author: string | null }[];
  const age = p.birth_date ? Math.floor((Date.now() - new Date(p.birth_date).getTime()) / (365.25 * 86400000)) : null;
  const canEdit = org.myRole === 'admin' || org.myPermissions?.includes('students');
  const sep = T.labels.listSep;

  return (
    <div className="max-w-6xl">
      <ProfileHeader
        name={p.name}
        subtitle={
          <>
            {p.code}
            {p.circle && (
              <>
                {' · '}
                <a href={`/circles/${p.circle.id}` as never} className="text-brand hover:underline">{p.circle.name}</a>
              </>
            )}
            {p.teacher && (
              <>
                {' · '}
                <a href={`/teachers/${p.teacher.member_id}` as never} className="text-brand hover:underline">{p.teacher.name ?? '—'}</a>
              </>
            )}
          </>
        }
        chips={
          <>
            <Chip tone={STATUS_TONE[p.status] ?? 'gray'}>{S.students.status[p.status] ?? p.status}</Chip>
            {p.circle?.stage && <Chip>{p.circle.stage}</Chip>}
            {p.rank != null && <Chip tone="brand">{P.rank}: {fmt(P.rankV, { rank: p.rank, n: p.circle_size })}</Chip>}
          </>
        }
        actions={
          <>
            <ActionLink href={`/students/${p.id}/recitations`} primary>{P.recite}</ActionLink>
            <ActionLink href={`/students/${p.id}/report?from=${f}&to=${t}`}>{P.printReport}</ActionLink>
            <ActionLink href={`/students/${p.id}/weekly`}>{S.weekly.open}</ActionLink>
            {canEdit && <ActionLink href={`/students/${p.id}/edit`}>{P.edit}</ActionLink>}
          </>
        }
      />

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {ok && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{ok}</p>}

      <StatGrid>
        <Stat label={P.totalPoints} value={p.total_points} />
        <Stat label={P.parts} value={p.parts_count ?? 0} hint={p.saved_parts?.length ? [...p.saved_parts].sort((a, b) => a - b).join(sep) : undefined} />
        <Stat label={P.recitationsTotal} value={p.recitations_total} />
        <Stat label={P.lastRecited} value={<span className="text-lg">{relDay(p.last_recited, P, lang)}</span>} />
      </StatGrid>

      {goal && (
        <div className="mb-6">
          <GoalCard g={goal} orgId={org.id} studentId={p.id} back={`/students/${p.id}`} edit />
          <div className="mt-3">
            <TodayReview plan={reviewData as ReviewPlan | null} />
          </div>
        </div>
      )}

      <div className="mb-6 grid gap-4 lg:grid-cols-3">
        <Panel title={P.about}>
          <Facts
            rows={[
              [P.birth, p.birth_date ? `${fmtDay(p.birth_date, lang)}${age != null ? ` (${fmt(P.ageN, { n: age })})` : ''}` : null],
              [P.joined, fmtDay(p.joined, lang)],
              [P.circle, p.circle ? <a href={`/circles/${p.circle.id}` as never} className="text-brand hover:underline">{p.circle.name}</a> : P.noCircle],
              [P.teacher, p.teacher ? <a href={`/teachers/${p.teacher.member_id}` as never} className="text-brand hover:underline">{p.teacher.name ?? '—'}</a> : null],
              [P.login, p.has_login ? P.yes : P.no],
            ]}
          />
        </Panel>
        <Panel title={P.contact}>
          <Facts
            rows={[
              [P.phone, p.phone ? <a href={`tel:${p.phone}`} dir="ltr" className="text-brand hover:underline">{p.phone}</a> : null],
              [P.whatsapp, p.whatsapp ? <a href={`https://wa.me/${p.whatsapp.replace(/\D/g, '')}`} target="_blank" rel="noreferrer" dir="ltr" className="text-brand hover:underline">{p.whatsapp}</a> : null],
              [P.address, p.address],
              [P.guardian, p.guardian ? p.guardian.name ?? p.guardian.email : P.noGuardian],
              ...(p.guardian?.phone ? [[`${P.guardian} · ${P.phone}`, <a key="g" href={`tel:${p.guardian.phone}`} dir="ltr" className="text-brand hover:underline">{p.guardian.phone}</a>] as [string, React.ReactNode]] : []),
            ]}
          />
        </Panel>
        <Panel title={P.plan}>
          <p className={`whitespace-pre-wrap text-sm ${p.next_plan ? '' : 'text-gray-400'}`}>{p.next_plan || P.noPlan}</p>
          <h3 className="mb-2 mt-4 text-xs font-semibold text-gray-500">{P.last14}</h3>
          <div className="flex gap-1">
            {p.last_days.map((d) => {
              const color = d.rec > 0 ? 'bg-brand' : d.att === 'present' || d.att === 'late' ? 'bg-green-300' : d.att === 'absent' ? 'bg-red-300' : d.att === 'excused' ? 'bg-amber-200' : 'bg-gray-100';
              return (
                <div
                  key={d.date}
                  title={`${fmtDay(d.date, lang)}${d.att ? ` · ${T.labels.attendance[d.att] ?? d.att}` : ''}${d.rec ? ` · ${P.legendRec} ${d.rec}` : ''}`}
                  className={`h-7 flex-1 rounded ${color}`}
                />
              );
            })}
          </div>
          <div className="mt-2 flex flex-wrap gap-3 text-[11px] text-gray-500">
            <span className="flex items-center gap-1"><i className="inline-block h-2.5 w-2.5 rounded bg-brand" />{P.legendRec}</span>
            <span className="flex items-center gap-1"><i className="inline-block h-2.5 w-2.5 rounded bg-green-300" />{P.legendPresent}</span>
            <span className="flex items-center gap-1"><i className="inline-block h-2.5 w-2.5 rounded bg-red-300" />{P.legendAbsent}</span>
            <span className="flex items-center gap-1"><i className="inline-block h-2.5 w-2.5 rounded bg-gray-100" />{P.legendNone}</span>
          </div>
        </Panel>
      </div>

      {recorded.length > 0 && (
        <section className="mb-6">
          <div className="mb-3 flex items-center justify-between">
            <h2 className="text-lg font-bold">{T.quran.recite.inboxTitle}</h2>
            <a href="/recitations" className="text-sm text-brand hover:underline">
              {T.quran.recite.pending}
            </a>
          </div>
          <RecitationList
            items={recorded}
            audio={recordedAudio}
            mode="staff"
            grades={(gradeRows ?? []) as { key: string; label: string }[]}
            typeLabels={T.labels.recitationType}
            locale={locale}
            R={T.quran.recite}
          />
        </section>
      )}

      <h2 className="mb-3 text-lg font-bold">{P.achievements}</h2>
      <RangeForm from={f} to={t} />
      {rError && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{rError.message}</p>}
      {r && (
        <>
          <StatGrid>
            <Stat label={P.recitations} value={r.recitations.count} />
            <Stat label={P.points} value={r.recitations.points} />
            <Stat label={P.attendanceRate} value={pct(r.attendance.rate)} />
            <Stat label={P.serdApproved} value={r.serd.filter((s) => s.status === 'approved').length} />
          </StatGrid>
          <div className="mb-6 grid gap-4 lg:grid-cols-3">
            <Panel title={P.types}>
              <CountList items={r.recitations.by_type.map((x) => ({ label: T.labels.recitationType[x.type] ?? x.type, count: x.count }))} />
            </Panel>
            <Panel title={P.attendance}>
              <CountList
                items={(['present', 'late', 'absent', 'excused'] as const).map((k) => ({ label: T.labels.attendance[k], count: r.attendance[k] }))}
              />
            </Panel>
            <Panel title={`${T.report.badges.replace(/[:：]\s*$/, '')} · ${T.report.certificates.replace(/[:：]\s*$/, '')}`}>
              {r.badges.length === 0 && r.certificates.length === 0 && <p className="text-sm text-gray-400">—</p>}
              <div className="flex flex-wrap gap-2">
                {r.badges.map((b, i) => (
                  <Chip key={i} tone="amber">🏅 {b.name}</Chip>
                ))}
              </div>
              {r.certificates.length > 0 && (
                <ul className="mt-3 flex flex-col gap-1 text-sm">
                  {r.certificates.map((c) => (
                    <li key={c.id}>
                      📜 <a href={`/certificates/${c.id}` as never} className="text-brand hover:underline">{c.title}</a>
                      <span className="text-xs text-gray-400"> · {fmtDay(c.at, lang)}</span>
                    </li>
                  ))}
                </ul>
              )}
            </Panel>
          </div>

          {r.serd.length > 0 && (
            <Panel title={T.report.serd.replace(/[:：]\s*$/, '')} className="mb-6" flush>
              <table className="w-full text-sm">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-3 py-2 text-start">{P.colDate}</th>
                    <th className="px-3 py-2 text-start">{P.colJuz}</th>
                    <th className="px-3 py-2 text-start">{P.colScore}</th>
                    <th className="px-3 py-2 text-start">{P.status}</th>
                  </tr>
                </thead>
                <tbody>
                  {r.serd.map((q, i) => (
                    <tr key={i} className="border-t">
                      <td className="px-3 py-2">{fmtDay(q.date, lang)}</td>
                      <td className="px-3 py-2">{q.juz.join(sep)}</td>
                      <td className="px-3 py-2">{q.score != null ? `${q.score}%` : '—'}</td>
                      <td className="px-3 py-2">{T.labels.serdStatus[q.status === 'approved' || q.status === 'rejected' ? q.status : 'submitted']}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </Panel>
          )}

          <Panel title={T.report.log} className="mb-6" flush>
            <RecitationTable rows={r.recitations.rows} labels={P} typeLabels={T.labels.recitationType} locale={locale} lang={lang} empty={P.none} gradeLabels={grades} />
          </Panel>
        </>
      )}

      <Panel title={S.students.notes}>
        <p className="mb-3 text-xs text-gray-500">{S.students.notesHint}</p>
        <form action={addStudentNote} className="mb-4 flex flex-col gap-2">
          <input type="hidden" name="orgId" value={org.id} />
          <input type="hidden" name="studentId" value={p.id} />
          <input type="hidden" name="back" value={`/students/${p.id}`} />
          <textarea name="body" required maxLength={1000} rows={2} placeholder={S.students.notePh} className="w-full rounded border px-3 py-2 text-sm" />
          <div className="flex items-center gap-3">
            <select name="visibility" className="rounded border px-2 py-1.5 text-sm">
              <option value="staff_only">{S.students.staffOnly}</option>
              <option value="guardian_visible">{S.students.guardianVisible}</option>
            </select>
            <SubmitButton className="rounded bg-brand px-4 py-1.5 text-sm text-white" pendingText="...">{S.common.add}</SubmitButton>
          </div>
        </form>
        <ul className="flex flex-col gap-2 text-sm">
          {notes.map((n) => (
            <li key={n.id} className="rounded bg-gray-50 p-3">
              <p className="whitespace-pre-wrap">{n.body}</p>
              <p className="mt-1 text-xs text-gray-400">
                {n.author ?? '—'} · {fmtDay(n.created_at, lang)}
                {n.visibility === 'guardian_visible' ? ` · ${S.students.guardianVisible}` : ''}
              </p>
            </li>
          ))}
          {!notes.length && <li className="text-gray-400">{S.students.noNotes}</li>}
        </ul>
      </Panel>
    </div>
  );
}
