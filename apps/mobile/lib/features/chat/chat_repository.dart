import 'package:supabase_flutter/supabase_flutter.dart';

class ChatThreadSummary {
  const ChatThreadSummary({
    required this.id,
    required this.otherLabel,
    required this.createdAt,
    required this.hasUnread,
  });
  final String id;
  final String otherLabel;
  final String createdAt;
  final bool hasUnread;
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

  /// Every active org member - only an admin should offer this as the "new
  /// chat" picker source (admins can message anyone); everyone else should
  /// use [fetchMyContacts] instead. Also the source list for the admin's
  /// contact picker in member_edit_screen.dart.
  Future<List<ChatMemberOption>> fetchMembers(String organizationId) async {
    final rows = await _client.rpc('list_org_members', params: {'org_id': organizationId});
    return (rows as List)
        .map((r) => ChatMemberOption(
              userId: r['user_id'] as String,
              label: (r['full_name'] as String?) ?? (r['email'] as String?) ?? '—',
            ))
        .toList();
  }

  /// Who [myUserId] is allowed to message, per the admin-curated
  /// chat_contacts list (migration 0020) - this is what new_chat_screen.dart
  /// shows a non-admin, instead of every org member.
  Future<List<ChatMemberOption>> fetchMyContacts(String organizationId, String myUserId) async {
    final results = await Future.wait<dynamic>([
      _client.from('chat_contacts').select('contact_user_id').eq('organization_id', organizationId).eq('user_id', myUserId),
      _client.rpc('list_org_members', params: {'org_id': organizationId}),
    ]);
    final contactRows = results[0] as List;
    final members = results[1] as List;
    final contactIds = contactRows.map((r) => r['contact_user_id'] as String).toSet();
    return members
        .where((m) => contactIds.contains(m['user_id']))
        .map((m) => ChatMemberOption(
              userId: m['user_id'] as String,
              label: (m['full_name'] as String?) ?? (m['email'] as String?) ?? '—',
            ))
        .toList();
  }

  /// Admin-only (enforced by RLS) - the set of user ids [userId] is
  /// currently allowed to message, for member_edit_screen.dart's picker.
  Future<Set<String>> fetchContactUserIds(String organizationId, String userId) async {
    final rows = await _client
        .from('chat_contacts')
        .select('contact_user_id')
        .eq('organization_id', organizationId)
        .eq('user_id', userId);
    return (rows as List).map((r) => r['contact_user_id'] as String).toSet();
  }

  /// Admin-only (enforced by RLS) - replaces [userId]'s allowed contacts
  /// with exactly [contactUserIds], both directions (so the other side can
  /// message back without a second, separate grant).
  Future<void> setContacts({
    required String organizationId,
    required String userId,
    required Set<String> contactUserIds,
  }) async {
    final current = await fetchContactUserIds(organizationId, userId);
    final toAdd = contactUserIds.difference(current);
    final toRemove = current.difference(contactUserIds);

    if (toRemove.isNotEmpty) {
      await _client
          .from('chat_contacts')
          .delete()
          .eq('organization_id', organizationId)
          .eq('user_id', userId)
          .inFilter('contact_user_id', toRemove.toList());
      await _client
          .from('chat_contacts')
          .delete()
          .eq('organization_id', organizationId)
          .inFilter('user_id', toRemove.toList())
          .eq('contact_user_id', userId);
    }

    if (toAdd.isNotEmpty) {
      final me = _client.auth.currentUser?.id;
      // upsert + ignoreDuplicates rather than insert: the reverse-direction
      // row (contactId -> userId) may already exist independently (e.g. if
      // contactId is an admin, who has everyone as a contact from the 0020
      // seed already) - a plain insert would hit the unique constraint and
      // fail the whole batch.
      await _client.from('chat_contacts').upsert(
        [
          for (final contactId in toAdd) ...[
            {'organization_id': organizationId, 'user_id': userId, 'contact_user_id': contactId, 'created_by': me},
            {'organization_id': organizationId, 'user_id': contactId, 'contact_user_id': userId, 'created_by': me},
          ],
        ],
        onConflict: 'organization_id,user_id,contact_user_id',
        ignoreDuplicates: true,
      );
    }
  }

