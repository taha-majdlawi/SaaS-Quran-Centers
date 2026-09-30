import { ar } from '@/lib/i18n/dictionaries/ar';

// Arabic names (the staff pages); translated screens use t.labels.* instead.
export const TYPE_LABELS: Record<string, string> = ar.labels.recitationType;
export const ATT_LABELS: Record<string, string> = ar.labels.attendance;
export const CERT_KIND_LABELS: Record<string, string> = ar.labels.certKind;

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

/** `lang` is t.labels.dateLocale on translated screens. */
export const fmtDay = (iso: string | null | undefined, lang = 'ar') => (iso ? new Date(iso).toLocaleDateString(lang) : '—');

/** yyyy-mm-dd of the 1st of this month, and of today (the default report window). */
export function defaultRange(): { from: string; to: string } {
  const now = new Date();
  const iso = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  return { from: iso(new Date(now.getFullYear(), now.getMonth(), 1)), to: iso(now) };
}

export const pct = (v: number | null | undefined) => (v == null ? '—' : `${v}%`);

/**
 * The period to compare [from, to] with: when it starts on the 1st, the same
 * days of the previous month (1–15 Oct vs 1–15 Sep; a whole month vs the whole
 * previous month); otherwise the same number of days just before it.
 */
export function previousRange(from: string, to: string): { from: string; to: string } {
  const iso = (d: Date) => `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}-${String(d.getUTCDate()).padStart(2, '0')}`;
  const f = new Date(`${from}T00:00:00Z`);
  const t = new Date(`${to}T00:00:00Z`);
  if (f.getUTCDate() === 1) {
    const pf = new Date(Date.UTC(f.getUTCFullYear(), f.getUTCMonth() - 1, 1));
    const lastOfPrev = new Date(Date.UTC(f.getUTCFullYear(), f.getUTCMonth(), 0)).getUTCDate();
    const sameMonth = t.getUTCFullYear() === f.getUTCFullYear() && t.getUTCMonth() === f.getUTCMonth();
    const lastOfThis = new Date(Date.UTC(t.getUTCFullYear(), t.getUTCMonth() + 1, 0)).getUTCDate();
    if (sameMonth) {
      const day = t.getUTCDate() === lastOfThis ? lastOfPrev : Math.min(t.getUTCDate(), lastOfPrev);
      return { from: iso(pf), to: iso(new Date(Date.UTC(pf.getUTCFullYear(), pf.getUTCMonth(), day))) };
    }
  }
  const days = Math.round((t.getTime() - f.getTime()) / 86400000) + 1;
  const pt = new Date(f.getTime() - 86400000);
  return { from: iso(new Date(pt.getTime() - (days - 1) * 86400000)), to: iso(pt) };
}

/** Change from `prev` to `now`: the difference and, when it means something, the percentage. */
export function delta(now: number | null | undefined, prev: number | null | undefined): { diff: number; pct: number | null } | null {
  if (now == null || prev == null) return null;
  const diff = Math.round((Number(now) - Number(prev)) * 10) / 10;
  return { diff, pct: Number(prev) === 0 ? null : Math.round((diff / Number(prev)) * 100) };
}
