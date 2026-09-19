import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const kAchievementTypes = {
  'new_memorization': 'حفظ جديد',
  'recent_review': 'مراجعة قريبة',
  'distant_review': 'مراجعة بعيدة',
};

class GradeOption {
  const GradeOption({required this.key, required this.label, required this.points});
  final String key;
  final String label;
  final int points;
}

class MyCircle {
  const MyCircle({required this.id, required this.name, this.stageName, required this.studentCount});
  final String id;
  final String name;
  final String? stageName;
  final int studentCount;
}

class CircleStudent {
  const CircleStudent({
    required this.id,
    required this.fullName,
    required this.studentCode,
    required this.totalPoints,
    required this.recitedToday,
    this.attendanceToday,
    this.nextPlan,
  });

  final String id;
  final String fullName;
  final String studentCode;
  final int totalPoints;

  /// How many recitations were logged for this student since local midnight.
  final int recitedToday;
  final String? attendanceToday;
  final String? nextPlan;
}

class SurahPart {
  const SurahPart({required this.surah, required this.ayahFrom, required this.ayahTo});
  final int surah;
  final int ayahFrom;
  final int ayahTo;
}

class RecitationEntry {
  const RecitationEntry({
    required this.id,
    required this.type,
    required this.surah,
    required this.ayahFrom,
    required this.ayahTo,
    required this.grade,
    required this.points,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String type;
  final int surah;
  final int ayahFrom;
  final int ayahTo;
  final String? grade;
  final int points;
  final String createdAt;
  final String? notes;
}

class TodayCircle {
  const TodayCircle({
    required this.id,
    required this.name,
    required this.students,
    required this.recited,
    required this.present,
    required this.absent,
  });

  final String id;
  final String name;
  final int students;
  final int recited;
  final int present;
  final int absent;
}

class TeacherToday {
  const TeacherToday({required this.isWorkingDay, required this.circles});
  final bool isWorkingDay;
  final List<TodayCircle> circles;
}

class RecitationResult {
  const RecitationResult({required this.pointsAwarded, required this.newTotalPoints, required this.wasDuplicate});
  final int pointsAwarded;
  final int? newTotalPoints;
  final bool wasDuplicate;
}

/// Mirrors eqraa's teacher recitation flow. Points are NEVER computed here:
/// the server stamps them from the center's own grade table (log_recitation).
class RecitationRepository {
  RecitationRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<List<GradeOption>> fetchGrades(String orgId) async {
    final rows = await _client
        .from('recitation_grades')
        .select('key, label, points')
        .eq('organization_id', orgId)
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List)
        .map((r) => GradeOption(key: r['key'] as String, label: r['label'] as String, points: r['points'] as int))
        .toList();
  }

  /// Circles the signed-in teacher teaches (an admin sees all of them).
  Future<List<MyCircle>> fetchMyCircles(String orgId, {required String userId, required bool isAdmin}) async {
    var query = _client
        .from('circles')
        .select('id, name, teacher_id, stages(name), students_profile(count)')
        .eq('organization_id', orgId)
        .eq('status', 'active');
    if (!isAdmin) query = query.eq('teacher_id', userId);
    final rows = await query.order('name');

    return (rows as List).map((r) {
      final stage = r['stages'] as Map<String, dynamic>?;
      final counts = r['students_profile'] as List?;
      final count = counts != null && counts.isNotEmpty ? (counts.first['count'] as int? ?? 0) : 0;
      return MyCircle(id: r['id'] as String, name: r['name'] as String, stageName: stage?['name'] as String?, studentCount: count);
    }).toList();
  }

  Future<List<CircleStudent>> fetchCircleStudents(String circleId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
    final today = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final results = await Future.wait<dynamic>([
      _client
          .from('students_profile')
          .select('id, full_name, student_code, total_points, next_plan')
          .eq('circle_id', circleId)
          .eq('status', 'active')
          .order('full_name'),
      _client.from('daily_achievements').select('student_id').eq('circle_id', circleId).gte('created_at', startOfDay),
      _client.from('attendance').select('student_id, status').eq('circle_id', circleId).eq('session_date', today),
    ]);

    final recitedCount = <String, int>{};
    for (final r in results[1] as List) {
      final id = r['student_id'] as String;
      recitedCount[id] = (recitedCount[id] ?? 0) + 1;
    }
    final attendance = {for (final a in results[2] as List) a['student_id'] as String: a['status'] as String};

    return (results[0] as List)
        .map((s) => CircleStudent(
              id: s['id'] as String,
              fullName: s['full_name'] as String,
              studentCode: s['student_code'] as String,
              totalPoints: (s['total_points'] as int?) ?? 0,
              recitedToday: recitedCount[s['id']] ?? 0,
              attendanceToday: attendance[s['id']],
              nextPlan: s['next_plan'] as String?,
            ))
        .toList();
  }

  String newSessionGroupId() => _uuid.v4();

  Future<RecitationResult> logRecitation({
    required String orgId,
    required String studentId,
    required String type,
    required SurahPart part,
    required String grade,
    String? notes,
    DateTime? recordedAt,
    String? sessionGroupId,
  }) async {
    final result = await _client.rpc('log_recitation', params: {
      'p_org': orgId,
      'p_student_id': studentId,
      'p_type': type,
      'p_surah': part.surah,
      'p_ayah_from': part.ayahFrom,
      'p_ayah_to': part.ayahTo,
      'p_grade': grade,
      'p_notes': notes,
      // Makes a retry (bad network) safe: the server ignores a repeated ref.
      'p_client_ref': _uuid.v4(),
      'p_recorded_at': recordedAt?.toUtc().toIso8601String(),
      'p_session_group_id': sessionGroupId,
    }) as Map<String, dynamic>;
    return RecitationResult(
      pointsAwarded: (result['points_awarded'] as num?)?.toInt() ?? 0,
      newTotalPoints: (result['new_total_points'] as num?)?.toInt(),
      wasDuplicate: result['was_duplicate'] as bool? ?? false,
    );
  }

  Future<void> setAttendance({
    required String orgId,
    required String circleId,
    required String studentId,
    required String status,
  }) {
    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _client.from('attendance').upsert({
      'organization_id': orgId,
      'student_id': studentId,
      'circle_id': circleId,
      'session_date': today,
      'status': status,
    }, onConflict: 'student_id,session_date');
  }

  Future<List<RecitationEntry>> fetchStudentRecitations(String studentId, {int limit = 60}) async {
    final rows = await _client
        .from('daily_achievements')
        .select('id, achievement_type, surah_from, ayah_from, ayah_to, grade, points_awarded, notes, created_at')
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => RecitationEntry(
              id: r['id'] as String,
              type: r['achievement_type'] as String,
              surah: r['surah_from'] as int,
              ayahFrom: r['ayah_from'] as int,
              ayahTo: r['ayah_to'] as int,
              grade: r['grade'] as String?,
              points: (r['points_awarded'] as num?)?.toInt() ?? 0,
              createdAt: r['created_at'] as String,
              notes: r['notes'] as String?,
            ))
        .toList();
  }

