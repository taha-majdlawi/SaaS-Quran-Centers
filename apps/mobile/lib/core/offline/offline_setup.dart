import 'package:supabase_flutter/supabase_flutter.dart';

import 'outbox.dart';
import 'sync_service.dart';

/// Creates the app-wide [SyncService] and teaches it how to replay each kind of
/// queued write. Every one of these calls is idempotent on the server
/// (`client_ref` for recitations / serd, upsert for attendance), so replaying
/// after a half-received answer never duplicates anything.
SyncService createSyncService(SupabaseClient client) {
  final sync = SyncService(SqliteOfflineStore(), currentUser: () => client.auth.currentUser?.id);

  sync.register('log_recitation', (payload) => client.rpc('log_recitation', params: payload));
  sync.register('serd_submit', (payload) => client.rpc('teacher_submit_serd', params: payload));
  sync.register('attendance', (payload) async {
    final rows = (payload['rows'] as List).cast<Map<String, dynamic>>();
    await client.from('attendance').upsert(rows, onConflict: 'student_id,session_date');
  });

  SyncService.instance = sync;
  return sync;
}
