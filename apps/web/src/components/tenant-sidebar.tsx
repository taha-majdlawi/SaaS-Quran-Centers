import type { ModuleKey } from '@/lib/permissions/modules';
import { getI18n } from '@/lib/i18n/server';
import { StaffNav, type NavSectionView } from '@/components/staff-nav';

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
  { slug: 'circles', label: 'الحلقات', adminOnly: true },
  { slug: 'stages', label: 'المراحل', adminOnly: true },
  { slug: 'attendance', label: 'الحضور', module: 'attendance' },
  { slug: 'gatherings', label: 'المجالس والأنشطة', module: 'attendance' },
  { slug: 'external-recitations', label: 'التسميع الخارجي', module: 'students' },
  { slug: 'reviews', label: 'المراجعة المقترحة' },
  { slug: 'search', label: 'بحث شامل' },
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
  { slug: 'fees', label: 'الرسوم', adminOnly: true, needsFees: true },
  { slug: 'members', label: 'الأعضاء والأدوار', adminOnly: true },
  { slug: 'deletion-requests', label: 'طلبات حذف البيانات', adminOnly: true },
  { slug: 'audit', label: 'سجل العمليات', adminOnly: true },
  { slug: 'site', label: 'الموقع العام', adminOnly: true },
  { slug: 'settings', label: 'إعدادات المركز', adminOnly: true },
  { slug: 'billing', label: 'الاشتراك والدفع', adminOnly: true },
] as const;

/** Which menu section each page sits in (same groups as the mobile app's drawer). */
const SECTION_OF: Record<string, 'teaching' | 'motivation' | 'comms' | 'admin' | null> = {
  dashboard: null, quran: null, search: null,
  students: 'teaching', teachers: 'teaching', circles: 'teaching', stages: 'teaching', attendance: 'teaching',
  gatherings: 'teaching', 'external-recitations': 'teaching', reviews: 'teaching', serd: 'teaching',
  points: 'motivation', badges: 'motivation', market: 'motivation', 'circle-challenges': 'motivation',
  activities: 'comms', calendar: 'comms', announcements: 'comms', chat: 'comms', notifications: 'comms', reports: 'comms', certificates: 'comms',
  fees: 'admin', members: 'admin', 'deletion-requests': 'admin', audit: 'admin', site: 'admin', settings: 'admin', billing: 'admin',
};
const SECTION_ORDER = [null, 'teaching', 'motivation', 'comms', 'admin'] as const;

export async function TenantSidebar({
  role,
  permissions,
  feesEnabled = false,
}: {
  role: 'admin' | 'teacher' | 'guardian' | 'student' | null;
  permissions: ModuleKey[];
  feesEnabled?: boolean;
}) {
  const S = (await getI18n()).t.staff;
  const visible = TENANT_MODULES.filter((m) => {
    if ('needsFees' in m && m.needsFees && !feesEnabled) return false; // optional feature (0081)
    if (role === 'admin') return true;
    if ('adminOnly' in m && m.adminOnly) return false;
    if (!('module' in m)) return true; // dashboard
    return permissions.includes(m.module as ModuleKey);
  });
  const sections: NavSectionView[] = SECTION_ORDER.map((sec) => ({
    title: sec ? (S.nav.sections[sec] ?? sec) : null,
    items: visible.filter((m) => (SECTION_OF[m.slug] ?? null) === sec).map((m) => ({ slug: m.slug, label: S.nav.items[m.slug] ?? m.label })),
  })).filter((s) => s.items.length);

  return <StaffNav sections={sections} menuLabel={S.nav.menu} />;
}
