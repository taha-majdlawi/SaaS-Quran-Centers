import 'package:supabase_flutter/supabase_flutter.dart';

const kAttendanceStatusOptions = {
  'present': 'حاضر',
  'absent': 'غائب',
  'excused': 'مستأذن',
  'late': 'متأخر',
};

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

  Future<List<CirclePickerOption>> fetchCircles(String organizationId) async {
    final rows = await _client
        .from('circles')
        .select('id, name')
        .eq('organization_id', organizationId)
        .order('name');
    return (rows as List).map((r) => CirclePickerOption(id: r['id'] as String, name: r['name'] as String)).toList();
  }

  Future<List<AttendanceStudentRow>> fetchStudentsInCircle(String organizationId, String circleId) async {
    final rows = await _client
        .from('students_profile')
        .select('id, full_name, student_code')
        .eq('organization_id', organizationId)
        .eq('circle_id', circleId)
        .order('full_name');
    return (rows as List)
        .map((r) => AttendanceStudentRow(
              id: r['id'] as String,
              studentCode: r['student_code'] as String,
              fullName: r['full_name'] as String,
            ))
        .toList();
  }

  Future<Map<String, String>> fetchExisting(String circleId, String sessionDate) async {
    final rows = await _client
        .from('attendance')
        .select('student_id, status')
        .eq('circle_id', circleId)
        .eq('session_date', sessionDate);
    return {for (final r in rows as List) r['student_id'] as String: r['status'] as String};
  }

  Future<void> saveAttendance({
    required String organizationId,
    required String circleId,
    required String sessionDate,
    required Map<String, String> statusByStudentId,
  }) async {
    if (statusByStudentId.isEmpty) return;
    final rows = statusByStudentId.entries
        .map((e) => {
              'organization_id': organizationId,
              'student_id': e.key,
              'circle_id': circleId,
              'session_date': sessionDate,
              'status': e.value,
            })
        .toList();
    await _client.from('attendance').upsert(rows, onConflict: 'student_id,session_date');
  }
}
