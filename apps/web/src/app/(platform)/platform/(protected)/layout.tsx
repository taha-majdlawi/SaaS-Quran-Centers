import { redirect } from 'next/navigation';
import { getPlatformContext } from '@/lib/platform/get-platform-context';
import { signOut } from '@/lib/auth/actions';

// Served on admin.{ROOT_DOMAIN} via middleware.ts. Replaces the legacy
// wep-eqraa-center/dev/ superadmin panel - now manages every tenant instead
// of one center's raw data.
export default async function PlatformProtectedLayout({ children }: { children: React.ReactNode }) {
  const platform = await getPlatformContext();

  // Not authenticated, or authenticated but not in `platform_owners` - RLS
  // would block every cross-tenant query anyway, so send them to sign in
  // rather than show an empty shell.
  if (!platform.isOwner) redirect('/login');

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
            المراكز (Tenants)
          </a>
          <a href="/plans" className="rounded px-3 py-2 hover:bg-gray-800">
            الخطط والاشتراكات
          </a>
          <a href="/feature-flags" className="rounded px-3 py-2 hover:bg-gray-800">
            أعلام الميزات
          </a>
        </nav>
        <form action={signOut} className="mt-6 border-t border-gray-700 pt-4">
          <button type="submit" className="text-sm text-gray-400 hover:text-red-400">
            تسجيل خروج ({platform.email})
          </button>
        </form>
      </aside>
      <main className="flex-1 p-8">{children}</main>
    </div>
  );
}
