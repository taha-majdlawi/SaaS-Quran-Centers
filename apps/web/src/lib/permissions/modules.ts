// Single source of truth for admin-configurable teacher module access.
// Keys must match: the `slug` used in tenant-sidebar.tsx nav entries, AND
// the module-key strings the DB migration 0015 uses in RLS's
// member_has_module(org_id, module) - changing a key here means updating
// both places.
export const MODULE_DEFS = [
  { key: 'students', label: 'الطلاب' },
  { key: 'circles', label: 'الحلقات' },
  { key: 'attendance', label: 'الحضور' },
  { key: 'serd', label: 'السرد القرآني وطلبات التسميع' },
  { key: 'points', label: 'النقاط' },
  { key: 'badges', label: 'الشارات' },
  { key: 'market', label: 'سوق النقاط' },
  { key: 'circle-challenges', label: 'منافسات الحلقات' },
  { key: 'activities', label: 'الأنشطة' },
  { key: 'calendar', label: 'التقويم' },
  { key: 'announcements', label: 'الإعلانات' },
  { key: 'chat', label: 'المحادثات' },
  { key: 'notifications', label: 'الإشعارات' },
] as const;

export type ModuleKey = (typeof MODULE_DEFS)[number]['key'];

export const ALL_MODULE_KEYS: ModuleKey[] = MODULE_DEFS.map((m) => m.key);

export function isModuleKey(value: string): value is ModuleKey {
  return (ALL_MODULE_KEYS as string[]).includes(value);
}
