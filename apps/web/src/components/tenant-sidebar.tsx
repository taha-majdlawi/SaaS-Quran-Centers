// Single source of truth for the tenant admin nav - the legacy admin/ had
// this list implicitly, duplicated as 20+ separate <nav> blocks copy-pasted
// across static HTML files. Here it is written once.
export const TENANT_MODULES = [
  { slug: 'dashboard', label: 'لوحة التحكم' },
  { slug: 'students', label: 'الطلاب' },
  { slug: 'teachers', label: 'المعلمون' },
  { slug: 'circles', label: 'الحلقات' },
  { slug: 'stages', label: 'المراحل' },
  { slug: 'attendance', label: 'الحضور' },
  { slug: 'serd', label: 'السرد القرآني' },
  { slug: 'recitation-requests', label: 'طلبات التسميع' },
  { slug: 'points', label: 'النقاط' },
  { slug: 'badges', label: 'الشارات' },
  { slug: 'market', label: 'سوق النقاط' },
  { slug: 'circle-challenges', label: 'منافسات الحلقات' },
  { slug: 'activities', label: 'الأنشطة' },
  { slug: 'calendar', label: 'التقويم' },
  { slug: 'announcements', label: 'الإعلانات' },
  { slug: 'chat', label: 'المحادثات' },
  { slug: 'notifications', label: 'الإشعارات' },
  { slug: 'members', label: 'الأعضاء والأدوار' },
  { slug: 'audit', label: 'سجل العمليات' },
  { slug: 'site', label: 'الموقع العام' },
  { slug: 'settings', label: 'إعدادات المركز' },
] as const;

export function TenantSidebar({ activeSlug }: { activeSlug?: string }) {
  return (
    <aside className="w-64 shrink-0 border-l bg-white p-4">
      <nav className="flex flex-col gap-1 text-sm">
        {TENANT_MODULES.map((m) => (
          <a
            key={m.slug}
            // Relative to the root domain, not `/[org]` - the browser is
            // already on `{slug}.bustan-alquran.com`, and middleware.ts
            // re-derives `org` from that hostname on every request.
            href={`/${m.slug === 'dashboard' ? '' : m.slug}`}
            className={`rounded px-3 py-2 hover:bg-gray-100 ${
              activeSlug === m.slug ? 'bg-brand/10 font-semibold text-brand' : 'text-gray-700'
            }`}
          >
            {m.label}
          </a>
        ))}
      </nav>
    </aside>
  );
}
