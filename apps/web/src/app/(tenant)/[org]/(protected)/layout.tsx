import { notFound, redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { SubmitButton } from '@/components/submit-button';
import { OrgLogo } from '@/components/org-logo';
import { signOut } from '@/lib/auth/actions';
import { createClient } from '@/lib/supabase/server';
import { billingBanner, usageBanner, type BillingState, type Usage } from '@/lib/billing/format';

const ROLE_LABELS: Record<string, string> = {
  admin: 'مدير',
  teacher: 'معلم',
  guardian: 'ولي أمر',
  student: 'طالب',
};

// Shell shared by the full staff dashboard (see (staff)/layout.tsx, which
// adds the sidebar and blocks student/guardian from these routes) and the
// student/guardian portal at /my. Only auth + the org header live here.
export default async function TenantProtectedLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ org: string }>;
}) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);

  if (!org) notFound();
  // Not authenticated, or authenticated but not a member of THIS org - RLS
  // would block every query anyway, so send them to sign in rather than show
  // an empty shell.
  if (!org.myRole) redirect('/login');

  // A viewing (read-only) account is told so on every page; the database refuses its writes regardless.
  const supabase = await createClient();
  const { data: access } = await supabase.rpc('my_access', { p_org: org.id });
  const acc = access as { is_read_only?: boolean; reason?: 'account' | 'billing' | null; billing?: BillingState; usage?: Usage | null } | null;
  const viewer = acc?.is_read_only === true && acc.reason !== 'billing';
  // Subscription state (0066/0067): locked for everyone; expiring / grace / capacity for staff.
  const isStaff = org.myRole === 'admin' || org.myRole === 'teacher';
  const billing = billingBanner(acc?.billing, isStaff);
  const capacity = isStaff ? usageBanner(acc?.usage) : null;
  const { data: noticeData } = await supabase.rpc('active_platform_notices');
  const notices = (noticeData ?? []) as { id: string; title: string; body: string | null; level: string }[];

  return (
    <div
      className="flex min-h-screen"
      style={
        {
          '--brand-primary': org.primaryColor,
          '--brand-secondary': org.secondaryColor,
        } as React.CSSProperties
      }
    >
      <div className="flex-1">
        {org.isPlatformOwner && (
          <div className="bg-purple-700 px-6 py-2 text-center text-sm font-semibold text-white print:hidden">
            وضع مالك المنصة — أنت تتصفح هذا المركز كمشرف وليس كعضو فيه
          </div>
        )}
        {notices.map((n) => (
          <div
            key={n.id}
            className={`px-6 py-2 text-center text-sm print:hidden ${
              n.level === 'critical' ? 'bg-red-600 text-white' : n.level === 'warning' ? 'bg-amber-100 text-amber-900' : 'bg-blue-50 text-blue-900'
            }`}
          >
            <b>{n.title}</b>
            {n.body && <span> — {n.body}</span>}
          </div>
        ))}
        {billing && (
          <div
            className={`px-6 py-2 text-center text-sm font-semibold print:hidden ${billing.tone === 'red' ? 'bg-red-600 text-white' : 'bg-amber-100 text-amber-900'}`}
          >
            {billing.text}
            {org.myRole === 'admin' && (
              <a href="/billing" className="ms-2 underline">
                الاشتراك والدفع
              </a>
            )}
          </div>
        )}
        {capacity && (
          <div className={`px-6 py-2 text-center text-sm font-semibold print:hidden ${capacity.tone === 'red' ? 'bg-red-100 text-red-800' : 'bg-amber-100 text-amber-900'}`}>
            {capacity.text}
            {org.myRole === 'admin' && (
              <a href="/billing" className="ms-2 underline">
                🌿 اسقِ بستانك — انتقل لخطة أكبر
              </a>
            )}
          </div>
        )}
        {viewer && (
          <div className="bg-amber-500 px-6 py-2 text-center text-sm font-semibold text-white print:hidden">
            هذا حساب عرض — البيانات للاطّلاع فقط
          </div>
        )}
        <header className="flex items-center justify-between border-b bg-white px-6 py-4 print:hidden">
          <span className="flex items-center gap-2 font-bold text-brand">
            <OrgLogo name={org.name} logoUrl={org.logoUrl} size={32} />
            {org.name}
          </span>
          <div className="flex items-center gap-4 text-sm text-gray-500">
            <span>{ROLE_LABELS[org.myRole] ?? org.myRole}</span>
            <form action={signOut}>
              <SubmitButton className="hover:text-red-600" pendingText="جاري الخروج...">
                تسجيل خروج
              </SubmitButton>
            </form>
          </div>
        </header>
        <main>{children}</main>
      </div>
    </div>
  );
}
