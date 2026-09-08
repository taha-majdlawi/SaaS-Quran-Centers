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
  const OrganizationMembership({required this.organization, required this.role});

  final Organization organization;
  final OrgRole role;
}
