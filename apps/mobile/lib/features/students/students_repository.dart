import 'package:supabase_flutter/supabase_flutter.dart';

class StudentSummary {
  const StudentSummary({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.status,
    this.circleName,
  });

  final String id;
  final String studentCode;
  final String fullName;
  final String status;
  final String? circleName;
}

class CircleOption {
  const CircleOption({required this.id, required this.name, this.stageId});
  final String id;
  final String name;
  final String? stageId;
}

class StageChoice {
  const StageChoice({required this.id, required this.name});
  final String id;
  final String name;
}

class StudentDetail {
  const StudentDetail({
    required this.id,
    required this.fullName,
    required this.studentCode,
    required this.circleId,
    required this.status,
    this.birthDate,
  });

  final String id;
  final String fullName;
  final String studentCode;
  final String? circleId;
  final String status;
  final String? birthDate;
}

/// Mirrors apps/web's students/actions.ts - same table, same organization_id
/// scoping (enforced by RLS either way), just called from Dart instead of a
/// Server Action.
class StudentsRepository {
  StudentsRepository(this._client);

  final SupabaseClient _client;

  Future<List<StudentSummary>> fetchStudents(String organizationId) async {
    final rows = await _client
        .from('students_profile')
        .select('id, student_code, full_name, status, circles(name)')
        .eq('organization_id', organizationId)
        .order('full_name');

    return (rows as List).map((row) {
      final circle = row['circles'] as Map<String, dynamic>?;
      return StudentSummary(
        id: row['id'] as String,
        studentCode: row['student_code'] as String,
        fullName: row['full_name'] as String,
        status: row['status'] as String,
        circleName: circle?['name'] as String?,
      );
    }).toList();
  }

  Future<List<CircleOption>> fetchCircles(String organizationId) async {
    final rows = await _client
        .from('circles')
        .select('id, name, stage_id')
        .eq('organization_id', organizationId)
        .order('name');

    return (rows as List)
        .map((r) => CircleOption(id: r['id'] as String, name: r['name'] as String, stageId: r['stage_id'] as String?))
        .toList();
  }

  Future<List<StageChoice>> fetchStages(String organizationId) async {
    final rows = await _client
        .from('stages')
        .select('id, name')
        .eq('organization_id', organizationId)
        .order('sort_order');
    return (rows as List).map((r) => StageChoice(id: r['id'] as String, name: r['name'] as String)).toList();
  }

  /// Same RPC apps/web uses to suggest "{stage_code}-{0001}" for a new student.
  Future<String?> nextStudentCode(String organizationId, String stageId) async {
    final code = await _client.rpc('next_student_code', params: {'org_id': organizationId, 'target_stage_id': stageId});
    return code as String?;
  }

  Future<StudentDetail?> fetchStudent(String id) async {
    final row = await _client
        .from('students_profile')
        .select('id, full_name, student_code, birth_date, circle_id, status')
        .eq('id', id)
        .maybeSingle();

    if (row == null) return null;

    return StudentDetail(
      id: row['id'] as String,
      fullName: row['full_name'] as String,
      studentCode: row['student_code'] as String,
      circleId: row['circle_id'] as String?,
      status: row['status'] as String,
      birthDate: row['birth_date'] as String?,
    );
  }

  Future<void> createStudent({
    required String organizationId,
    required String fullName,
    required String studentCode,
    required String circleId,
    String? birthDate,
  }) {
    return _client.from('students_profile').insert({
      'organization_id': organizationId,
      'full_name': fullName,
      'student_code': studentCode,
      'circle_id': circleId,
      'birth_date': birthDate,
    });
  }

  Future<void> updateStudent({
    required String id,
    required String fullName,
    required String studentCode,
    required String circleId,
    required String status,
    String? birthDate,
  }) {
    return _client.from('students_profile').update({
      'full_name': fullName,
      'student_code': studentCode,
      'circle_id': circleId,
      'status': status,
      'birth_date': birthDate,
    }).eq('id', id);
  }

  Future<void> deleteStudent(String id) {
    return _client.from('students_profile').delete().eq('id', id);
  }
}