  Future<List<ChatThreadSummary>> fetchMyThreads(String myUserId) async {
    final myParticipantRows = await _client
        .from('chat_thread_participants')
        .select('thread_id, last_read_at')
        .eq('user_id', myUserId);
    final myRows = myParticipantRows as List;
    final threadIds = myRows.map((r) => r['thread_id'] as String).toList();
    if (threadIds.isEmpty) return [];
    final lastReadByThread = {for (final r in myRows) r['thread_id'] as String: r['last_read_at'] as String?};

    final organizationId = await _orgIdForThread(threadIds.first);
    final results = await Future.wait<dynamic>([
      _client
          .from('chat_threads')
          .select('id, title, created_at, chat_thread_participants(user_id)')
          .inFilter('id', threadIds)
          .order('created_at', ascending: false),
      _client.rpc('list_org_members', params: {'org_id': organizationId}),
      // Cheap columns only, across every message in every one of my threads -
      // this app is 1:1 chat with no group threads yet, so volume stays low
      // enough that reducing "latest per thread" client-side (below) is
      // simpler than a per-thread-LIMIT-1 query PostgREST can't express in
      // one call anyway.
      _client.from('chat_messages').select('thread_id, created_at').inFilter('thread_id', threadIds).order(
        'created_at',
        ascending: false,
      ),
    ]);
    final threads = results[0] as List;
    final members = results[1] as List;
    final messages = results[2] as List;
    final nameByUserId = {
      for (final m in members)
        m['user_id'] as String: (m['full_name'] as String?) ?? (m['email'] as String?) ?? '—',
    };

    final latestMessageByThread = <String, String>{};
    for (final m in messages) {
      latestMessageByThread.putIfAbsent(m['thread_id'] as String, () => m['created_at'] as String);
    }

    return threads.map((t) {
      final id = t['id'] as String;
      final participants = (t['chat_thread_participants'] as List)
          .map((p) => p['user_id'] as String)
          .where((pid) => pid != myUserId)
          .toList();
      final otherLabel = participants.isNotEmpty
          ? participants.map((pid) => nameByUserId[pid] ?? '—').join('، ')
          : ((t['title'] as String?) ?? 'محادثة');

      final lastRead = lastReadByThread[id];
      final latestMessage = latestMessageByThread[id];
      final hasUnread = latestMessage != null &&
          (lastRead == null || DateTime.parse(latestMessage).isAfter(DateTime.parse(lastRead)));

      return ChatThreadSummary(
        id: id,
        otherLabel: otherLabel,
        createdAt: t['created_at'] as String,
        hasUnread: hasUnread,
      );
    }).toList();
  }

  Future<void> markThreadRead({required String threadId, required String userId}) {
    return _client
        .from('chat_thread_participants')
        .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('thread_id', threadId)
        .eq('user_id', userId);
  }

  Future<String> _orgIdForThread(String threadId) async {
    final row = await _client.from('chat_threads').select('organization_id').eq('id', threadId).single();
    return row['organization_id'] as String;
  }

  /// Throws if [otherUserId] isn't in my contact list and I'm not an admin
  /// (chat_participants_insert, migration 0020) - cleans up the otherwise-
  /// orphaned empty thread it just created before rethrowing, rather than
  /// leaving a stray single-participant thread behind.
  Future<String> createThread({required String organizationId, required String myUserId, required String otherUserId}) async {
    final thread = await _client
        .from('chat_threads')
        .insert({'organization_id': organizationId, 'is_group': false, 'created_by': myUserId})
        .select('id')
        .single();
    final threadId = thread['id'] as String;

    try {
      await _client.from('chat_thread_participants').insert([
        {'thread_id': threadId, 'user_id': myUserId},
        {'thread_id': threadId, 'user_id': otherUserId},
      ]);
    } catch (e) {
      await _client.from('chat_threads').delete().eq('id', threadId);
      rethrow;
    }

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
