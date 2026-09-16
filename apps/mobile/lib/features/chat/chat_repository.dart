import 'package:supabase_flutter/supabase_flutter.dart';

class ChatThreadSummary {
  const ChatThreadSummary({required this.id, required this.otherLabel, required this.createdAt});
  final String id;
  final String otherLabel;
  final String createdAt;
}

class ChatMemberOption {
  const ChatMemberOption({required this.userId, required this.label});
  final String userId;
  final String label;
}

class ChatMessage {
  const ChatMessage({required this.id, required this.senderId, required this.body, required this.createdAt});
  final String id;
  final String senderId;
  final String body;
  final String createdAt;

  /// Builds from a raw row map - shared by the plain select above and by
  /// core/chat/chat_realtime.dart's Postgres Changes payload, which hands
  /// back the same column shape.
  factory ChatMessage.fromRecord(Map<String, dynamic> r) {
    return ChatMessage(
      id: r['id'] as String,
      senderId: r['sender_id'] as String,
      body: (r['body'] as String?) ?? '',
      createdAt: r['created_at'] as String,
    );
  }
}

/// Mirrors apps/web's chat/actions.ts - 1:1 threads. Realtime message
/// delivery (core/chat/chat_realtime.dart) is mobile-only so far; apps/web
/// still just reloads after sending, same as this repository's messages
/// used to work before that.
class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;

  Future<List<ChatMemberOption>> fetchMembers(String organizationId) async {
    final rows = await _client.rpc('list_org_members', params: {'org_id': organizationId});
    return (rows as List)
        .map((r) => ChatMemberOption(
              userId: r['user_id'] as String,
              label: (r['full_name'] as String?) ?? (r['email'] as String?) ?? '—',
            ))
        .toList();
  }

  Future<List<ChatThreadSummary>> fetchMyThreads(String myUserId) async {
    final myThreadIds = await _client.from('chat_thread_participants').select('thread_id').eq('user_id', myUserId);
    final threadIds = (myThreadIds as List).map((r) => r['thread_id'] as String).toList();
    if (threadIds.isEmpty) return [];

    final organizationId = await _orgIdForThread(threadIds.first);
    final results = await Future.wait<dynamic>([
      _client
          .from('chat_threads')
          .select('id, title, created_at, chat_thread_participants(user_id)')
          .inFilter('id', threadIds)
          .order('created_at', ascending: false),
      _client.rpc('list_org_members', params: {'org_id': organizationId}),
    ]);
    final threads = results[0] as List;
    final members = results[1] as List;
    final nameByUserId = {
      for (final m in members)
        m['user_id'] as String: (m['full_name'] as String?) ?? (m['email'] as String?) ?? '—',
    };

    return threads.map((t) {
      final participants = (t['chat_thread_participants'] as List)
          .map((p) => p['user_id'] as String)
          .where((id) => id != myUserId)
          .toList();
      final otherLabel = participants.isNotEmpty
          ? participants.map((id) => nameByUserId[id] ?? '—').join('، ')
          : ((t['title'] as String?) ?? 'محادثة');
      return ChatThreadSummary(id: t['id'] as String, otherLabel: otherLabel, createdAt: t['created_at'] as String);
    }).toList();
  }

  Future<String> _orgIdForThread(String threadId) async {
    final row = await _client.from('chat_threads').select('organization_id').eq('id', threadId).single();
    return row['organization_id'] as String;
  }

  Future<String> createThread({required String organizationId, required String myUserId, required String otherUserId}) async {
    final thread = await _client
        .from('chat_threads')
        .insert({'organization_id': organizationId, 'is_group': false, 'created_by': myUserId})
        .select('id')
        .single();
    final threadId = thread['id'] as String;

    await _client.from('chat_thread_participants').insert([
      {'thread_id': threadId, 'user_id': myUserId},
      {'thread_id': threadId, 'user_id': otherUserId},
    ]);

    return threadId;
  }

  Future<List<ChatMessage>> fetchMessages(String threadId) async {
    final rows = await _client
        .from('chat_messages')
        .select('id, sender_id, body, created_at')
        .eq('thread_id', threadId)
        .order('created_at');
    return (rows as List).map((r) => ChatMessage.fromRecord(r as Map<String, dynamic>)).toList();
  }

  Future<ChatMessage> sendMessage({required String threadId, required String senderId, required String body}) async {
    final row = await _client
        .from('chat_messages')
        .insert({'thread_id': threadId, 'sender_id': senderId, 'body': body})
        .select('id, sender_id, body, created_at')
        .single();
    return ChatMessage.fromRecord(row);
  }
}
