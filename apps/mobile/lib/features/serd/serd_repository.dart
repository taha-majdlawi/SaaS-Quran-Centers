import 'package:supabase_flutter/supabase_flutter.dart';

const kSerdTypeLabels = {'full': 'كامل', 'partial': 'جزئي'};
const kSerdStatusLabels = {
  'pending': 'قيد الانتظار',
  'scheduled': 'مجدولة',
  'in_progress': 'جارية',
  'completed': 'مكتملة',
  'cancelled': 'ملغاة',
};

class SerdStudentOption {
  const SerdStudentOption({required this.id, required this.fullName});
  final String id;
  final String fullName;
}

class SerdStaffOption {
  const SerdStaffOption({required this.userId, required this.label});
  final String userId;
  final String label;
}

class SerdSessionSummary {
  const SerdSessionSummary({
    required this.id,
    required this.sessionType,
    required this.status,
    required this.studentName,
    this.scheduledAt,
    this.overallGrade,
  });

  final String id;
  final String sessionType;
  final String status;
  final String studentName;
  final String? scheduledAt;
  final num? overallGrade;
}

class SerdSessionDetail {
  const SerdSessionDetail({
    required this.id,
    required this.sessionType,
    required this.status,
    required this.studentName,
    this.examinerId,
    this.scheduledAt,
    this.overallGrade,
    this.notes,
  });

  final String id;
  final String sessionType;
  final String status;
  final String studentName;
  final String? examinerId;
  final String? scheduledAt;
  final num? overallGrade;
  final String? notes;
}

/// Mirrors apps/web's serd/actions.ts - scheduling + one-overall-grade
/// recording for Quran recitation exam sessions.
class SerdRepository {
  SerdRepository(this._client);

  final SupabaseClient _client;

  Future<List<SerdSessionSummary>> fetchSessions(String organizationId) async {
    final rows = await _client
        .from('serd_sessions')
        .select('id, session_type, status, scheduled_at, overall_grade, students_profile(full_name)')
        .eq('organization_id', organizationId)
        .order('scheduled_at', ascending: false);

    return (rows as List).map((r) {
      final student = r['students_profile'] as Map<String, dynamic>?;
      return SerdSessionSummary(
        id: r['id'] as String,
        sessionType: r['session_type'] as String,
        status: r['status'] as String,
        studentName: (student?['full_name'] as String?) ?? '—',
        scheduledAt: r['scheduled_at'] as String?,
        overallGrade: r['overall_grade'] as num?,
      );
    }).toList();
  }

  Future<List<SerdStudentOption>> fetchStudents(String organizationId) async {
    final rows = await _client
        .from('students_profile')
        .select('id, full_name')
        .eq('organization_id', organizationId)
        .order('full_name');
    return (rows as List)
        .map((r) => SerdStudentOption(id: r['id'] as String, fullName: r['full_name'] as String))
        .toList();
  }

  Future<List<SerdStaffOption>> fetchStaff(String organizationId) async {
    final rows = await _client.rpc('list_org_members', params: {'org_id': organizationId});
    return (rows as List)
        .where((r) => r['role'] == 'teacher' || r['role'] == 'admin')
        .map((r) => SerdStaffOption(
              userId: r['user_id'] as String,
              label: (r['full_name'] as String?) ?? (r['email'] as String?) ?? '—',
            ))
        .toList();
  }

  Future<SerdSessionDetail?> fetchSession(String id) async {
    final row = await _client
        .from('serd_sessions')
        .select(
          'id, session_type, status, scheduled_at, examiner_id, overall_grade, notes, students_profile(full_name)',
        )
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    final student = row['students_profile'] as Map<String, dynamic>?;
    return SerdSessionDetail(
      id: row['id'] as String,
      sessionType: row['session_type'] as String,
      status: row['status'] as String,
      studentName: (student?['full_name'] as String?) ?? '—',
      examinerId: row['examiner_id'] as String?,
      scheduledAt: row['scheduled_at'] as String?,
      overallGrade: row['overall_grade'] as num?,
      notes: row['notes'] as String?,
    );
  }

  Future<void> createSession({
    required String organizationId,
    required String studentId,
    required String sessionType,
    String? scheduledAt,
  }) {
    return _client.from('serd_sessions').insert({
      'organization_id': organizationId,
      'student_id': studentId,
      'session_type': sessionType,
      'scheduled_at': scheduledAt,
      'status': scheduledAt != null ? 'scheduled' : 'pending',
    });
  }

  Future<void> updateSession({
    required String id,
    required String status,
    String? examinerId,
    String? scheduledAt,
    num? overallGrade,
    String? notes,
  }) {
    return _client.from('serd_sessions').update({
      'status': status,
      'examiner_id': examinerId,
      'scheduled_at': scheduledAt,
      'overall_grade': overallGrade,
      'notes': notes,
    }).eq('id', id);
  }

  Future<void> deleteSession(String id) {
    return _client.from('serd_sessions').delete().eq('id', id);
  }
}
