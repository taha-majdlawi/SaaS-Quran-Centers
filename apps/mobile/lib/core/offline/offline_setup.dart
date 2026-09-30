import 'package:supabase_flutter/supabase_flutter.dart';

import 'outbox.dart';
import 'sync_service.dart';

/// Creates the app-wide [SyncService] and teaches it how to replay each kind of
/// queued write. Every one of these calls is idempotent on the server
/// (`client_ref` for recitations / serd, upsert for attendance), so replaying
/// after a half-received answer never duplicates anything.
SyncService createSyncService(SupabaseClient client) {
  final sync = SyncService(
    SqliteOfflineStore(),
    currentUser: () => client.auth.currentUser?.id,
    // the cheapest call anyone may make: it answers only if the server is really there
    probe: () => client.rpc('public_plans'),
  );

  sync.register('log_recitation', (payload) => client.rpc('log_recitation', params: payload));
  sync.register('serd_submit', (payload) => client.rpc('teacher_submit_serd', params: payload));
  sync.register('student_note', (payload) => client.rpc('add_student_note', params: payload));
  sync.register('student_plan', (payload) => client.rpc('set_student_plan', params: payload));
  sync.register('teacher_check_in', (payload) => client.rpc('teacher_check_in', params: payload));
  sync.register('external_recitation', (payload) => client.rpc('submit_external_recitation', params: payload));
  sync.register('gathering', (payload) => client.rpc('submit_gathering', params: payload));
  sync.register('recitation_update', (payload) => client.rpc('update_recitation', params: payload));
  sync.register('recitation_delete', (payload) => client.rpc('delete_recitation', params: payload));
  sync.register('attendance', (payload) async {
    final rows = (payload['rows'] as List).cast<Map<String, dynamic>>();
    await client.from('attendance').upsert(rows, onConflict: 'student_id,session_date');
  });

  SyncService.instance = sync;
  return sync;
}