  Future<void> updateRecitation({
    required String id,
    required String type,
    required SurahPart part,
    required String grade,
    String? notes,
  }) {
    return _client.rpc('update_recitation', params: {
      'p_id': id,
      'p_type': type,
      'p_surah': part.surah,
      'p_ayah_from': part.ayahFrom,
      'p_ayah_to': part.ayahTo,
      'p_grade': grade,
      'p_notes': notes,
    });
  }

  Future<void> deleteRecitation(String id) => _client.rpc('delete_recitation', params: {'p_id': id});

  Future<void> setStudentPlan({required String orgId, required String studentId, required String? plan}) {
    return _client.rpc('set_student_plan', params: {'p_org': orgId, 'p_student': studentId, 'p_next_plan': plan});
  }

  Future<TeacherToday> fetchTeacherToday(String orgId) async {
    final data = await _client.rpc('get_teacher_today', params: {'p_org': orgId}) as Map<String, dynamic>;
    return TeacherToday(
      isWorkingDay: data['is_working_day'] as bool? ?? true,
      circles: [
        for (final c in data['circles'] as List)
          TodayCircle(
            id: c['id'] as String,
            name: c['name'] as String,
            students: (c['students'] as num).toInt(),
            recited: (c['recited'] as num).toInt(),
            present: (c['present'] as num).toInt(),
            absent: (c['absent'] as num).toInt(),
          ),
      ],
    );
  }
}
