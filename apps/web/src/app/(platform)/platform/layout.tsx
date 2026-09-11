// Served on admin.{ROOT_DOMAIN} via middleware.ts. Replaces the legacy
// wep-eqraa-center/dev/ superadmin panel - now manages every tenant instead
// of one center's raw data. Real auth guard (must be in `platform_owners`)
// belongs here once auth is wired up.

export default function PlatformLayout({ children }: { children: React.ReactNode }) {
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
      </aside>
      <main className="flex-1 p-8">{children}</main>
    </div>
  );
}
