// Shared bits for the market / badges / challenges pages. All values (balances,
// progress, rankings) are computed in SQL; this file only names and formats.

export const RULE_LABELS: Record<string, string> = {
  manual: 'يدوية (يمنحها المشرف)',
  points_threshold: 'الوصول إلى عدد نقاط',
  recitations_count: 'عدد التسميعات',
  grade_count: 'عدد التسميعات بتقدير معيّن',
  streak_days: 'أيام متتالية بتسميع',
  weekly_attendance: 'نسبة الحضور الأسبوعية',
  juz_complete: 'إتمام جزء كامل في السرد',
  serd_passed_count: 'عدد السرد الناجح',
};

export function ruleText(b: { rule_type: string; threshold: number; param: string | null }, gradeLabels?: Map<string, string>): string {
  switch (b.rule_type) {
    case 'manual':
      return 'يمنحها المشرف';
    case 'points_threshold':
      return `${b.threshold} نقطة`;
    case 'recitations_count':
      return `${b.threshold} تسميعة`;
    case 'grade_count':
      return `${b.threshold} تسميعة بتقدير «${gradeLabels?.get(b.param ?? '') ?? b.param}»`;
    case 'streak_days':
      return `${b.threshold} أيام متتالية`;
    case 'weekly_attendance':
      return `حضور أسبوعي ${b.threshold}%`;
    case 'juz_complete':
      return `إتمام الجزء ${b.threshold} في السرد`;
    case 'serd_passed_count':
      return `${b.threshold} سرد ناجح`;
    default:
      return '';
  }
}

export interface MarketItem {
  id: string;
  name: string;
  description: string | null;
  image_url: string | null;
  price: number;
  stock: number | null;
  is_active?: boolean;
}

export interface Wallet {
  earned_points: number;
  converted_points: number;
  total_converted: number;
  pending_points: number;
  spent: number;
  balance: number;
}

export interface Purchase {
  id: string;
  item_name: string;
  spent: number;
  status: 'pending' | 'fulfilled' | 'cancelled';
  created_at: string;
  decided_at: string | null;
  student_id?: string;
  student_name?: string;
  student_code?: string;
}

export const PURCHASE_LABELS: Record<string, string> = { pending: 'قيد التسليم', fulfilled: 'تم التسليم', cancelled: 'ملغى' };
export const PURCHASE_STYLES: Record<string, string> = {
  pending: 'bg-amber-50 text-amber-700',
  fulfilled: 'bg-green-50 text-green-700',
  cancelled: 'bg-gray-100 text-gray-500',
};

export const money = (v: number | string, symbol: string) => `${Number(v).toLocaleString('ar', { maximumFractionDigits: 2 })} ${symbol}`;
export const fmtDate = (iso: string | null) => (iso ? new Date(iso).toLocaleDateString('ar') : '—');

export interface BadgeProgress {
  id: string;
  name: string;
  description: string | null;
  icon: string;
  color: string;
  rule_type: string;
  threshold: number;
  param: string | null;
  progress: number;
  goal: number;
  earned: boolean;
  awarded_at: string | null;
  expires_at: string | null;
}

export const METRIC_LABELS: Record<string, string> = {
  points: 'متوسط النقاط لكل طالب',
  recitations: 'متوسط عدد التسميعات لكل طالب',
  attendance: 'متوسط أيام الحضور لكل طالب',
};

export const CHALLENGE_STATUS: Record<string, string> = { upcoming: 'قادمة', active: 'جارية', ended: 'انتهت' };
