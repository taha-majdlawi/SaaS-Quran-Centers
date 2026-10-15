import { redirect } from 'next/navigation';
import { cookies, headers } from 'next/headers';
import { loginWithNext } from '@/lib/auth/next';
import { getPlatformContext } from '@/lib/platform/get-platform-context';
import { MFA_UNAVAILABLE_COOKIE } from '@/lib/platform/mfa';
import { SubmitButton } from '@/components/submit-button';
import { signOut } from '@/lib/auth/actions';
import { createClient } from '@/lib/supabase/server';
import { PlatformLogo } from '@/components/org-logo';
import {
  BellRing,
  Building2,
  Bug,
  CreditCard,
  Layers,
  LayoutDashboard,
  LogOut,
  Megaphone,
  ScrollText,
  Settings,
  ToggleLeft,
  Users,
  type LucideIcon,
} from 'lucide-react';

// Served on admin.{ROOT_DOMAIN} via middleware.ts. Replaces the legacy
// wep-eqraa-center/dev/ superadmin panel - now manages every tenant instead
// of one center's raw data.
export default async function PlatformProtectedLayout({ children }: { children: React.ReactNode }) {
  const platform = await getPlatformContext();

  // Not authenticated, or authenticated but not in `platform_owners` - RLS
  // would block every cross-tenant query anyway, so send them to sign in
  // rather than show an empty shell.
  if (!platform.isOwner) redirect(loginWithNext((await headers()).get('x-bustan-path')) as never);

  // the second factor (0094): enter the code, or set one up first. Only when Supabase
  // itself refused to set one up (MFA off for the project) does the console open without it.
  const mfaUnavailable = platform.mfa === 'enroll' && (await cookies()).get(MFA_UNAVAILABLE_COOKIE)?.value === '1';
  if (platform.mfa !== 'ok' && !mfaUnavailable) redirect('/mfa');

  // centers needing attention (0067) - the count shows next to the menu entry
  const supabase = await createClient();
  const { data: alerts } = await supabase.rpc('platform_billing_alerts');
  const alertCount = ((alerts as { rows?: unknown[] } | null)?.rows ?? []).length;
  const { data: openErrors } = await supabase.rpc('platform_open_error_count');
  const errorCount = Number(openErrors ?? 0);

  // the page being shown (middleware.ts): its menu entry is highlighted
  const here = '/' + (((await headers()).get('x-bustan-path') ?? '').split('/').filter(Boolean)[0] ?? '');
  const nav: { href: string; label: string; icon: LucideIcon; count?: number }[] = [
    { href: '/', label: 'نظرة عامة', icon: LayoutDashboard },
    { href: '/organizations', label: 'المراكز', icon: Building2 },
    { href: '/alerts', label: 'تنبيهات المراكز', icon: BellRing, count: alertCount },
    { href: '/errors', label: 'الأخطاء', icon: Bug, count: errorCount },
    { href: '/users', label: 'الحسابات', icon: Users },
    { href: '/plans', label: 'الخطط والحدود', icon: Layers },
    { href: '/billing', label: 'المدفوعات والاشتراكات', icon: CreditCard },
    { href: '/feature-flags', label: 'مفاتيح الميزات', icon: ToggleLeft },
    { href: '/notices', label: 'إشعارات للمراكز', icon: Megaphone },
    { href: '/settings', label: 'إعدادات المنصة', icon: Settings },
    { href: '/audit', label: 'سجل العمليات', icon: ScrollText },
  ];

  return (
    <div className="flex min-h-screen flex-col md:flex-row">
      <aside className="shrink-0 border-b border-gray-200 bg-white p-4 md:sticky md:top-0 md:h-screen md:w-64 md:overflow-y-auto md:border-b-0 md:border-e">
        <div className="mb-5 flex items-center gap-3 px-1">
          <PlatformLogo size={40} />
          <div className="leading-tight">
            <p className="font-bold text-brand">بستان القرآن</p>
            <p className="text-xs text-gray-500">لوحة مالك المنصة</p>
          </div>
        </div>
        {/* Relative to the root domain, not literally "/platform" - the
            browser is already on admin.bustan-alquran.com, and
            middleware.ts re-adds the /platform prefix on every request. */}
        <nav className="flex gap-1 overflow-x-auto text-sm md:flex-col md:overflow-visible">
          {nav.map(({ href, label, icon: Icon, count }) => {
            const active = here === href;
            return (
              <a
                key={href}
                href={href}
                aria-current={active ? 'page' : undefined}
                className={`flex shrink-0 items-center gap-2.5 rounded-lg px-3 py-2 transition-colors ${
                  active ? 'bg-brand/10 font-semibold text-brand' : 'text-gray-700 hover:bg-gray-50'
                }`}
              >
                <Icon size={17} className={active ? 'text-brand' : 'text-gray-400'} />
                <span className="flex-1 whitespace-nowrap">{label}</span>
                {!!count && <span className="rounded-full bg-red-500 px-2 text-xs font-bold text-white">{count}</span>}
              </a>
            );
          })}
        </nav>
        <form action={signOut} className="mt-5 border-t border-gray-100 pt-4">
          <SubmitButton className="flex items-center gap-2 px-1 text-sm text-gray-500 hover:text-red-600" pendingText="جاري الخروج...">
            <LogOut size={16} />
            تسجيل خروج <span className="text-xs text-gray-400" dir="ltr">{platform.email}</span>
          </SubmitButton>
        </form>
      </aside>
      <main className="min-w-0 flex-1 p-4 sm:p-8">
        {mfaUnavailable && (
          <p className="mb-6 rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-800">
            التحقق بخطوتين غير مفعّل بعد: Supabase رفض إعداده. فعّل TOTP من لوحة Supabase (Authentication ← Multi-Factor)، ثم{' '}
            <a href="/mfa" className="font-semibold underline">أعد المحاولة</a>.
          </p>
        )}
        {children}
      </main>
    </div>
  );
}
