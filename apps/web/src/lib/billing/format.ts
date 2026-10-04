import { ar } from '@/lib/i18n/dictionaries/ar';
import { staffAr } from '@/lib/i18n/dictionaries/staff.ar';
import { fmt } from '@/lib/i18n/config';

// Billing phase 1 (manual payments, migration 0066) - shapes + labels shared by
// the center's /billing page, the tenant banner and the platform console.

export interface BillingState {
  state: 'trial' | 'active' | 'grace' | 'expired' | 'suspended' | 'cancelled' | 'free';
  kind: 'trial' | 'paid' | null;
  until: string | null;
  days_left: number | null;
  grace_ends: string | null;
  grace_days: number;
  enforced: boolean;
  locked: boolean;
  plan_id: string | null;
  free_plan_available?: boolean;
}

/** Plan usage (0067) - staff only. */
export interface Usage {
  plan_id: string | null;
  plan_name: string | null;
  students: number;
  max_students: number | null;
  students_left: number | null;
  teachers: number;
  max_teachers: number | null;
  teachers_left: number | null;
}

export interface BillingPlan {
  id: string;
  name: string;
  price_cents: number;
  yearly_price_cents: number | null;
  currency: string;
  limits: { max_students?: number | null; max_teachers?: number | null };
  is_free?: boolean;
}

export interface BillingRequest {
  id: string;
  plan: string;
  period: 'monthly' | 'yearly';
  amount_cents: number;
  currency: string;
  method: string;
  reference: string | null;
  status: 'pending' | 'approved' | 'rejected' | 'cancelled';
  created_at: string;
  review_note: string | null;
  period_start: string | null;
  period_end: string | null;
}

// Arabic by default (the platform console); the center's pages pass their own strings.
const B = staffAr.billing;
export type BillingLabels = typeof B;
export const METHOD_LABELS = B.method;
export const PERIOD_LABELS = B.period;
export const REQUEST_STATUS = B.requestStatus;
export const REQUEST_STYLES: Record<string, string> = {
  pending: 'bg-amber-50 text-amber-700',
  approved: 'bg-green-50 text-green-700',
  rejected: 'bg-red-50 text-red-700',
  cancelled: 'bg-gray-100 text-gray-500',
};
export const STATE_LABELS = B.state;

/**
 * The garden ladder (0068): plans, cheapest first, are the stages of a growing
 * orchard - بذرة -> غرسة -> شجرة -> بستان. Picked by position, so a plan the
 * owner renames in the console keeps its icon and tagline.
 */
export const GARDEN_STAGES = ar.marketing.stages;
export const gardenStage = (i: number) => GARDEN_STAGES[Math.max(0, Math.min(i, GARDEN_STAGES.length - 1))];

/** The upgrade call-to-action used wherever a plan limit is reached. */
export const UPGRADE_CTA = B.upgrade;

export const money = (cents: number, currency: string) =>
  `${(cents / 100).toLocaleString('en-US', { maximumFractionDigits: 2 })} ${currency}`;

export const fmtDay = (iso: string | null, lang = 'ar') => (iso ? new Date(iso).toLocaleDateString(lang, { day: 'numeric', month: 'long', year: 'numeric' }) : '—');

/** "5 طلاب" / "طالب واحد" / "طالبان". */
export function countText(n: number, one: string, two: string, many: string): string {
  return n === 1 ? `${one} واحد` : n === 2 ? two : `${n} ${many}`;
}

/** A count from a {one, two, many} set of templates ("{n} طلاب" / "1 student"). */
export function plural(n: number, forms: Record<string, string>): string {
  return n === 1 ? forms.one : n === 2 ? forms.two : fmt(forms.many, { n });
}

/** The one-line subscription banner for the tenant shell (staff = admins + teachers), or null. */
export function billingBanner(
  b: BillingState | null | undefined,
  isStaff: boolean,
  L: BillingLabels = B,
  lang = 'ar',
): { tone: 'red' | 'amber'; text: string } | null {
  if (!b || !b.enforced) return null;
  const trial = b.kind === 'trial';
  if (b.locked) {
    return { tone: 'red', text: b.state === 'suspended' || b.state === 'cancelled' ? L.suspendedBanner : trial ? L.lockedTrial : L.lockedPaid };
  }
  if (!isStaff) return null;
  if (b.state === 'grace') {
    const next = b.free_plan_available ? L.nextFree : L.nextReadOnly;
    return { tone: 'red', text: fmt(trial ? L.graceTrial : L.gracePaid, { next, date: fmtDay(b.grace_ends, lang) }) };
  }
  if ((b.state === 'trial' || b.state === 'active') && b.days_left != null && b.days_left <= 7) {
    return { tone: 'amber', text: fmt(trial ? L.soonTrial : L.soonPaid, { days: plural(b.days_left, L.days) }) };
  }
  return null;
}

/** Capacity warning for staff: <= 5 students or <= 1 teacher left on the plan. */
export function usageBanner(u: Usage | null | undefined, L: BillingLabels = B): { tone: 'red' | 'amber'; text: string } | null {
  if (!u) return null;
  const parts: string[] = [];
  let full = false;
  if (u.students_left != null && u.students_left <= 5) {
    full ||= u.students_left === 0;
    parts.push(u.students_left === 0 ? fmt(L.studentsFull, { max: u.max_students ?? 0 }) : fmt(L.leftToAdd, { n: plural(u.students_left, L.students) }));
  }
  if (u.teachers_left != null && u.teachers_left <= 1) {
    full ||= u.teachers_left === 0;
    parts.push(u.teachers_left === 0 ? fmt(L.teachersFull, { max: u.max_teachers ?? 0 }) : L.oneTeacherLeft);
  }
  if (!parts.length) return null;
  return { tone: full ? 'red' : 'amber', text: fmt(L.withinPlan, { parts: parts.join(' · '), plan: u.plan_name ?? '' }) };
}
