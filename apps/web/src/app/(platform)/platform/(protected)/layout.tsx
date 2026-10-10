import { redirect } from 'next/navigation';
import { cookies } from 'next/headers';
import { getPlatformContext } from '@/lib/platform/get-platform-context';
import { MFA_UNAVAILABLE_COOKIE } from '@/lib/platform/mfa';
import { SubmitButton } from '@/components/submit-button';
import { signOut } from '@/lib/auth/actions';
import { createClient } from '@/lib/supabase/server';

// Served on admin.{ROOT_DOMAIN} via middleware.ts. Replaces the legacy
// wep-eqraa-center/dev/ superadmin panel - now manages every tenant instead
// of one center's raw data.
export default async function PlatformProtectedLayout({ children }: { children: React.ReactNode }) {
  const platform = await getPlatformContext();

  // Not authenticated, or authenticated but not in `platform_owners` - RLS
  // would block every cross-tenant query anyway, so send them to sign in
  // rather than show an empty shell.
  if (!platform.isOwner) redirect('/login');

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

  return (
    <div className="flex min-h-screen">
      <aside className="w-64 shrink-0 border-l bg-gray-900 p-4 text-white">
        <h2 className="mb-6 text-lg font-bold">لوحة مالك المنصة</h2>
        {/* Relative to the root domain, not literally "/platform" - the
            browser is already on admin.bustan-alquran.com, and
            middleware.ts re-adds the /platform prefix on every request. */}
        <nav className="flex flex-col gap-2 text-sm">
          <a href="/" className="rounded px-3 py-2 hover:bg-gray-800">
            نظرة عامة
          </a>
          <a href="/organizations" className="rounded px-3 py-2 hover:bg-gray-800">
            المراكز
          </a>
          <a href="/alerts" className="flex items-center justify-between rounded px-3 py-2 hover:bg-gray-800">
            تنبيهات المراكز
            {alertCount > 0 && <span className="rounded-full bg-red-500 px-2 text-xs font-bold text-white">{alertCount}</span>}
          </a>
          <a href="/errors" className="flex items-center justify-between rounded px-3 py-2 hover:bg-gray-800">
            الأخطاء
            {errorCount > 0 && <span className="rounded-full bg-red-500 px-2 text-xs font-bold text-white">{errorCount}</span>}
          </a>
          <a href="/users" className="rounded px-3 py-2 hover:bg-gray-800">
            الحسابات
          </a>
          <a href="/plans" className="rounded px-3 py-2 hover:bg-gray-800">
            الخطط والحدود
          </a>
          <a href="/billing" className="rounded px-3 py-2 hover:bg-gray-800">
            المدفوعات والاشتراكات
          </a>
          <a href="/feature-flags" className="rounded px-3 py-2 hover:bg-gray-800">
            مفاتيح الميزات
          </a>
          <a href="/notices" className="rounded px-3 py-2 hover:bg-gray-800">
            إشعارات للمراكز
          </a>
          <a href="/settings" className="rounded px-3 py-2 hover:bg-gray-800">
            إعدادات المنصة
          </a>
          <a href="/audit" className="rounded px-3 py-2 hover:bg-gray-800">
            سجل العمليات
          </a>
        </nav>
        <form action={signOut} className="mt-6 border-t border-gray-700 pt-4">
          <SubmitButton className="text-sm text-gray-400 hover:text-red-400" pendingText="جاري الخروج...">
            تسجيل خروج ({platform.email})
          </SubmitButton>
        </form>
      </aside>
      <main className="flex-1 p-8">
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
