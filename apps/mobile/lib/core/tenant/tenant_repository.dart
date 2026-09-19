import 'package:supabase_flutter/supabase_flutter.dart';

import 'organization.dart';

/// Reads the organizations (and the caller's role in each) that the
/// currently authenticated user belongs to. Backed entirely by RLS on
/// `organization_members` / `organizations` - no manual filtering needed,
/// Postgres only returns rows the caller is actually allowed to see.
class TenantRepository {
  TenantRepository(this._client);

  final SupabaseClient _client;

  Future<List<OrganizationMembership>> fetchMyMemberships() async {
    final rows = await _client
        .from('organization_members')
        .select('role, permissions, organizations(*)')
        .eq('user_id', _client.auth.currentUser?.id ?? '')
        .eq('status', 'active');

    return (rows as List).map((row) {
      final org = Organization.fromMap(row['organizations'] as Map<String, dynamic>);
      final role = OrgRole.values.byName(row['role'] as String);
      final permissions = ((row['permissions'] as List?) ?? const []).cast<String>();
      return OrganizationMembership(organization: org, role: role, permissions: permissions);
    }).toList();
  }
}
