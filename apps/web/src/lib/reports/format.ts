export const TYPE_LABELS: Record<string, string> = {
  new_memorization: 'حفظ جديد',
  recent_review: 'مراجعة قريبة',
  distant_review: 'مراجعة بعيدة',
};

export const ATT_LABELS: Record<string, string> = {
  present: 'حاضر',
  late: 'متأخر',
  absent: 'غائب',
  excused: 'مستأذن',
};

export const CERT_KIND_LABELS: Record<string, string> = {
  serd: 'السرد القرآني',
  memorization: 'إتمام حفظ',
  excellence: 'تفوّق',
  attendance: 'انتظام',
  custom: 'مخصّصة',
};

export interface CenterReport {
  from: string;
  to: string;
  totals: {
    students_active: number;
    new_students: number;
    recitations: number;
    points: number;
    reciting_students: number;
    attendance_present: number;
    attendance_late: number;
    attendance_absent: number;
    attendance_excused: number;
    attendance_rate: number | null;
    serd_approved: number;
    serd_average: number | null;
    certificates: number;
  };
  by_type: { type: string; count: number }[];
  circles: { id: string; name: string; teacher: string | null; students: number; recitations: number; points: number; attendance_rate: number | null }[];
  teachers: { id: string | null; name: string | null; recitations: number; points: number }[];
  top_students: { id: string; name: string; code: string; circle: string | null; points: number; recitations: number }[];
  daily: { date: string; recitations: number }[];
}

export interface StudentReport {
  from: string;
  to: string;
  student: {
    id: string;
    name: string;
    code: string;
    status: string;
    circle: string | null;
    teacher: string | null;
    total_points: number;
    parts_count: number | null;
    saved_parts: number[] | null;
    joined: string;
  };
  recitations: {
    count: number;
    points: number;
    by_type: { type: string; count: number }[];
    rows: { at: string; type: string; surah_from: number | null; ayah_from: number | null; surah_to: number | null; ayah_to: number | null; grade: string | null; points: number }[];
  };
  attendance: { present: number; late: number; absent: number; excused: number; rate: number | null };
  serd: { date: string; juz: number[]; score: number | null; pass: number | null; status: string }[];
  badges: { name: string; at: string }[];
  certificates: { id: string; title: string; at: string }[];
}

export interface CertificateRow {
  id: string;
  serial: string;
  kind: string;
  title: string;
  recipient_name: string;
  issued_at: string;
  revoked_at: string | null;
  student_id: string;
  student_code: string;
}

export interface CertificateFull {
  id: string;
  serial: string;
  kind: string;
  title: string;
  recipient_name: string;
  description: string | null;
  issued_at: string;
  revoked_at: string | null;
  signer_name: string | null;
  signer_title: string | null;
  footer: string | null;
  student_id: string;
  center: { name: string; slug: string; logo_url: string | null; primary_color: string };
}

export const fmtDay = (iso: string | null | undefined) => (iso ? new Date(iso).toLocaleDateString('ar') : '—');

/** yyyy-mm-dd of the 1st of this month, and of today (the default report window). */
export function defaultRange(): { from: string; to: string } {
  const now = new Date();
  const iso = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  return { from: iso(new Date(now.getFullYear(), now.getMonth(), 1)), to: iso(now) };
}

export const pct = (v: number | null | undefined) => (v == null ? '—' : `${v}%`);
