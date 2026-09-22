class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.primaryColor = '#1E7A54',
    this.secondaryColor = '#D4A24C',
  });

  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String primaryColor;
  final String secondaryColor;

  factory Organization.fromMap(Map<String, dynamic> map) {
    return Organization(
      id: map['id'] as String,
      name: map['name'] as String,
      slug: map['slug'] as String,
      logoUrl: map['logo_url'] as String?,
      primaryColor: (map['primary_color'] as String?) ?? '#1E7A54',
      secondaryColor: (map['secondary_color'] as String?) ?? '#D4A24C',
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
  /// [hasModule], students/guardians never carry any (they use the
  /// dedicated student/guardian dashboards instead of module screens).
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
