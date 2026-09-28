import 'package:supabase_flutter/supabase_flutter.dart';

import '../calendar/calendar_models.dart';
import '../calendar/calendar_repository.dart';
import '../comms/comms_repository.dart' show Announcement, CommsRepository;
import '../engagement/engagement_models.dart' show BadgeProgress;
import '../engagement/engagement_repository.dart';
import '../serd/serd_models.dart';
import '../settings/settings_repository.dart';
import '../../core/offline/sync_service.dart';

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

  factory PortalRecitation.fromJson(Map<String, dynamic> r) => PortalRecitation(
        type: r['type'] as String,
        surah: (r['surah'] as num).toInt(),
        ayahFrom: (r['ayah_from'] as num).toInt(),
        ayahTo: (r['ayah_to'] as num).toInt(),
        gradeLabel: (r['grade_label'] as String?) ?? '',
        points: (r['points_awarded'] as num).toInt(),
        createdAt: r['created_at'] as String,
        notes: r['notes'] as String?,
        sessionGroupId: r['session_group_id'] as String?,
      );
}

class AttendanceRow {
  const AttendanceRow({required this.date, required this.status});
  final String date;
  final String status;

  factory AttendanceRow.fromJson(Map<String, dynamic> j) =>
      AttendanceRow(date: j['date'] as String, status: j['status'] as String);
}

class PointsBreakdownRow {
  const PointsBreakdownRow({required this.grade, required this.count, required this.pointsEach, required this.total});
  final String grade;
  final int count;
  final int pointsEach;
  final int total;

  factory PointsBreakdownRow.fromJson(Map<String, dynamic> j) => PointsBreakdownRow(
        grade: j['grade'] as String,
        count: (j['count'] as num).toInt(),
        pointsEach: (j['points_each'] as num).toInt(),
        total: (j['total'] as num).toInt(),
      );
}

/// The student "record" screen's fuller data - beyond the 20-row home
/// preview, and the two figures (monthly points, points-by-grade) that must
/// come from the server so they never drift from students_profile.total_points
/// after an admin changes a grade's point value (see 0056).
class RecordDetail {
  const RecordDetail({
    required this.monthlyPoints,
    required this.pointsBreakdown,
    required this.recitations,
    required this.attendance,
  });
  final int monthlyPoints;
  final List<PointsBreakdownRow> pointsBreakdown;
  final List<PortalRecitation> recitations;
  final List<AttendanceRow> attendance;
}

class PortalDashboard {
  PortalDashboard({
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
    this.announcements = const [],
    this.upcoming = const [],
    this.badges = const [],
    this.prayerSettings = const {},
  });

  final SerdSummary? serd;
  final List<Announcement> announcements;
  final List<CalEntry> upcoming;
  final List<BadgeProgress> badges;
  final Map<String, String> prayerSettings;
  final String fullName;
  final String studentCode;
  final int totalPoints;
  final int totalParts;
  final num progress;
  final String? circleName;
  final String? teacherName;
  final String? stageName;
  /// Not final: a plan still waiting on the teacher's phone is shown in its place.
  String? nextPlan;
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
    final rows = (await SyncService.instance.raw('portal.fetchMyStudents:$organizationId', () => _client
        .from('students_profile')
        .select('id, student_code, full_name')
        .eq('organization_id', organizationId)
        .order('full_name'))) as List<dynamic>;
    return (rows)
        .map((r) => PortalStudent(
              id: r['id'] as String,
              fullName: r['full_name'] as String,
              studentCode: r['student_code'] as String,
            ))
        .toList();
  }

  Future<PortalDashboard?> fetchDashboard(String organizationId, String studentId) async {
    final data = (await SyncService.instance.raw('portal.fetchDashboard:$organizationId:$studentId', () => _client.rpc('get_student_dashboard', params: {
      'p_org': organizationId,
      'p_student_id': studentId,
    }))) as Map<String, dynamic>;
    if (data['linked'] != true) return null;

    final student = data['student'] as Map<String, dynamic>;
    final circle = data['circle'] as Map<String, dynamic>?;
    final stats = data['stats'] as Map<String, dynamic>;

    // Each extra home section is a separate call to its own already-existing
    // feature - a failure in any one (e.g. calendar module disabled) must
    // never blank the rest of the home screen.
    SerdSummary? serd;
    try {
      serd = SerdSummary.fromJson(
        (await SyncService.instance.raw('portal.fetchDashboard:$organizationId:$studentId#1', () => _client.rpc('serd_student_summary', params: {'p_org': organizationId, 'p_student': studentId}))) as Map<String, dynamic>,
      );
    } catch (_) {
      serd = null;
    }

    var announcements = <Announcement>[];
    try {
      announcements = await CommsRepository(_client).announcements(organizationId);
    } catch (_) {}

    var upcoming = <CalEntry>[];
    try {
      final now = DateTime.now();
      final range = await CalendarRepository(_client).fetchRange(organizationId, now, now.add(const Duration(days: 7)));
      upcoming = range.entries;
    } catch (_) {}

    var badges = <BadgeProgress>[];
    try {
      badges = await EngagementRepository(_client).studentBadges(organizationId, studentId);
    } catch (_) {}

    var prayerSettings = <String, String>{};
    try {
      prayerSettings = await SettingsRepository(_client).fetchCenterSettings(organizationId);
    } catch (_) {}

    return PortalDashboard(
      serd: serd,
      announcements: announcements,
      upcoming: upcoming,
      badges: badges,
      prayerSettings: prayerSettings,
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
      recent: (data['recent'] as List).map((r) => PortalRecitation.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }

  Future<RecordDetail> fetchRecordDetail(String organizationId, String studentId) async {
    final data = (await SyncService.instance.raw('portal.fetchRecordDetail:$organizationId:$studentId', () => _client.rpc('student_record_detail', params: {
      'p_org': organizationId,
      'p_student': studentId,
    }))) as Map<String, dynamic>;
    return RecordDetail(
      monthlyPoints: (data['monthly_points'] as num).toInt(),
      pointsBreakdown: (data['points_breakdown'] as List)
          .map((r) => PointsBreakdownRow.fromJson(r as Map<String, dynamic>))
          .toList(),
      recitations: (data['recitations'] as List).map((r) => PortalRecitation.fromJson(r as Map<String, dynamic>)).toList(),
      attendance: (data['attendance'] as List).map((r) => AttendanceRow.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }
}
