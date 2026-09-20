import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { ATT_LABELS, TYPE_LABELS, defaultRange, type CenterReport } from '@/lib/reports/format';

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
  if (!org.myPermissions.includes('reports')) return new Response('غير مصرّح', { status: 403 });

  const url = new URL(req.url);
  const range = defaultRange();
  const from = url.searchParams.get('from') || range.from;
  const to = url.searchParams.get('to') || range.to;

  const supabase = await createClient();
  const { data, error } = await supabase.rpc('center_report', { p_org: org.id, p_from: from, p_to: to });
  if (error || !data) return new Response(error?.message ?? 'تعذّر إنشاء التقرير', { status: 400 });
  const r = data as CenterReport;

  const rows: string[] = [
    line('تقرير المركز', org.name),
    line('من', r.from, 'إلى', r.to),
    '',
    line('الملخص'),
    line('الطلاب النشطون', r.totals.students_active),
    line('طلاب جدد', r.totals.new_students),
    line('التسميعات', r.totals.recitations),
    line('طلاب سمّعوا', r.totals.reciting_students),
    line('النقاط', r.totals.points),
    line('نسبة الحضور %', r.totals.attendance_rate),
    line('سرد معتمد', r.totals.serd_approved),
    line('متوسط السرد %', r.totals.serd_average),
    line('شهادات صدرت', r.totals.certificates),
    '',
    line('أنواع التسميع'),
    ...r.by_type.map((x) => line(TYPE_LABELS[x.type] ?? x.type, x.count)),
    '',
    line('الحضور'),
    line(ATT_LABELS.present, r.totals.attendance_present),
    line(ATT_LABELS.late, r.totals.attendance_late),
    line(ATT_LABELS.absent, r.totals.attendance_absent),
    line(ATT_LABELS.excused, r.totals.attendance_excused),
    '',
    line('الحلقات'),
    line('الحلقة', 'المعلم', 'الطلاب', 'التسميعات', 'النقاط', 'الحضور %'),
    ...r.circles.map((c) => line(c.name, c.teacher, c.students, c.recitations, c.points, c.attendance_rate)),
    '',
    line('المعلمون'),
    line('المعلم', 'التسميعات', 'النقاط'),
    ...r.teachers.map((t) => line(t.name, t.recitations, t.points)),
    '',
    line('الأعلى نقاطًا'),
    line('الطالب', 'الرقم', 'الحلقة', 'النقاط', 'التسميعات'),
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
