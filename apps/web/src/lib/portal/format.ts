// Student portal (/my) shapes and the small client-side derivations the
// mobile portal also does locally (apps/mobile/lib/features/my_portal/) -
// kept in step with home_extras.dart / record_extras.dart on purpose.
import inspirations from './daily_inspirations.json';

export interface PortalRecitation {
  id: string;
  type: string;
  surah: number;
  ayah_from: number;
  ayah_to: number;
  grade: string | null;
  grade_label: string | null;
  points_awarded: number;
  notes: string | null;
  created_at: string;
  session_group_id: string | null;
}

/** get_student_dashboard (0016) */
export interface Dashboard {
  linked: boolean;
  student: {
    id: string;
    full_name: string;
    student_code: string;
    total_points: number;
    total_parts_count: number;
    total_progress: number;
    next_plan: string | null;
  };
  circle: { name: string; teacher: string | null; stage: string | null } | null;
  stats: {
    total_recitations: number;
    recitations_this_week: number;
    recitations_last_week: number;
    ayahs_this_week: number;
    current_streak: number;
    longest_streak: number;
    weekly_attendance_rate: number | null;
    monthly_attendance_rate: number | null;
    last_recitation_at: string | null;
  };
  recent: PortalRecitation[];
}

/** student_record_detail (0056) */
export interface RecordDetail {
  monthly_points: number;
  points_breakdown: { grade: string; count: number; points_each: number; total: number }[];
  recitations: PortalRecitation[];
  attendance: { date: string; status: string }[];
}

export const ATTENDANCE_LABELS: Record<string, string> = { present: 'حاضر', absent: 'غائب', late: 'متأخر', excused: 'مُعذَر' };
export const ATTENDANCE_STYLES: Record<string, string> = {
  present: 'bg-green-50 text-green-700',
  absent: 'bg-red-50 text-red-700',
  late: 'bg-orange-50 text-orange-700',
  excused: 'bg-slate-100 text-slate-600',
};

export const fmtDate = (iso: string | null) => (iso ? new Date(iso).toLocaleDateString('ar') : '—');

// ---- goals (computeGoals in home_extras.dart: eqraa's hardcoded milestones)

export interface StudentGoal {
  label: string;
  remaining: number;
  unit: string;
  progress: number;
  icon: string;
}

const clamp01 = (v: number) => Math.min(1, Math.max(0, v));

export function computeGoals(totalParts: number, totalPoints: number): StudentGoal[] {
  const goals: StudentGoal[] = [];
  if (totalParts < 30) {
    goals.push({ label: 'لإكمال حفظ القرآن الكريم', remaining: 30 - totalParts, unit: 'جزء', progress: clamp01(totalParts / 30), icon: '📖' });
  }
  const nextHundred = (Math.floor(totalPoints / 100) + 1) * 100;
  goals.push({
    label: `للوصول إلى ${nextHundred} نقطة`,
    remaining: nextHundred - totalPoints,
    unit: 'نقطة',
    progress: clamp01((totalPoints % 100) / 100),
    icon: '⭐',
  });
  return goals;
}

// ---- session grouping (groupSessions in record_extras.dart)

/** Consecutive recitations sharing a non-null session_group_id collapse into one group. */
export function groupSessions<T extends { session_group_id: string | null }>(list: T[]): T[][] {
  const groups: T[][] = [];
  for (const r of list) {
    const lastId = groups.length ? groups[groups.length - 1][0].session_group_id : null;
    if (r.session_group_id != null && lastId === r.session_group_id) groups[groups.length - 1].push(r);
    else groups.push([r]);
  }
  return groups;
}

// ---- dates in the center's time zone (the server renders in UTC)

/** YYYY-MM-DD of an instant as seen in `tz`. */
export function localDate(tz: string, at: Date = new Date()): string {
  try {
    return new Intl.DateTimeFormat('en-CA', { timeZone: tz, year: 'numeric', month: '2-digit', day: '2-digit' }).format(at);
  } catch {
    return at.toISOString().slice(0, 10);
  }
}

export function addDays(ymd: string, days: number): string {
  const d = new Date(`${ymd}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

// ---- daily ayah / quote (DailyInspirationCard: day-of-year index)

export interface Inspiration {
  text: string;
  source: string;
}

export function dailyInspiration(todayYmd: string): Inspiration | null {
  const list = inspirations as Inspiration[];
  if (!list.length) return null;
  const today = Date.UTC(+todayYmd.slice(0, 4), +todayYmd.slice(5, 7) - 1, +todayYmd.slice(8, 10));
  const dayOfYear = Math.round((today - Date.UTC(+todayYmd.slice(0, 4), 0, 1)) / 86_400_000);
  return list[dayOfYear % list.length];
}
