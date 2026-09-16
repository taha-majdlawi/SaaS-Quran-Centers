import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client.dart';
import '../../features/chat/chat_repository.dart';

/// Wraps a Supabase Realtime (Postgres Changes) subscription on
/// chat_messages for one thread - chat_thread_screen.dart is the only user
/// so far, but this lives in core/ rather than features/chat so a future
/// unread-badge or thread-list-reorder listener can reuse the same small
/// wrapper instead of hand-rolling channel setup again.
///
/// RLS still applies to the underlying replication stream (chat_messages'
/// policies gate this the same as a plain select would), so this can't leak
/// another thread's messages even with a broad channel name.
class ChatThreadRealtime {
  ChatThreadRealtime({required String threadId, required void Function(ChatMessage message) onMessage})
      : _channel = AppSupabase.client.channel('chat_messages:$threadId') {
    _channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'thread_id', value: threadId),
          callback: (payload) => onMessage(ChatMessage.fromRecord(payload.newRecord)),
        )
        .subscribe();
  }

  final RealtimeChannel _channel;

  Future<void> dispose() => AppSupabase.client.removeChannel(_channel);
}
