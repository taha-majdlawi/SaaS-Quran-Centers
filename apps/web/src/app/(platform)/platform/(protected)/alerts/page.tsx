import { createClient } from '@/lib/supabase/server';
import { STATE_LABELS, countText, fmtDay, type BillingState, type Usage } from '@/lib/billing/format';

interface Row {
  id: string;
  name: string;
  slug: string;
  plan: string | null;
  billing: BillingState;
  usage: Usage;
  pending_payment: boolean;
  reasons: string[];
  severity: number;
}

const SEVERITY_STYLES: Record<number, string> = {
  1: 'border-red-300 bg-red-50',
  2: 'border-orange-200 bg-orange-50',
  3: 'border-amber-200 bg-amber-50',
  4: 'bg-white',
};

function reasonText(r: string, row: Row): string {
  const b = row.billing;
  const u = row.usage;
  const what = b.kind === 'trial' ? 'التجربة' : 'الاشتراك';
  switch (r) {
    case 'locked':
      return b.state === 'expired' ? `منتهي ومقفول للقراءة فقط (انتهى ${fmtDay(b.until)})` : `المركز ${STATE_LABELS[b.state] ?? b.state}`;
    case 'grace':
      return `انتهى ${what} — مهلة حتى ${fmtDay(b.grace_ends)}`;
    case 'expiring':
      return `ينتهي ${what} خلال ${countText(b.days_left ?? 0, 'يوم', 'يومين', 'أيام')} (${fmtDay(b.until)})`;
    case 'students':
      return u.students_left === 0 ? `وصل للحد الأقصى من الطلاب (${u.max_students})` : `تبقى ${countText(u.students_left ?? 0, 'طالب', 'طالبان', 'طلاب')} (${u.students}/${u.max_students})`;
    case 'teachers':
      return u.teachers_left === 0 ? `وصل للحد الأقصى من المعلمين (${u.max_teachers})` : `تبقى إضافة معلم واحد (${u.teachers}/${u.max_teachers})`;
    case 'payment':
      return 'إشعار دفع بانتظار تأكيدك';
    default:
      return r;
  }
}

// Every center that needs the owner's attention (0067): locked, in grace,
// expiring (trial <= 7 days, paid <= 60 days), at/near its plan's capacity,
// or with a payment waiting - most urgent first.
export default async function PlatformAlertsPage() {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('platform_billing_alerts');
  const d = (data ?? { enforced: false, pending_payments: 0, rows: [] }) as { enforced: boolean; pending_payments: number; rows: Row[] };

  return (
    <div className="max-w-4xl">
      <h1 className="mb-1 text-2xl font-bold">تنبيهات المراكز</h1>
      <p className="mb-4 text-sm text-gray-500">مراكز تحتاج انتباهك: اشتراكات تقترب من الانتهاء، مراكز مقفولة، مراكز قريبة من حدود خطتها، ودفعات بانتظار التأكيد.</p>
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error.message}</p>}
      {!d.enforced && (
        <p className="mb-4 rounded border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-900">
          القفل والتذكيرات للمراكز معطّلة حاليًا — تُفعَّل من{' '}
          <a href="/billing" className="underline">
            المدفوعات والاشتراكات
          </a>
          . القائمة أدناه تعرض الوضع الفعلي على كل حال.
        </p>
      )}
      {d.pending_payments > 0 && (
        <a href="/billing" className="mb-4 block rounded-lg border border-orange-200 bg-orange-50 px-4 py-3 text-sm font-semibold text-orange-900 hover:bg-orange-100">
          💳 {countText(d.pending_payments, 'إشعار دفع', 'إشعارا دفع', 'إشعارات دفع')} بانتظار تأكيدك ←
        </a>
      )}
      {d.rows.length === 0 ? (
        <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا شيء يحتاج انتباهك الآن ✓</p>
      ) : (
        <div className="flex flex-col gap-2">
          {d.rows.map((r) => (
            <a key={r.id} href={`/organizations/${r.id}` as never} className={`block rounded-lg border p-4 text-sm hover:shadow-sm ${SEVERITY_STYLES[r.severity] ?? 'bg-white'}`}>
              <div className="flex flex-wrap items-center justify-between gap-2">
                <span>
                  <b className="text-base">{r.name}</b>{' '}
                  <span className="text-xs text-gray-400" dir="ltr">
                    {r.slug}
                  </span>
                </span>
                <span className="text-xs text-gray-600">
                  {r.plan ?? 'بدون خطة'} · {STATE_LABELS[r.billing.state] ?? r.billing.state}
                </span>
              </div>
              <ul className="mt-2 flex flex-wrap gap-2">
                {r.reasons.map((reason) => (
                  <li key={reason} className="rounded-full bg-white/70 px-2.5 py-0.5 text-xs font-semibold ring-1 ring-black/5">
                    {reasonText(reason, r)}
                  </li>
                ))}
              </ul>
            </a>
          ))}
        </div>
      )}
    </div>
  );
}
