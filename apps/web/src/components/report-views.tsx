import { surahLabel } from '@/lib/quran/data';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';
import { PrintButton } from '@/components/print-button';
import { fmtDay, pct, type CenterReport, type StudentReport } from '@/lib/reports/format';
import { Delta } from '@/components/profile-views';

const field = 'rounded border px-3 py-2 text-sm';

export async function RangeForm({ from, to, extra }: { from: string; to: string; extra?: React.ReactNode }) {
  const { t } = await getI18n();
  return (
    <form className="mb-6 flex flex-wrap items-end gap-3 print:hidden">
      {extra}
      <label className="text-sm text-gray-700">
        {t.report.from}
        <input type="date" name="from" defaultValue={from} className={`mt-1 block ${field}`} />
      </label>
      <label className="text-sm text-gray-700">
        {t.report.to}
        <input type="date" name="to" defaultValue={to} className={`mt-1 block ${field}`} />
      </label>
      <button className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">{t.report.show}</button>
    </form>
  );
}

function Kpi({ label, value, change }: { label: string; value: React.ReactNode; change?: React.ReactNode }) {
  return (
    <div className="rounded-lg border bg-white p-4">
      <p className="text-xs text-gray-500">{label}</p>
      <p className="flex flex-wrap items-baseline gap-2 text-2xl font-bold text-brand">
        {value}
        {change}
      </p>
    </div>
  );
}

const th = 'px-3 py-2 text-start font-semibold';
const td = 'px-3 py-2';

