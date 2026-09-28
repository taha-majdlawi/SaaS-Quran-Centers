import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { defaultRange, type CenterReport } from '@/lib/reports/format';
import { getI18n } from '@/lib/i18n/server';

// A cell that starts with = + - @ would be run as a formula by Excel; quote it.
const cell = (v: unknown) => {
  let s = v == null ? '' : String(v);
  if (/^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  return `"${s.replace(/"/g, '""')}"`;
};
const line = (...cols: unknown[]) => cols.map(cell).join(',');

export async function GET(req: Request, { params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const R = T.staff.centerReport;
  if (!org.myPermissions.includes('reports')) return new Response(T.staff.common.forbidden, { status: 403 });

  const url = new URL(req.url);
  const range = defaultRange();
  const from = url.searchParams.get('from') || range.from;
  const to = url.searchParams.get('to') || range.to;

  const supabase = await createClient();
  const { data, error } = await supabase.rpc('center_report', { p_org: org.id, p_from: from, p_to: to });
  if (error || !data) return new Response(error?.message ?? R.failed, { status: 400 });
  const r = data as CenterReport;

  const rows: string[] = [
    line(R.title, org.name),
    line(R.from, r.from, R.to, r.to),
    '',
    line(R.summary),
    line(R.activeStudents, r.totals.students_active),
    line(R.newStudents, r.totals.new_students),
    line(R.recitations, r.totals.recitations),
    line(R.recitingStudents, r.totals.reciting_students),
    line(R.points, r.totals.points),
    line(R.attendanceRatePct, r.totals.attendance_rate),
    line(R.serdApproved, r.totals.serd_approved),
    line(R.serdAveragePct, r.totals.serd_average),
    line(R.certsIssued, r.totals.certificates),
    '',
    line(R.types),
    ...r.by_type.map((x) => line(T.labels.recitationType[x.type] ?? x.type, x.count)),
    '',
    line(R.attendance),
    line(T.labels.attendance.present, r.totals.attendance_present),
    line(T.labels.attendance.late, r.totals.attendance_late),
    line(T.labels.attendance.absent, r.totals.attendance_absent),
    line(T.labels.attendance.excused, r.totals.attendance_excused),
    '',
    line(R.circles),
    line(R.colCircle, R.colTeacher, R.colStudents, R.recitations, R.points, R.colAttendancePct),
    ...r.circles.map((c) => line(c.name, c.teacher, c.students, c.recitations, c.points, c.attendance_rate)),
    '',
    line(R.teachers),
    line(R.colTeacher, R.recitations, R.points),
    ...r.teachers.map((t) => line(t.name, t.recitations, t.points)),
    '',
    line(R.top),
    line(R.colStudent, R.colCode, R.colCircle, R.points, R.recitations),
    ...r.top_students.map((s) => line(s.name, s.code, s.circle, s.points, s.recitations)),
  ];

  // BOM so Excel reads the Arabic as UTF-8
  return new Response('﻿' + rows.join('\r\n'), {
    headers: {
      'Content-Type': 'text/csv; charset=utf-8',
      'Content-Disposition': `attachment; filename="report-${from}_${to}.csv"`,
    },
  });
}
