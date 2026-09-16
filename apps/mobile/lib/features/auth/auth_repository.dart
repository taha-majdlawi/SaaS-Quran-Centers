import 'package:supabase_flutter/supabase_flutter.dart';

class InvitationPreview {
  const InvitationPreview({required this.organizationName, required this.email, required this.role});
  final String organizationName;
  final String email;
  final String role;
}

/// Backs the two account-creation paths that don't fit the plain sign-in
/// screen: self-serve org creation (mirrors apps/web's /signup) and
/// accepting an admin's invitation by token (mirrors apps/web's [org]/join).
/// Both go through SECURITY DEFINER RPCs (migrations 0010/0011) since the
/// plain organizations/organization_invitations RLS policies don't allow
/// either action directly - see those migrations for why.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  /// Throws a PostgrestException with code 23505 if the slug is taken.
  Future<void> createOrganizationWithOwner({required String orgName, required String orgSlug}) {
    return _client.rpc('create_organization_with_owner', params: {'org_name': orgName, 'org_slug': orgSlug});
  }

  /// Null for an unknown, expired, or already-accepted token - get_invitation
  /// always returns exactly one row (with nulls) rather than zero, see 0011.
  Future<InvitationPreview?> getInvitation(String token) async {
    final rows = await _client.rpc('get_invitation', params: {'invite_token': token});
    final row = (rows as List).isEmpty ? null : rows.first as Map<String, dynamic>;
    if (row == null || row['valid'] != true) return null;
    return InvitationPreview(
      organizationName: row['organization_name'] as String,
      email: row['email'] as String,
      role: row['role'] as String,
    );
  }

  Future<void> acceptInvitation(String token) {
    return _client.rpc('accept_invitation', params: {'invite_token': token});
  }
}