export async function CenterReportView({ r, exportHref, prev }: { r: CenterReport; exportHref: string; prev?: CenterReport | null }) {
  const { t: T } = await getI18n();
  const R = T.staff.centerReport;
  const C = T.staff.compare;
  const lang = T.labels.dateLocale;
  const t = r.totals;
  const p = prev?.totals;
  const ch = (k: keyof CenterReport['totals'], points?: boolean) => (p ? <Delta now={t[k]} prev={p[k]} points={points} labels={C} /> : null);
  const prevCircle = new Map((prev?.circles ?? []).map((c) => [c.id, c]));
  const prevTeacher = new Map((prev?.teachers ?? []).map((x) => [x.id, x]));
  const max = Math.max(1, ...r.daily.map((d) => d.recitations));
  return (
    <div>
      <div className="mb-4 flex flex-wrap items-center gap-3 print:hidden">
        <a href={exportHref as never} className="rounded border px-4 py-2 text-sm hover:bg-gray-50">
          {R.exportCsv}
        </a>
        <PrintButton label={T.report.print} />
      </div>
      <p className="mb-4 text-sm text-gray-500">
        {fmt(R.period, { from: fmtDay(r.from, lang), to: fmtDay(r.to, lang) })}
        {prev && <span className="block text-xs text-gray-400">{fmt(C.vs, { from: fmtDay(prev.from, lang), to: fmtDay(prev.to, lang) })}</span>}
      </p>

      <div className="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
        <Kpi label={R.activeStudents} value={t.students_active} change={ch('students_active')} />
        <Kpi label={R.newStudents} value={t.new_students} change={ch('new_students')} />
        <Kpi label={R.recitations} value={t.recitations} change={ch('recitations')} />
        <Kpi label={R.recitingStudents} value={t.reciting_students} change={ch('reciting_students')} />
        <Kpi label={R.points} value={t.points} change={ch('points')} />
        <Kpi label={R.attendanceRate} value={pct(t.attendance_rate)} change={ch('attendance_rate', true)} />
        <Kpi label={R.serdApproved} value={`${t.serd_approved}${t.serd_average != null ? ` · ${t.serd_average}%` : ''}`} change={ch('serd_approved')} />
        <Kpi label={R.certsIssued} value={t.certificates} change={ch('certificates')} />
      </div>

      <div className="mb-6 grid gap-4 sm:grid-cols-2">
        <section className="rounded-lg border bg-white p-4">
          <h2 className="mb-2 text-sm font-semibold">{R.types}</h2>
          {r.by_type.length ? (
            <ul className="flex flex-col gap-1 text-sm">
              {r.by_type.map((x) => (
                <li key={x.type} className="flex justify-between">
                  <span>{T.labels.recitationType[x.type] ?? x.type}</span>
                  <b>{x.count}</b>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-gray-400">—</p>
          )}
        </section>
        <section className="rounded-lg border bg-white p-4">
          <h2 className="mb-2 text-sm font-semibold">{R.attendance}</h2>
          <ul className="flex flex-col gap-1 text-sm">
            {[
              ['present', t.attendance_present],
              ['late', t.attendance_late],
              ['absent', t.attendance_absent],
              ['excused', t.attendance_excused],
            ].map(([k, n]) => (
              <li key={k} className="flex justify-between">
                <span>{T.labels.attendance[k as string]}</span>
                <b>{n}</b>
              </li>
            ))}
          </ul>
        </section>
      </div>

      {r.daily.length > 0 && (
        <section className="mb-6 rounded-lg border bg-white p-4">
          <h2 className="mb-3 text-sm font-semibold">{R.daily}</h2>
          <div className="flex h-24 items-end gap-1">
            {r.daily.map((d) => (
              <div key={d.date} className="flex h-full flex-1 flex-col items-center justify-end" title={`${fmtDay(d.date, lang)}: ${d.recitations}`}>
                <div className="w-full min-w-1 rounded-t bg-brand" style={{ height: `${(d.recitations / max) * 100}%` }} />
              </div>
            ))}
          </div>
        </section>
      )}

      <section className="mb-6 overflow-x-auto rounded-lg border bg-white">
        <h2 className="border-b px-4 py-2 text-sm font-semibold">{R.circles}</h2>
        <table className="w-full text-sm">
          <thead className="bg-gray-50">
            <tr>
              <th className={th}>{R.colCircle}</th>
              <th className={th}>{R.colTeacher}</th>
              <th className={th}>{R.colStudents}</th>
              <th className={th}>{R.recitations}</th>
              <th className={th}>{R.points}</th>
              <th className={th}>{R.attendance}</th>
              {prev && <th className={th}>{C.colChange}</th>}
            </tr>
          </thead>
          <tbody>
            {r.circles.map((c) => (
              <tr key={c.id} className="border-t">
                <td className={td}><a href={`/circles/${c.id}` as never} className="text-brand hover:underline">{c.name}</a></td>
                <td className={td}>{c.teacher ?? '—'}</td>
                <td className={td}>{c.students}</td>
                <td className={td}>{c.recitations}</td>
                <td className={td}>{c.points}</td>
                <td className={td}>{pct(c.attendance_rate)}</td>
                {prev && (
                  <td className={td}>
                    <Delta now={c.recitations} prev={prevCircle.get(c.id)?.recitations ?? 0} labels={C} />
                  </td>
                )}
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <div className="grid gap-4 sm:grid-cols-2">
        <section className="overflow-x-auto rounded-lg border bg-white">
          <h2 className="border-b px-4 py-2 text-sm font-semibold">{R.teachersLogged}</h2>
          <table className="w-full text-sm">
            <tbody>
              {r.teachers.map((x, i) => (
                <tr key={x.id ?? i} className="border-t first:border-0">
                  <td className={td}>{x.id ? <a href={`/teachers/${x.id}` as never} className="text-brand hover:underline">{x.name ?? '—'}</a> : x.name ?? '—'}</td>
                  <td className={td}>{x.recitations}</td>
                  <td className={td}>{fmt(R.pointsN, { n: x.points })}</td>
                  {prev && (
                    <td className={td}>
                      <Delta now={x.recitations} prev={prevTeacher.get(x.id)?.recitations ?? 0} labels={C} />
                    </td>
                  )}
                </tr>
              ))}
              {!r.teachers.length && (
                <tr>
                  <td className={`${td} text-gray-400`}>—</td>
                </tr>
              )}
            </tbody>
          </table>
        </section>
        <section className="overflow-x-auto rounded-lg border bg-white">
          <h2 className="border-b px-4 py-2 text-sm font-semibold">{R.top}</h2>
          <table className="w-full text-sm">
            <tbody>
              {r.top_students.map((s, i) => (
                <tr key={s.id} className="border-t first:border-0">
                  <td className={td}>{i + 1}</td>
                  <td className={td}>
                    <a href={`/students/${s.id}` as never} className="text-brand hover:underline">
                      {s.name}
                    </a>
                    <span className="text-xs text-gray-400"> · {s.circle ?? '—'}</span>
                  </td>
                  <td className={td}>{s.points}</td>
                </tr>
              ))}
              {!r.top_students.length && (
                <tr>
                  <td className={`${td} text-gray-400`}>—</td>
                </tr>
              )}
            </tbody>
          </table>
        </section>
      </div>
    </div>
  );
}

const ayahRange = (row: StudentReport['recitations']['rows'][number], locale: string) => {
  if (row.surah_from == null) return '—';
  const a = surahLabel(row.surah_from, locale);
  if (row.surah_to == null || row.surah_to === row.surah_from) return `${a} (${row.ayah_from}–${row.ayah_to})`;
  return `${a} ${row.ayah_from} ${locale === 'ar' ? '←' : '→'} ${surahLabel(row.surah_to, locale)} ${row.ayah_to}`;
};

export async function StudentReportView({ r, certificatesBase }: { r: StudentReport; certificatesBase: string }) {
  const { t, locale } = await getI18n();
  const L = t.report;
  const lang = t.labels.dateLocale;
  const sep = t.labels.listSep;
  const s = r.student;
  return (
    <div>
      <div className="mb-4 flex items-center justify-between gap-3">
        <div>
          <h2 className="text-xl font-bold">{s.name}</h2>
          <p className="text-sm text-gray-500">
            {s.code}
            {s.circle && <> · {s.circle}</>}
            {s.teacher && <> · {fmt(L.teacher, { name: s.teacher })}</>}
          </p>
          <p className="text-xs text-gray-400">
            {fmt(L.period, { from: fmtDay(r.from, lang), to: fmtDay(r.to, lang) })}
          </p>
        </div>
        <PrintButton label={L.print} />
      </div>

      <div className="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
        <Kpi label={L.periodRecitations} value={r.recitations.count} />
        <Kpi label={L.periodPoints} value={r.recitations.points} />
        <Kpi label={L.attendance} value={pct(r.attendance.rate)} />
        <Kpi label={L.totalPoints} value={s.total_points} />
      </div>

      <div className="mb-6 grid gap-4 sm:grid-cols-2">
        <section className="rounded-lg border bg-white p-4 text-sm">
          <h3 className="mb-2 font-semibold">{L.attendance}</h3>
          <ul className="flex flex-col gap-1">
            {(['present', 'late', 'absent', 'excused'] as const).map((k) => (
              <li key={k} className="flex justify-between">
                <span>{t.labels.attendance[k]}</span>
                <b>{r.attendance[k]}</b>
              </li>
            ))}
          </ul>
        </section>
        <section className="rounded-lg border bg-white p-4 text-sm">
          <h3 className="mb-2 font-semibold">{L.progress}</h3>
          <p>
            {L.savedParts} <b>{s.parts_count ?? 0}</b>
          </p>
          {s.saved_parts && s.saved_parts.length > 0 && <p className="text-xs text-gray-500">({[...s.saved_parts].sort((a, b) => a - b).join(sep)})</p>}
          <ul className="mt-2 flex flex-col gap-1">
            {r.recitations.by_type.map((x) => (
              <li key={x.type} className="flex justify-between">
                <span>{t.labels.recitationType[x.type] ?? x.type}</span>
                <b>{x.count}</b>
              </li>
            ))}
          </ul>
        </section>
      </div>

      {r.serd.length > 0 && (
        <section className="mb-6 rounded-lg border bg-white p-4 text-sm">
          <h3 className="mb-2 font-semibold">{L.serd}</h3>
          <ul className="flex flex-col gap-1">
            {r.serd.map((q, i) => (
              <li key={i} className="flex justify-between">
                <span>
                  {fmtDay(q.date, lang)} · {fmt(t.labels.juz, { n: q.juz.join(sep) })}
                </span>
                <span>
                  {q.score != null ? `${q.score}%` : '—'} · {t.labels.serdStatus[q.status === 'approved' || q.status === 'rejected' ? q.status : 'submitted']}
                </span>
              </li>
            ))}
          </ul>
        </section>
      )}

      {(r.badges.length > 0 || r.certificates.length > 0) && (
        <section className="mb-6 rounded-lg border bg-white p-4 text-sm">
          {r.badges.length > 0 && (
            <p className="mb-2">
              <b>{L.badges}</b>
              {r.badges.map((b) => b.name).join(sep)}
            </p>
          )}
          {r.certificates.length > 0 && (
            <p>
              <b>{L.certificates}</b>
              {r.certificates.map((c, i) => (
                <span key={c.id}>
                  {i > 0 && sep}
                  <a href={`${certificatesBase}/${c.id}` as never} className="text-brand hover:underline">
                    {c.title}
                  </a>
                </span>
              ))}
            </p>
          )}
        </section>
      )}

      <section className="overflow-x-auto rounded-lg border bg-white">
        <h3 className="border-b px-4 py-2 text-sm font-semibold">{L.log}</h3>
        <table className="w-full text-sm">
          <thead className="bg-gray-50">
            <tr>
              <th className={th}>{L.colDate}</th>
              <th className={th}>{L.colType}</th>
              <th className={th}>{L.colPassage}</th>
              <th className={th}>{L.colGrade}</th>
              <th className={th}>{L.colPoints}</th>
            </tr>
          </thead>
          <tbody>
            {r.recitations.rows.map((x, i) => (
              <tr key={i} className="border-t">
                <td className={td}>{fmtDay(x.at, lang)}</td>
                <td className={td}>{t.labels.recitationType[x.type] ?? x.type}</td>
                <td className={td}>{ayahRange(x, locale)}</td>
                <td className={td}>{x.grade ?? '—'}</td>
                <td className={td}>{x.points}</td>
              </tr>
            ))}
            {!r.recitations.rows.length && (
              <tr>
                <td colSpan={5} className={`${td} text-center text-gray-400`}>
                  {L.none}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </section>
    </div>
  );
}
