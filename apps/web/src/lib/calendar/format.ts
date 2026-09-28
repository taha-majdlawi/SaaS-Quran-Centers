import { ar } from '@/lib/i18n/dictionaries/ar';

// Shared bits for the calendar pages. Everything decided by the server (who
// sees an entry, seats, whether registration is open, consent) comes from the
// calendar_* RPCs; this file only names and lays things out.

export interface CalType {
  id: string;
  key: string;
  name: string;
  color: string;
  default_is_working: boolean;
  is_active: boolean;
  supports_registration: boolean;
  requires_guardian_consent: boolean;
  sort_order: number;
}

export interface CalEntry {
  id: string;
  title: string;
  description: string | null;
  start_date: string;
  end_date: string;
  starts_at: string | null;
  location: string | null;
  kind: string;
  type_id: string | null;
  type_name: string;
  type_color: string;
  is_working_day: boolean;
  audience: string;
  circle_id: string | null;
  circle_name: string | null;
  stage_id: string | null;
  stage_name: string | null;
  capacity: number | null;
  registration_open: boolean;
  registration_deadline: string | null;
  supports_registration: boolean;
  requires_guardian_consent: boolean;
  taken: number;
  waiting: number;
  my_registered: boolean;
  registration_state: 'none' | 'ended' | 'closed' | 'full' | 'open';
}

export interface CalRange {
  from: string;
  to: string;
  working_days: number;
  total_days: number;
  weekdays: { dow: number; label: string; is_working: boolean; is_serd_day: boolean }[];
  types: CalType[];
  entries: CalEntry[];
  serd: { id: string; student_name: string; session_date: string; assigned: boolean }[];
}

export interface MineRow {
  student_id: string;
  student_name: string;
  registration_id: string | null;
  source: string | null;
  consent_status: string | null;
  consent_token: string | null;
  result_rank: number | null;
  result_note: string | null;
  waiting: boolean;
}

export interface Participant {
  registration_id: string;
  student_id: string;
  student_name: string;
  student_code: string;
  circle_name: string | null;
  source: string;
  consent_status: string;
  consent_method: string | null;
  consent_token: string;
  result_rank: number | null;
  result_note: string | null;
}

export interface CalImage {
  id: string;
  image_url: string;
  caption: string | null;
}

export interface CalDetails extends CalEntry {
  mine: MineRow[];
  participants: Participant[];
  waitlist: { student_id: string; student_name: string; created_at: string }[];
  images: CalImage[];
}

export const AUDIENCE_LABELS: Record<string, string> = ar.labels.audience;

export const CONSENT_LABELS: Record<string, string> = ar.labels.consent;

export const CONSENT_STYLES: Record<string, string> = {
  pending: 'bg-amber-50 text-amber-700',
  approved: 'bg-green-50 text-green-700',
  declined: 'bg-red-50 text-red-700',
};

export const SOURCE_LABELS: Record<string, string> = {
  self: 'سجّل بنفسه',
  guardian: 'سجّله ولي الأمر',
  teacher: 'سجّله المعلم',
  admin: 'سجّله المشرف',
};

export const STATE_LABELS: Record<string, string> = ar.labels.registration;

/** `lang` is t.labels.dateLocale on translated screens. */
export const fmtDay = (iso: string, lang = 'ar') => new Date(`${iso}T00:00:00`).toLocaleDateString(lang, { day: 'numeric', month: 'long', year: 'numeric' });

export function fmtRange(e: { start_date: string; end_date: string }, lang = 'ar') {
  return e.start_date === e.end_date ? fmtDay(e.start_date, lang) : `${fmtDay(e.start_date, lang)} — ${fmtDay(e.end_date, lang)}`;
}

export const fmtTime = (t: string | null) => (t ? t.slice(0, 5) : '');

/** 'YYYY-MM' -> { from, to, year, month(0-based) } covering the whole month. */
export function monthBounds(ym?: string) {
  const now = new Date();
  const [y, m] = ym && /^\d{4}-\d{2}$/.test(ym) ? ym.split('-').map(Number) : [now.getFullYear(), now.getMonth() + 1];
  const iso = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  const first = new Date(y, m - 1, 1);
  const last = new Date(y, m, 0);
  const shift = (delta: number) => {
    const d = new Date(y, m - 1 + delta, 1);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
  };
  return { from: iso(first), to: iso(last), year: y, month: m - 1, prev: shift(-1), next: shift(1), iso };
}

export const MONTH_NAMES = ar.labels.months;
