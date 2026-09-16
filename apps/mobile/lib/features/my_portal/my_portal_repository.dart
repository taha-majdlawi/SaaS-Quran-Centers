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

  /// Serialization is only for core/offline/offline_cache.dart's read-through
  /// fallback (see my_portal_screen.dart) - not used on the live-fetch path.
  Map<String, dynamic> toJson() => {'id': id, 'student_code': studentCode, 'full_name': fullName, 'status': status};

  factory PortalStudent.fromJson(Map<String, dynamic> j) => PortalStudent(
        id: j['id'] as String,
        studentCode: j['student_code'] as String,
        fullName: j['full_name'] as String,
        status: j['status'] as String,
      );
}

class PortalAttendanceEntry {
  const PortalAttendanceEntry({required this.sessionDate, required this.status});
  final String sessionDate;
  final String status;

  Map<String, dynamic> toJson() => {'session_date': sessionDate, 'status': status};

  factory PortalAttendanceEntry.fromJson(Map<String, dynamic> j) =>
      PortalAttendanceEntry(sessionDate: j['session_date'] as String, status: j['status'] as String);
}

class PortalSerdEntry {
  const PortalSerdEntry({required this.sessionType, required this.status});
  final String sessionType;
  final String status;

  Map<String, dynamic> toJson() => {'session_type': sessionType, 'status': status};

  factory PortalSerdEntry.fromJson(Map<String, dynamic> j) =>
      PortalSerdEntry(sessionType: j['session_type'] as String, status: j['status'] as String);
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

  Map<String, dynamic> toJson() => {
        'achievement_type': achievementType,
        'points_awarded': pointsAwarded,
        'surah_from': surahFrom,
        'ayah_from': ayahFrom,
        'surah_to': surahTo,
        'ayah_to': ayahTo,
        'grade': grade,
      };

  factory PortalAchievementEntry.fromJson(Map<String, dynamic> j) => PortalAchievementEntry(
        achievementType: j['achievement_type'] as String,
        pointsAwarded: j['points_awarded'] as int,
        surahFrom: j['surah_from'] as int?,
        ayahFrom: j['ayah_from'] as int?,
        surahTo: j['surah_to'] as int?,
        ayahTo: j['ayah_to'] as int?,
        grade: j['grade'] as num?,
      );
}

/// Center-wide, not per-student - upcoming trips/events shown once above the
/// student cards (mirrors apps/web having no equivalent yet; this is new UI).
class PortalUpcomingEvent {
  const PortalUpcomingEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.requiresGuardianConsent,
    this.location,
  });
  final String id;
  final String title;
  final String startsAt;
  final bool requiresGuardianConsent;
  final String? location;

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'starts_at': startsAt, 'requires_guardian_consent': requiresGuardianConsent, 'location': location};

  factory PortalUpcomingEvent.fromJson(Map<String, dynamic> j) => PortalUpcomingEvent(
        id: j['id'] as String,
        title: j['title'] as String,
        startsAt: j['starts_at'] as String,
        requiresGuardianConsent: j['requires_guardian_consent'] as bool,
        location: j['location'] as String?,
      );
}

/// A student's registration on an event - its existence IS the guardian's
/// consent for events that require it (see 0006/0016's RLS: only a guardian
/// of the student, or staff, can create one).
class PortalRegistration {
  const PortalRegistration({required this.id, required this.eventId, required this.studentId});
  final String id;
  final String eventId;
  final String studentId;
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
        .select('id, title, starts_at, location, requires_guardian_consent')
        .eq('organization_id', organizationId)
        .gte('starts_at', DateTime.now().toUtc().toIso8601String())
        .order('starts_at')
        .limit(5);

    return (rows as List)
        .map((r) => PortalUpcomingEvent(
              id: r['id'] as String,
              title: r['title'] as String,
              startsAt: r['starts_at'] as String,
              requiresGuardianConsent: r['requires_guardian_consent'] as bool,
              location: r['location'] as String?,
            ))
        .toList();
  }

  /// This guardian/student's own linked-student registrations across the
  /// given events - used to show which upcoming events already have consent.
  Future<List<PortalRegistration>> fetchRegistrations({
    required List<String> studentIds,
    required List<String> eventIds,
  }) async {
    if (studentIds.isEmpty || eventIds.isEmpty) return [];
    final rows = await _client
        .from('calendar_registrations')
        .select('id, event_id, student_id')
        .inFilter('student_id', studentIds)
        .inFilter('event_id', eventIds);

    return (rows as List)
        .map((r) => PortalRegistration(
              id: r['id'] as String,
              eventId: r['event_id'] as String,
              studentId: r['student_id'] as String,
            ))
        .toList();
  }

  /// The caller's own organization_members.id - recorded as consented_by so
  /// staff can see which guardian gave consent for a trip.
  Future<String?> fetchMyMemberId(String organizationId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from('organization_members')
        .select('id')
        .eq('organization_id', organizationId)
        .eq('user_id', userId)
        .maybeSingle();
    return row?['id'] as String?;
  }

  /// Throws a PostgrestException with code 23505 if already consented.
  Future<void> giveConsent({required String eventId, required String studentId, String? guardianMemberId}) {
    return _client.from('calendar_registrations').insert({
      'event_id': eventId,
      'student_id': studentId,
      'status': 'registered',
      'consented_by': guardianMemberId,
    });
  }

  Future<void> withdrawConsent(String registrationId) {
    return _client.from('calendar_registrations').delete().eq('id', registrationId);
  }
}
