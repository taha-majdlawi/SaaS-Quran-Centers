/// Mirrors `apps/web/src/lib/permissions/modules.ts` and migration
/// `0015_module_permissions_and_family_scoping.sql`'s `member_has_module()`.
/// Keep this list, the web one, and the SQL module-key strings in sync -
/// they're compared as plain strings, not an enum, on both ends.
const List<String> kModuleKeys = [
  'students',
  'circles',
  'attendance',
  'serd',
  'points',
  'badges',
  'market',
  'circle-challenges',
  'activities',
  'calendar',
  'announcements',
  'chat',
  'notifications',
];

/// Arabic labels for the checkboxes on the member-permission editor.
const Map<String, String> kModuleLabels = {
  'students': 'الطلاب',
  'circles': 'الحلقات',
  'attendance': 'الحضور',
  'serd': 'السرد القرآني وطلبات التسميع',
  'points': 'النقاط',
  'badges': 'الشارات',
  'market': 'سوق النقاط',
  'circle-challenges': 'منافسات الحلقات',
  'activities': 'الأنشطة',
  'calendar': 'التقويم',
  'announcements': 'الإعلانات',
  'chat': 'المحادثات',
  'notifications': 'الإشعارات',
};
