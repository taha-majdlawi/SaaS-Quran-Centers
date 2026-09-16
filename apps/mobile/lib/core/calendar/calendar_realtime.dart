import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client.dart';

/// A Supabase Realtime (Postgres Changes) subscription on center_calendar
/// for one organization - unlike core/chat/chat_realtime.dart (which hands
/// back the inserted row so the caller can append it), this just tells the
/// caller *something* changed and lets it re-fetch (calendar_list_screen.dart
/// calls its own `_reload`), since insert/update/delete would each need
/// different local-patch logic for comparatively little payoff on a list
/// this size. See migration 0018 for why every event type (not just insert,
/// unlike chat) reaches this: REPLICA IDENTITY FULL on center_calendar.
class CalendarRealtime {
  CalendarRealtime({required String organizationId, required void Function() onChange})
      : _channel = AppSupabase.client.channel('center_calendar:$organizationId') {
    _channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'center_calendar',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'organization_id', value: organizationId),
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  final RealtimeChannel _channel;

  Future<void> dispose() => AppSupabase.client.removeChannel(_channel);
}
