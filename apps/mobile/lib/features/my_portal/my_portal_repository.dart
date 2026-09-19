import 'package:supabase_flutter/supabase_flutter.dart';

import '../serd/serd_models.dart';

class PortalStudent {
  const PortalStudent({required this.id, required this.fullName, required this.studentCode});
  final String id;
  final String fullName;
  final String studentCode;
}

class PortalRecitation {
  const PortalRecitation({
    required this.type,
    required this.surah,
    required this.ayahFrom,
    required this.ayahTo,
    required this.gradeLabel,
    required this.points,
    required this.createdAt,
    this.notes,
    this.sessionGroupId,
  });

  final String type;
  final int surah;
  final int ayahFrom;
  final int ayahTo;
  final String gradeLabel;
  final int points;
  final String createdAt;
  final String? notes;
  final String? sessionGroupId;
}

class PortalDashboard {
  const PortalDashboard({
    required this.fullName,
    required this.studentCode,
    required this.totalPoints,
    required this.totalParts,
    required this.progress,
    required this.recent,
    required this.totalRecitations,
    required this.thisWeek,
    required this.lastWeek,
    required this.ayahsThisWeek,
    required this.currentStreak,
    required this.longestStreak,
    this.circleName,
    this.teacherName,
    this.stageName,
    this.nextPlan,
    this.weeklyAttendance,
    this.monthlyAttendance,
    this.lastRecitationAt,
    this.phone,
    this.address,
    this.serd,
  });

  final SerdSummary? serd;
  final String fullName;
  final String studentCode;
  final int totalPoints;
  final int totalParts;
  final num progress;
  final String? circleName;
  final String? teacherName;
  final String? stageName;
  final String? nextPlan;
  final int totalRecitations;
  final int thisWeek;
  final int lastWeek;
  final int ayahsThisWeek;
  final int currentStreak;
  final int longestStreak;
  final num? weeklyAttendance;
  final num? monthlyAttendance;
  final String? lastRecitationAt;
  final String? phone;
  final String? address;
  final List<PortalRecitation> recent;
}

/// Everything on the student's home comes from ONE server call
/// (get_student_dashboard) - the same shape eqraa's home uses - so the phone
/// never re-derives points, streaks or attendance rates.
class MyPortalRepository {
  MyPortalRepository(this._client);

  final SupabaseClient _client;

  /// Own record for a student, or every linked child for a guardian (RLS).
  Future<List<PortalStudent>> fetchMyStudents(String organizationId) async {
    final rows = await _client
        .from('students_profile')
        .select('id, student_code, full_name')
        .eq('organization_id', organizationId)
        .order('full_name');
    return (rows as List)
        .map((r) => PortalStudent(
              id: r['id'] as String,
              fullName: r['full_name'] as String,
              studentCode: r['student_code'] as String,
            ))
        .toList();
  }

  Future<PortalDashboard?> fetchDashboard(String organizationId, String studentId) async {
    final data = await _client.rpc('get_student_dashboard', params: {
      'p_org': organizationId,
      'p_student_id': studentId,
    }) as Map<String, dynamic>;
    if (data['linked'] != true) return null;

    final student = data['student'] as Map<String, dynamic>;
    final circle = data['circle'] as Map<String, dynamic>?;
    final stats = data['stats'] as Map<String, dynamic>;

    // Serd is a separate module: a failure here must not blank the home.
    SerdSummary? serd;
    try {
      serd = SerdSummary.fromJson(
        await _client.rpc('serd_student_summary', params: {'p_org': organizationId, 'p_student': studentId}) as Map<String, dynamic>,
      );
    } catch (_) {
      serd = null;
    }

    return PortalDashboard(
      serd: serd,
      fullName: student['full_name'] as String,
      studentCode: student['student_code'] as String,
      totalPoints: (student['total_points'] as num).toInt(),
      totalParts: (student['total_parts_count'] as num).toInt(),
      progress: student['total_progress'] as num,
      nextPlan: student['next_plan'] as String?,
      phone: student['phone'] as String?,
      address: student['address'] as String?,
      circleName: circle?['name'] as String?,
      teacherName: circle?['teacher'] as String?,
      stageName: circle?['stage'] as String?,
      totalRecitations: (stats['total_recitations'] as num).toInt(),
      thisWeek: (stats['recitations_this_week'] as num).toInt(),
      lastWeek: (stats['recitations_last_week'] as num).toInt(),
      ayahsThisWeek: (stats['ayahs_this_week'] as num).toInt(),
      currentStreak: (stats['current_streak'] as num).toInt(),
      longestStreak: (stats['longest_streak'] as num).toInt(),
      weeklyAttendance: stats['weekly_attendance_rate'] as num?,
      monthlyAttendance: stats['monthly_attendance_rate'] as num?,
      lastRecitationAt: stats['last_recitation_at'] as String?,
      recent: (data['recent'] as List)
          .map((r) => PortalRecitation(
                type: r['type'] as String,
                surah: (r['surah'] as num).toInt(),
                ayahFrom: (r['ayah_from'] as num).toInt(),
                ayahTo: (r['ayah_to'] as num).toInt(),
                gradeLabel: (r['grade_label'] as String?) ?? '',
                points: (r['points_awarded'] as num).toInt(),
                createdAt: r['created_at'] as String,
                notes: r['notes'] as String?,
                sessionGroupId: r['session_group_id'] as String?,
              ))
          .toList(),
    );
  }
}
