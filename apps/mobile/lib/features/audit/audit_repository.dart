import 'package:supabase_flutter/supabase_flutter.dart';

const kAuditActionLabels = {'delete': 'حذف', 'update': 'تعديل', 'create': 'إضافة'};
const kAuditTableLabels = {
  'students_profile': 'طالب',
  'circles': 'حلقة',
  'stages': 'مرحلة',
  'serd_sessions': 'جلسة سرد',
  'organization_members': 'عضو',
};

class AuditEntry {
  const AuditEntry({
    required this.actorName,
    required this.action,
    required this.entityTable,
    required this.createdAt,
  });

  final String actorName;
  final String action;
  final String entityTable;
  final String createdAt;
}

/// Mirrors apps/web's /audit page - admin-only (audit_log_select_admin RLS).
class AuditRepository {
  AuditRepository(this._client);

  final SupabaseClient _client;

  Future<List<AuditEntry>> fetchLog(String organizationId) async {
    final results = await Future.wait<dynamic>([
      _client
          .from('audit_log')
          .select('id, actor_id, action, entity_table, entity_id, created_at')
          .eq('organization_id', organizationId)
          .order('created_at', ascending: false)
          .limit(100),
      _client.rpc('list_org_members', params: {'org_id': organizationId}),
    ]);
    final entries = results[0] as List;
    final members = results[1] as List;
    final nameByUserId = {
      for (final m in members) m['user_id'] as String: (m['full_name'] as String?) ?? (m['email'] as String?) ?? '—',
    };

    return entries
        .map((e) => AuditEntry(
              actorName: nameByUserId[e['actor_id']] ?? '—',
              action: e['action'] as String,
              entityTable: e['entity_table'] as String,
              createdAt: e['created_at'] as String,
            ))
        .toList();
  }
}
