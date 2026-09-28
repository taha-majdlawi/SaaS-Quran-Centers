/// Mirrors `apps/web/src/lib/permissions/modules.ts` and migration
/// `0015_module_permissions_and_family_scoping.sql`'s `member_has_module()`.
/// Keep this list, the web one, and the SQL module-key strings in sync -
/// they're compared as plain strings, not an enum, on both ends.
library;

import '../i18n/i18n.dart';

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
  'reports',
  'certificates',
];

/// Labels for the checkboxes on the member-permission editor, in the current language.
Map<String, String> get kModuleLabels => currentStrings.mem.modules;
