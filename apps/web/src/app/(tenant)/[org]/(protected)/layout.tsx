import { GrowingTree } from '@/components/growing-tree';
import { MonitoringOrg } from '@/components/error-reporter';
import { notFound, redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { SubmitButton } from '@/components/submit-button';
import { OrgLogo } from '@/components/org-logo';
import { signOut } from '@/lib/auth/actions';
import { createClient } from '@/lib/supabase/server';
import { billingBanner, usageBanner, type BillingState, type Usage } from '@/lib/billing/format';
import { getI18n, isTranslatedScreen } from '@/lib/i18n/server';
import { LanguageSwitcher, LocaleSync } from '@/lib/i18n/client';
import { LockedFormGuard } from '@/components/locked-form-guard';

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
  // independent lookups - run them side by side
  const [{ data: access }, { data: noticeData }, { t }, translated] = await Promise.all([
    supabase.rpc('my_access', { p_org: org.id }),
    supabase.rpc('active_platform_notices'),
    getI18n(),
    isTranslatedScreen(),
  ]);
  const acc = access as { is_read_only?: boolean; reason?: 'account' | 'billing' | null; billing?: BillingState; usage?: Usage | null } | null;
  const viewer = acc?.is_read_only === true && acc.reason !== 'billing';
  // Subscription state (0066/0067): locked for everyone; expiring / grace / capacity for staff.
  const isStaff = org.myRole === 'admin' || org.myRole === 'teacher';
  let billing = billingBanner(acc?.billing, isStaff, t.staff.billing, t.labels.dateLocale);
  // the portal only ever sees the lock itself - say it in the viewer's language
  if (billing && !isStaff) {
    const st = acc?.billing?.state;
    billing = { ...billing, text: st === 'suspended' || st === 'cancelled' ? t.shell.suspended : t.shell.locked };
  }
  const capacity = isStaff ? usageBanner(acc?.usage, t.staff.billing) : null;
  const billingLocked = isStaff && acc?.is_read_only === true && acc.reason === 'billing';
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
      <MonitoringOrg orgId={org.id} />
      <LocaleSync />
      <div className="flex-1">
        {org.isPlatformOwner && (
          <div className="bg-purple-700 px-6 py-2 text-center text-sm font-semibold text-white print:hidden">
            {t.shell.platformOwner}
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
        {billingLocked && <LockedFormGuard message={billing?.text ?? t.shell.locked} />}
        {billing && (
          <div
            className={`px-6 py-2 text-center text-sm font-semibold print:hidden ${billing.tone === 'red' ? 'bg-red-600 text-white' : 'bg-amber-100 text-amber-900'}`}
          >
            {billing.text}
            {org.myRole === 'admin' && (
              <a href="/billing" className="ms-2 underline">
                {t.staff.billing.bannerLink}
              </a>
            )}
          </div>
        )}
        {capacity && (
          <div className={`px-6 py-2 text-center text-sm font-semibold print:hidden ${capacity.tone === 'red' ? 'bg-red-100 text-red-800' : 'bg-amber-100 text-amber-900'}`}>
            {capacity.text}
            {org.myRole === 'admin' && (
              <a href="/billing" className="ms-2 underline">
                {t.staff.billing.upgrade}
              </a>
            )}
          </div>
        )}
        {viewer && (
          <div className="bg-amber-500 px-6 py-2 text-center text-sm font-semibold text-white print:hidden">
            {t.shell.viewer}
          </div>
        )}
        <header className="sticky top-0 z-20 flex items-center justify-between gap-3 border-b bg-white/90 px-4 py-3 backdrop-blur sm:px-6 print:hidden">
          <a href="/" className="flex min-w-0 items-center gap-2 font-bold text-brand">
            <OrgLogo name={org.name} logoUrl={org.logoUrl} size={32} />
            <span className="truncate">{org.name}</span>
          </a>
          <div className="flex shrink-0 items-center gap-3 text-sm text-gray-500 sm:gap-4">
            {translated && <LanguageSwitcher />}
            <span className="hidden rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-600 sm:inline">{t.shell.roles[org.myRole] ?? org.myRole}</span>
            <form action={signOut} data-allow-locked>
              <SubmitButton className="hover:text-red-600" pendingText={t.shell.signingOut}>
                {t.shell.signOut}
              </SubmitButton>
            </form>
          </div>
        </header>
        <main>{children}</main>
        <GrowingTree corner />
      </div>
    </div>
  );
}
