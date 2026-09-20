import type { ModuleKey } from '@/lib/permissions/modules';

// Single source of truth for the tenant admin nav - the legacy admin/ had
// this list implicitly, duplicated as 20+ separate <nav> blocks copy-pasted
// across static HTML files. Here it is written once.
//
// `module` is optional: entries without one (dashboard, teachers, stages,
// members, audit, site, settings) are staff-structural pages every admin
// and teacher can reach regardless of the admin-configured module list -
// only entries WITH a module key are gated by it (see get-org-context.ts /
// migration 0015's member_has_module()).
export const TENANT_MODULES = [
  { slug: 'dashboard', label: 'لوحة التحكم' },
  { slug: 'quran', label: 'المصحف' },
  { slug: 'students', label: 'الطلاب', module: 'students' },
  { slug: 'teachers', label: 'المعلمون', adminOnly: true },
  { slug: 'circles', label: 'الحلقات', module: 'circles' },
  { slug: 'stages', label: 'المراحل', adminOnly: true },
  { slug: 'attendance', label: 'الحضور', module: 'attendance' },
  { slug: 'serd', label: 'السرد القرآني', module: 'serd' },
  { slug: 'points', label: 'النقاط', module: 'points' },
  { slug: 'badges', label: 'الشارات', module: 'badges' },
  { slug: 'market', label: 'سوق النقاط', module: 'market' },
  { slug: 'circle-challenges', label: 'منافسات الحلقات', module: 'circle-challenges' },
  { slug: 'activities', label: 'الأنشطة', module: 'activities' },
  { slug: 'calendar', label: 'التقويم', module: 'calendar' },
  { slug: 'announcements', label: 'الإعلانات', module: 'announcements' },
  { slug: 'chat', label: 'المحادثات', module: 'chat' },
  { slug: 'notifications', label: 'الإشعارات' },
  { slug: 'reports', label: 'التقارير', module: 'reports' },
  { slug: 'certificates', label: 'الشهادات', module: 'certificates' },
  { slug: 'members', label: 'الأعضاء والأدوار', adminOnly: true },
  { slug: 'deletion-requests', label: 'طلبات حذف البيانات', adminOnly: true },
  { slug: 'audit', label: 'سجل العمليات', adminOnly: true },
  { slug: 'site', label: 'الموقع العام', adminOnly: true },
  { slug: 'settings', label: 'إعدادات المركز', adminOnly: true },
] as const;

export function TenantSidebar({
  activeSlug,
  role,
  permissions,
}: {
  activeSlug?: string;
  role: 'admin' | 'teacher' | 'guardian' | 'student' | null;
  permissions: ModuleKey[];
}) {
  const visible = TENANT_MODULES.filter((m) => {
    if (role === 'admin') return true;
    if ('adminOnly' in m && m.adminOnly) return false;
    if (!('module' in m)) return true; // dashboard
    return permissions.includes(m.module as ModuleKey);
  });

  return (
    <aside className="w-64 shrink-0 border-l bg-white p-4 print:hidden">
      <nav className="flex flex-col gap-1 text-sm">
        {visible.map((m) => (
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
