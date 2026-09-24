// Billing phase 1 (manual payments, migration 0066) - shapes + labels shared by
// the center's /billing page, the tenant banner and the platform console.

export interface BillingState {
  state: 'trial' | 'active' | 'grace' | 'expired' | 'suspended' | 'cancelled';
  kind: 'trial' | 'paid' | null;
  until: string | null;
  days_left: number | null;
  grace_ends: string | null;
  grace_days: number;
  enforced: boolean;
  locked: boolean;
  plan_id: string | null;
}

export interface BillingPlan {
  id: string;
  name: string;
  price_cents: number;
  yearly_price_cents: number | null;
  currency: string;
  limits: { max_students?: number | null; max_teachers?: number | null };
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
};

export const money = (cents: number, currency: string) =>
  `${(cents / 100).toLocaleString('en-US', { maximumFractionDigits: 2 })} ${currency}`;

export const fmtDay = (iso: string | null) => (iso ? new Date(iso).toLocaleDateString('ar', { day: 'numeric', month: 'long', year: 'numeric' }) : '—');

/** The one-line banner for the tenant shell, or null when there is nothing to say. */
export function billingBanner(b: BillingState | null | undefined, isAdmin: boolean): { tone: 'red' | 'amber'; text: string } | null {
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
  if (!isAdmin) return null;
  if (b.state === 'grace') return { tone: 'red', text: `${ended} ${what} — يتحول المركز للقراءة فقط في ${fmtDay(b.grace_ends)}` };
  if ((b.state === 'trial' || b.state === 'active') && b.days_left != null && b.days_left <= 7) {
    return { tone: 'amber', text: `${ends} ${what} خلال ${b.days_left} ${b.days_left === 1 ? 'يوم' : 'أيام'}` };
  }
  return null;
}
