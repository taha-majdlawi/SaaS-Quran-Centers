import 'package:flutter/painting.dart' show Color;

const kDefaultBrandPrimary = Color(0xFF0F766E);
const kDefaultBrandSecondary = Color(0xFFF59E0B);

/// Parses an "#rrggbb" hex string (as stored in `organizations.primary_color`
/// / `.secondary_color`) into a Color - null on anything malformed rather
/// than throwing, since this is admin-typed free text with no format
/// validation on the way in (see settings_screen.dart).
Color? parseHexColor(String hex) {
  var value = hex.trim();
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  final intValue = int.tryParse(value, radix: 16);
  return intValue == null ? null : Color(intValue);
}

class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.primaryColor = '#0f766e',
    this.secondaryColor = '#f59e0b',
  });

  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String primaryColor;
  final String secondaryColor;

  Color get primaryColorValue => parseHexColor(primaryColor) ?? kDefaultBrandPrimary;
  Color get secondaryColorValue => parseHexColor(secondaryColor) ?? kDefaultBrandSecondary;

  factory Organization.fromMap(Map<String, dynamic> map) {
    return Organization(
      id: map['id'] as String,
      name: map['name'] as String,
      slug: map['slug'] as String,
      logoUrl: map['logo_url'] as String?,
      primaryColor: (map['primary_color'] as String?) ?? '#0f766e',
      secondaryColor: (map['secondary_color'] as String?) ?? '#f59e0b',
    );
  }
}

/// Mirrors `organization_members.role` (see 0001_core_tenancy.sql) - the
/// role a user holds in ONE specific organization, not globally.
enum OrgRole { student, teacher, admin, guardian }

class OrganizationMembership {
  const OrganizationMembership({
    required this.organization,
    required this.role,
    this.permissions = const [],
  });

  final Organization organization;
  final OrgRole role;

  /// Module keys this member was granted (see `core/access/module_keys.dart`).
  /// Only meaningful for `role == teacher` - admins bypass it entirely via
  /// [hasModule], students/guardians never carry any (they land on
  /// `features/my_portal` instead of any module screen - see app_router.dart).
  final List<String> permissions;

  /// Mirrors the SQL `member_has_module()` function (migration 0015): admins
  /// always pass, teachers need the module in their granted list, students
  /// and guardians never pass - RLS enforces the same rule server-side, this
  /// is only so screens can hide controls instead of showing a Postgres error.
  bool hasModule(String moduleKey) {
    if (role == OrgRole.admin) return true;
    if (role == OrgRole.teacher) return permissions.contains(moduleKey);
    return false;
  }
}
