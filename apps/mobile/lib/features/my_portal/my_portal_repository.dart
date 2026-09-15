import 'package:supabase_flutter/supabase_flutter.dart';

class PortalStudent {
  const PortalStudent({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.status,
  });

  final String id;
  final String studentCode;
  final String fullName;
  final String status;
}

class PortalAttendanceEntry {
  const PortalAttendanceEntry({required this.sessionDate, required this.status});
  final String sessionDate;
  final String status;
}

class PortalSerdEntry {
  const PortalSerdEntry({required this.sessionType, required this.status});
  final String sessionType;
  final String status;
}

/// Mirrors apps/web's /my portal page - every table read here is already
/// scoped by RLS to the caller's own linked student(s) (migration 0015's
/// linked_student_ids()), so a plain select is enough, same as on web.
class MyPortalRepository {
  MyPortalRepository(this._client);

  final SupabaseClient _client;

  Future<List<PortalStudent>> fetchMyStudents(String organizationId) async {
    final rows = await _client
        .from('students_profile')
        .select('id, student_code, full_name, status')
        .eq('organization_id', organizationId);

    return (rows as List)
        .map((r) => PortalStudent(
              id: r['id'] as String,
              studentCode: r['student_code'] as String,
              fullName: r['full_name'] as String,
              status: r['status'] as String,
            ))
        .toList();
  }

  Future<int> fetchWalletBalance(String studentId) async {
    final row = await _client
        .from('student_wallets')
        .select('balance')
        .eq('student_id', studentId)
        .maybeSingle();
    return (row?['balance'] as int?) ?? 0;
  }

  Future<int> fetchBadgeCount(String studentId) async {
    final rows = await _client.from('student_badges').select('id').eq('student_id', studentId);
    return (rows as List).length;
  }

  Future<List<PortalAttendanceEntry>> fetchRecentAttendance(String studentId) async {
    final rows = await _client
        .from('attendance')
        .select('session_date, status')
        .eq('student_id', studentId)
        .order('session_date', ascending: false)
        .limit(8);

    return (rows as List)
        .map((r) => PortalAttendanceEntry(
              sessionDate: r['session_date'] as String,
              status: r['status'] as String,
            ))
        .toList();
  }

  Future<List<PortalSerdEntry>> fetchRecentSerdSessions(String studentId) async {
    final rows = await _client
        .from('serd_sessions')
        .select('session_type, status, scheduled_at')
        .eq('student_id', studentId)
        .order('scheduled_at', ascending: false)
        .limit(5);

    return (rows as List)
        .map((r) => PortalSerdEntry(sessionType: r['session_type'] as String, status: r['status'] as String))
        .toList();
  }
}
