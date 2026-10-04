// Shapes returned by the fees RPCs (0081).

export type FeePeriod = 'monthly' | 'term' | 'once';
export type FeeMethod = 'cash' | 'transfer' | 'card' | 'wallet' | 'other';
export const FEE_METHODS: FeeMethod[] = ['cash', 'transfer', 'card', 'wallet', 'other'];

export interface FeeBalance {
  due: number;
  paid: number;
  /** positive = owes, negative = in credit */
  balance: number;
  upcoming: number;
  last_paid: string | null;
  first_due: string | null;
}

export interface FeePlan {
  id: string;
  name: string;
  amount: number;
  period: FeePeriod;
  active: boolean;
  students: number;
}

export interface FeeStudentRow extends FeeBalance {
  id: string;
  name: string;
  code: string | null;
  circle: string | null;
  plan_id: string | null;
  plan: string | null;
  discount: number;
  exempt: boolean;
  note: string | null;
}

export interface FeesOverview {
  enabled: boolean;
  platform_allowed: boolean;
  currency: string;
  due_day: number;
  reminder_days: number;
  today: string;
  plans: FeePlan[];
  collected_month: number;
  collected_total: number;
  students: FeeStudentRow[];
}

export interface FeeCharge {
  id: string;
  title: string;
  amount: number;
  due_date: string;
  status: 'open' | 'waived' | 'cancelled';
}

export interface FeePayment {
  id: string;
  amount: number;
  method: FeeMethod;
  paid_on: string;
  receipt_no: number;
  note: string | null;
  voided: boolean;
  void_reason: string | null;
}

export interface StudentFees {
  enabled: boolean;
  is_admin?: boolean;
  currency?: string;
  today?: string;
  student?: { id: string; name: string; code: string | null };
  plan?: { id: string | null; name: string | null; amount: number | null; period: FeePeriod | null; discount: number; exempt: boolean; note: string | null } | null;
  balance?: FeeBalance;
  charges?: FeeCharge[];
  payments?: FeePayment[];
}

export interface FeeReceipt {
  receipt_no: number;
  amount: number;
  method: FeeMethod;
  paid_on: string;
  note: string | null;
  voided: boolean;
  void_reason: string | null;
  currency: string;
  center: string;
  logo_url: string | null;
  student: string;
  student_code: string | null;
  recorded_by: string | null;
  balance: FeeBalance;
}

export interface FeesReport {
  currency: string;
  total: number;
  count: number;
  by_method: Partial<Record<FeeMethod, number>>;
  charged: number;
  outstanding: number;
  payments: { id: string; receipt_no: number; paid_on: string; amount: number; method: FeeMethod; student: string; voided: boolean }[];
}

/** "12.5 JD" in the viewer's number format. */
export const feeMoney = (v: number | string | null | undefined, currency: string, lang = 'ar') =>
  `${Number(v ?? 0).toLocaleString(lang, { maximumFractionDigits: 2 })}${currency ? ` ${currency}` : ''}`;
