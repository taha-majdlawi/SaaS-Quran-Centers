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

export const METHOD_LABELS: Record<string, string> = {
  bank_transfer: 'تحويل بنكي',
  wallet: 'محفظة إلكترونية',
  cash: 'نقدًا',
  other: 'أخرى',
};
export const PERIOD_LABELS: Record<string, string> = { monthly: 'شهري', yearly: 'سنوي' };
export const REQUEST_STATUS: Record<string, string> = { pending: 'بانتظار التأكيد', approved: 'مؤكَّد', rejected: 'مرفوض', cancelled: 'ملغى' };
export const REQUEST_STYLES: Record<string, string> = {
  pending: 'bg-amber-50 text-amber-700',
  approved: 'bg-green-50 text-green-700',
  rejected: 'bg-red-50 text-red-700',
  cancelled: 'bg-gray-100 text-gray-500',
};
export const STATE_LABELS: Record<string, string> = {
  trial: 'فترة تجريبية',
  active: 'مفعّل',
  grace: 'انتهى — ضمن مهلة السماح',
  expired: 'منتهي',
  suspended: 'موقوف',
  cancelled: 'ملغى',
  free: 'الخطة المجانية',
};

export const money = (cents: number, currency: string) =>
  `${(cents / 100).toLocaleString('en-US', { maximumFractionDigits: 2 })} ${currency}`;

export const fmtDay = (iso: string | null) => (iso ? new Date(iso).toLocaleDateString('ar', { day: 'numeric', month: 'long', year: 'numeric' }) : '—');

/** "5 طلاب" / "طالب واحد" / "طالبان". */
export function countText(n: number, one: string, two: string, many: string): string {
  return n === 1 ? `${one} واحد` : n === 2 ? two : `${n} ${many}`;
}

/** The one-line subscription banner for the tenant shell (staff = admins + teachers), or null. */
export function billingBanner(b: BillingState | null | undefined, isStaff: boolean): { tone: 'red' | 'amber'; text: string } | null {
  if (!b || !b.enforced) return null;
  const trial = b.kind === 'trial';
  const what = trial ? 'الفترة التجريبية' : 'اشتراك المركز';
  const ended = trial ? 'انتهت' : 'انتهى';
  const ends = trial ? 'تنتهي' : 'ينتهي';
  if (b.locked) {
    return {
      tone: 'red',
      text:
        b.state === 'suspended' || b.state === 'cancelled'
          ? 'المركز موقوف — البيانات للاطّلاع فقط. تواصل مع إدارة المنصة'
          : `${ended} ${what} — البيانات للاطّلاع فقط حتى التجديد`,
    };
  }
  if (!isStaff) return null;
  if (b.state === 'grace') {
    const next = b.free_plan_available ? 'ينتقل المركز للخطة المجانية (أو للقراءة فقط إن تجاوز حدودها)' : 'يتحول المركز للقراءة فقط';
    return { tone: 'red', text: `${ended} ${what} — ${next} في ${fmtDay(b.grace_ends)}` };
  }
  if ((b.state === 'trial' || b.state === 'active') && b.days_left != null && b.days_left <= 7) {
    return { tone: 'amber', text: `${ends} ${what} خلال ${b.days_left} ${b.days_left === 1 ? 'يوم' : 'أيام'}` };
  }
  return null;
}

/** Capacity warning for staff: <= 5 students or <= 1 teacher left on the plan. */
export function usageBanner(u: Usage | null | undefined): { tone: 'red' | 'amber'; text: string } | null {
  if (!u) return null;
  const parts: string[] = [];
  let full = false;
  if (u.students_left != null && u.students_left <= 5) {
    full ||= u.students_left === 0;
    parts.push(u.students_left === 0 ? `وصل المركز للحد الأقصى من الطلاب (${u.max_students})` : `تبقى ${countText(u.students_left, 'طالب', 'طالبان', 'طلاب')} يمكن إضافتهم`);
  }
  if (u.teachers_left != null && u.teachers_left <= 1) {
    full ||= u.teachers_left === 0;
    parts.push(u.teachers_left === 0 ? `وصل المركز للحد الأقصى من المعلمين (${u.max_teachers})` : 'تبقى إضافة معلم واحد فقط');
  }
  if (!parts.length) return null;
  return { tone: full ? 'red' : 'amber', text: `${parts.join(' · ')} ضمن خطة «${u.plan_name ?? ''}»` };
}
