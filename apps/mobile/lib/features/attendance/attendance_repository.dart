import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/offline/sync_service.dart';
import '../../core/i18n/i18n.dart';

Map<String, String> get kAttendanceStatusOptions => currentStrings.org.attStatus;

class CirclePickerOption {
  const CirclePickerOption({required this.id, required this.name});
  final String id;
  final String name;
}

class AttendanceStudentRow {
  const AttendanceStudentRow({required this.id, required this.studentCode, required this.fullName});
  final String id;
  final String studentCode;
  final String fullName;
}

/// Mirrors apps/web's attendance/actions.ts - pick a circle + date, mark
/// every student in it, upsert on the (student_id, session_date) unique
/// constraint so re-saving the same day just updates it.
class AttendanceRepository {
  AttendanceRepository(this._client);

  final SupabaseClient _client;

  Future<List<CirclePickerOption>> fetchCircles(String organizationId) {
    return SyncService.instance.cached<List<CirclePickerOption>>(
      'att-circles:$organizationId',
      () => _client.from('circles').select('id, name').eq('organization_id', organizationId).order('name'),
      (rows) => [for (final r in rows as List) CirclePickerOption(id: r['id'] as String, name: r['name'] as String)],
    );
  }

  Future<List<AttendanceStudentRow>> fetchStudentsInCircle(String organizationId, String circleId) {
    return SyncService.instance.cached<List<AttendanceStudentRow>>(
      'att-students:$circleId',
      () => _client
          .from('students_profile')
          .select('id, full_name, student_code')
          .eq('organization_id', organizationId)
          .eq('circle_id', circleId)
          .order('full_name'),
      (rows) => [
        for (final r in rows as List)
          AttendanceStudentRow(id: r['id'] as String, studentCode: r['student_code'] as String, fullName: r['full_name'] as String),
      ],
    );
  }

  Future<Map<String, String>> fetchExisting(String circleId, String sessionDate) async {
    final sync = SyncService.instance;
    final saved = await sync.cached<Map<String, String>>(
      'att-existing:$circleId:$sessionDate',
      () => _client.from('attendance').select('student_id, status').eq('circle_id', circleId).eq('session_date', sessionDate),
      (rows) => {for (final r in rows as List) r['student_id'] as String: r['status'] as String},
    );
    return saved;
  }

  /// Returns true when it was stored on the phone (no network) instead of reaching the server.
  Future<bool> saveAttendance({
    required String organizationId,
    required String circleId,
    required String sessionDate,
    required Map<String, String> statusByStudentId,
  }) async {
    if (statusByStudentId.isEmpty) return false;
    final rows = statusByStudentId.entries
        .map((e) => {
              'organization_id': organizationId,
              'student_id': e.key,
              'circle_id': circleId,
              'session_date': sessionDate,
              'status': e.value,
            })
        .toList();
    final outcome = await SyncService.instance.submit(
      'attendance',
      {'rows': rows},
      label: fmt(currentStrings.org.outboxAttendance, {'sessionDate': sessionDate, 'n': rows.length}),
    );
    return outcome.queued;
  }
}
