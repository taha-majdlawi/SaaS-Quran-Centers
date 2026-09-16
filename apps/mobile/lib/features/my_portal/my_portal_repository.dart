import 'package:supabase_flutter/supabase_flutter.dart';

const kAchievementTypeLabels = {
  'new_memorization': 'حفظ جديد',
  'recent_review': 'مراجعة قريبة',
  'distant_review': 'مراجعة بعيدة',
};

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

class PortalAchievementEntry {
  const PortalAchievementEntry({
    required this.achievementType,
    required this.pointsAwarded,
    this.surahFrom,
    this.ayahFrom,
    this.surahTo,
    this.ayahTo,
    this.grade,
  });

  final String achievementType;
  final int pointsAwarded;
  final int? surahFrom;
  final int? ayahFrom;
  final int? surahTo;
  final int? ayahTo;
  final num? grade;
}

/// Center-wide, not per-student - upcoming trips/events shown once above the
/// student cards (mirrors apps/web having no equivalent yet; this is new UI).
class PortalUpcomingEvent {
  const PortalUpcomingEvent({required this.id, required this.title, required this.startsAt, this.location});
  final String id;
  final String title;
  final String startsAt;
  final String? location;
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

  Future<List<PortalAchievementEntry>> fetchRecentAchievements(String studentId) async {
    final rows = await _client
        .from('daily_achievements')
        .select('achievement_type, surah_from, ayah_from, surah_to, ayah_to, grade, points_awarded')
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(5);

    return (rows as List)
        .map((r) => PortalAchievementEntry(
              achievementType: r['achievement_type'] as String,
              pointsAwarded: r['points_awarded'] as int,
              surahFrom: r['surah_from'] as int?,
              ayahFrom: r['ayah_from'] as int?,
              surahTo: r['surah_to'] as int?,
              ayahTo: r['ayah_to'] as int?,
              grade: r['grade'] as num?,
            ))
        .toList();
  }

  Future<List<PortalUpcomingEvent>> fetchUpcomingEvents(String organizationId) async {
    final rows = await _client
        .from('center_calendar')
        .select('id, title, starts_at, location')
        .eq('organization_id', organizationId)
        .gte('starts_at', DateTime.now().toUtc().toIso8601String())
        .order('starts_at')
        .limit(5);

    return (rows as List)
        .map((r) => PortalUpcomingEvent(
              id: r['id'] as String,
              title: r['title'] as String,
              startsAt: r['starts_at'] as String,
              location: r['location'] as String?,
            ))
        .toList();
  }
}
