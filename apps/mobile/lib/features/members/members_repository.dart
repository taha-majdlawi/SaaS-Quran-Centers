import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';

Map<String, String> get kMemberRoleLabels => currentStrings.labels.roles;
Map<String, String> get kMemberStatusLabels => currentStrings.mem.status;

class MemberRow {
  const MemberRow({
    required this.id,
    required this.userId,
    required this.role,
    required this.status,
    required this.permissions,
    this.fullName,
    this.email,
  });

  final String id;
  final String userId;
  final String role;
  final String status;
  final List<String> permissions;
  final String? fullName;
  final String? email;
}

class PendingInvitation {
  const PendingInvitation({required this.email, required this.role, required this.token});
  final String email;
  final String role;
  final String token;
}

/// Mirrors apps/web's members/actions.ts - invitation creation goes through
/// the create_invitation() SECURITY DEFINER RPC (same as web), role/status/
/// permission edits and removal are plain RLS-backed updates. Deliberately
/// does NOT replicate teachers/actions.ts's updateTeacherAccount (email/
/// password changes) - that needs the service_role key, which must stay
/// server-side only and has no safe equivalent in a distributed mobile app.
class MembersRepository {
  MembersRepository(this._client);

  final SupabaseClient _client;

  Future<List<MemberRow>> fetchMembers(String organizationId) async {
    final rows = await _client.rpc('list_org_members', params: {'org_id': organizationId});
    return (rows as List)
        .map((r) => MemberRow(
              id: r['id'] as String,
              userId: r['user_id'] as String,
              role: r['role'] as String,
              status: r['status'] as String,
              permissions: ((r['permissions'] as List?) ?? const []).cast<String>(),
              fullName: r['full_name'] as String?,
              email: r['email'] as String?,
            ))
        .toList();
  }

  Future<List<PendingInvitation>> fetchPendingInvitations(String organizationId) async {
    final rows = await _client.rpc('list_org_invitations', params: {'org_id': organizationId});
    return (rows as List)
        .where((r) => r['accepted_at'] == null)
        .map((r) => PendingInvitation(email: r['email'] as String, role: r['role'] as String, token: r['token'] as String))
        .toList();
  }

  Future<void> createInvitation({required String organizationId, required String email, required String role}) {
    return _client.rpc('create_invitation', params: {
      'org_id': organizationId,
      'invite_email': email,
      'invite_role': role,
    });
  }

  Future<void> updateMember({
    required String id,
    required String role,
    required String status,
    required List<String> permissions,
  }) {
    return _client.from('organization_members').update({
      'role': role,
      'status': status,
      'permissions': permissions,
    }).eq('id', id);
  }

  /// Is this member's account a viewing (read-only) one? (admin only)
  Future<bool> isViewer(String orgId, String userId) async {
    final rows = await _client.rpc('list_account_flags', params: {'p_org': orgId}) as List;
    return rows.any((r) => r['user_id'] == userId);
  }

  Future<void> setViewer(String orgId, String userId, bool viewer) =>
      _client.rpc('set_account_access', params: {'p_org': orgId, 'p_user': userId, 'p_read_only': viewer});

  Future<void> removeMember(String id) {
    return _client.from('organization_members').delete().eq('id', id);
  }
}
