import { ar } from '@/lib/i18n/dictionaries/ar';
import { fmt } from '@/lib/i18n/config';

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

/** What a badge asks for. `templates` is t.labels.rule on translated screens. */
export function ruleText(
  b: { rule_type: string; threshold: number; param: string | null },
  gradeLabels?: Map<string, string>,
  templates: Record<string, string> = ar.labels.rule,
): string {
  const tpl = templates[b.rule_type];
  return tpl ? fmt(tpl, { n: b.threshold, grade: gradeLabels?.get(b.param ?? '') ?? b.param ?? '' }) : '';
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

export const PURCHASE_LABELS: Record<string, string> = ar.labels.purchase;
export const PURCHASE_STYLES: Record<string, string> = {
  pending: 'bg-amber-50 text-amber-700',
  fulfilled: 'bg-green-50 text-green-700',
  cancelled: 'bg-gray-100 text-gray-500',
};

export const money = (v: number | string, symbol: string, lang = 'ar') => `${Number(v).toLocaleString(lang, { maximumFractionDigits: 2 })} ${symbol}`;
export const fmtDate = (iso: string | null, lang = 'ar') => (iso ? new Date(iso).toLocaleDateString(lang) : '—');

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

export const METRIC_LABELS: Record<string, string> = ar.labels.metric;

export const CHALLENGE_STATUS: Record<string, string> = ar.labels.challengeStatus;
