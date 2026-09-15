import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationLogEntry {
  const NotificationLogEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.sentAt,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final String sentAt;
  final String? readAt;
}

class NotificationRecipientOption {
  const NotificationRecipientOption({required this.userId, required this.label});
  final String userId;
  final String label;
}

/// Mirrors apps/web's notifications/actions.ts - an in-app notification log,
/// sent to one member at a time.
class NotificationsRepository {
  NotificationsRepository(this._client);

  final SupabaseClient _client;

  Future<List<NotificationLogEntry>> fetchLog(String organizationId) async {
    final rows = await _client
        .from('notification_log')
        .select('id, title, body, sent_at, read_at')
        .eq('organization_id', organizationId)
        .order('sent_at', ascending: false)
        .limit(50);
    return (rows as List)
        .map((r) => NotificationLogEntry(
              id: r['id'] as String,
              title: r['title'] as String,
              body: r['body'] as String,
              sentAt: r['sent_at'] as String,
              readAt: r['read_at'] as String?,
            ))
        .toList();
  }

  Future<List<NotificationRecipientOption>> fetchMembers(String organizationId) async {
    final rows = await _client.rpc('list_org_members', params: {'org_id': organizationId});
    return (rows as List)
        .map((r) => NotificationRecipientOption(
              userId: r['user_id'] as String,
              label: (r['full_name'] as String?) ?? (r['email'] as String?) ?? '—',
            ))
        .toList();
  }

  Future<void> sendNotification({
    required String organizationId,
    required String userId,
    required String title,
    required String body,
  }) {
    return _client.from('notification_log').insert({
      'organization_id': organizationId,
      'user_id': userId,
      'channel': 'in_app',
      'title': title,
      'body': body,
    });
  }
}
