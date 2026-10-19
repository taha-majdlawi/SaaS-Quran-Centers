import 'package:supabase_flutter/supabase_flutter.dart';

import 'next_position.dart';
import 'package:uuid/uuid.dart';

import '../../core/i18n/i18n.dart';
import '../../core/offline/sync_service.dart';

/// Recitation types in the current language (strings.labels.recitationType).
Map<String, String> get kAchievementTypes => currentStrings.labels.recitationType;

class GradeOption {
  const GradeOption({required this.key, required this.label, required this.points});
  final String key;
  final String label;
  final int points;
}

class MyCircle {
  const MyCircle({required this.id, required this.name, this.stageName, required this.studentCount, this.assistant = false});
  final bool assistant;
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
    this.lastRecitation,
  });

  final String id;
  final String fullName;
  final String studentCode;
  final int totalPoints;

  /// The student's most recent recitation (any circle), for the teacher to pick up from.
  final LastRecitation? lastRecitation;

  /// How many recitations were logged for this student since local midnight.
  final int recitedToday;
  final String? attendanceToday;
  final String? nextPlan;
}

class LastRecitation {
  const LastRecitation({required this.type, required this.surah, required this.ayahFrom, required this.ayahTo, this.grade, required this.createdAt});
  final String type;
  final int surah;
  final int ayahFrom;
  final int ayahTo;
  final String? grade;
  final String createdAt;
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
    this.pending = false,
  });

  final String id;

  /// Recorded or changed on this phone and not uploaded yet.
  final bool pending;
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
  const RecitationResult({required this.pointsAwarded, required this.newTotalPoints, required this.wasDuplicate, this.queued = false});
  final int pointsAwarded;
  final int? newTotalPoints;
  final bool wasDuplicate;

  /// Stored on the phone (no network); it uploads by itself when the connection returns.
  final bool queued;
}

/// Mirrors eqraa's teacher recitation flow. Points are NEVER computed here:
/// the server stamps them from the center's own grade table (log_recitation).
class RecitationRepository {
  RecitationRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<List<GradeOption>> fetchGrades(String orgId) {
    return SyncService.instance.cached<List<GradeOption>>(
      'grades:$orgId',
      () => _client
          .from('recitation_grades')
          .select('key, label, points')
          .eq('organization_id', orgId)
          .eq('is_active', true)
          .order('sort_order'),
      (rows) => [for (final r in rows as List) GradeOption(key: r['key'] as String, label: r['label'] as String, points: r['points'] as int)],
    );
  }

  /// Circles the signed-in teacher teaches (an admin sees all of them).
  Future<List<MyCircle>> fetchMyCircles(String orgId, {required String userId, required bool isAdmin}) {
    return SyncService.instance.cached<List<MyCircle>>('mycircles:$orgId:$isAdmin', () async {
      var query = _client
          .from('circles')
          .select('id, name, teacher_id, stages(name), students_profile(count)')
          .eq('organization_id', orgId)
          .eq('status', 'active');
      final assistantIn = <String>{};
      if (!isAdmin) {
        // primary teacher or assistant (0046)
        final mine = await _client.rpc('my_circle_ids', params: {'p_org': orgId}) as List;
        if (mine.isEmpty) return <dynamic>[];
        for (final m in mine) {
          if (m['assistant'] == true) assistantIn.add(m['id'] as String);
        }
        query = query.inFilter('id', [for (final m in mine) m['id'] as String]);
      }
      final rows = await query.order('name');
      return [for (final r in rows) {...Map<String, dynamic>.from(r as Map), 'assistant': assistantIn.contains(r['id'])}];
    }, (rows) => _parseCircles(rows));
  }

  List<MyCircle> _parseCircles(dynamic rows) {
    return (rows as List).map((r) {
      final stage = r['stages'] as Map<String, dynamic>?;
      final counts = r['students_profile'] as List?;
      final count = counts != null && counts.isNotEmpty ? (counts.first['count'] as int? ?? 0) : 0;
      return MyCircle(id: r['id'] as String, name: r['name'] as String, stageName: stage?['name'] as String?, studentCount: count, assistant: r['assistant'] == true);
    }).toList();
  }

  Future<List<CircleStudent>> fetchCircleStudents(String circleId) {
    return SyncService.instance.cached<List<CircleStudent>>('circle-students:$circleId', () async {
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
      // each student's latest recitation, wherever it was (newest first: the first row per student wins)
      final ids = [for (final r in results[0] as List) r['id'] as String];
      final last = ids.isEmpty
          ? <dynamic>[]
          : await _client
              .from('daily_achievements')
              .select('student_id, achievement_type, surah_from, ayah_from, ayah_to, grade, created_at')
              .inFilter('student_id', ids)
              .order('created_at', ascending: false)
              .limit(ids.length * 15);
      // one JSON-able snapshot so it can be cached as a whole
      return {'students': results[0], 'recited': results[1], 'attendance': results[2], 'today': today, 'last': last};
    }, (json) {
      final data = json as Map<String, dynamic>;
      final recitedCount = <String, int>{};
      for (final r in data['recited'] as List) {
        final id = r['student_id'] as String;
        recitedCount[id] = (recitedCount[id] ?? 0) + 1;
      }
      final attendance = {for (final a in data['attendance'] as List) a['student_id'] as String: a['status'] as String};
      final today = data['today'] as String;
      final lastBy = <String, LastRecitation>{};
      for (final r in (data['last'] as List?) ?? const []) {
        final id = r['student_id'] as String;
        if (lastBy.containsKey(id) || r['surah_from'] == null) continue;
        lastBy[id] = LastRecitation(
          type: r['achievement_type'] as String,
          surah: r['surah_from'] as int,
          ayahFrom: (r['ayah_from'] as int?) ?? 1,
          ayahTo: (r['ayah_to'] as int?) ?? (r['ayah_from'] as int?) ?? 1,
          grade: r['grade'] as String?,
          createdAt: r['created_at'] as String,
        );
      }

      return (data['students'] as List).map((s) {
        final id = s['id'] as String;
        final sync = SyncService.instance;
        return CircleStudent(
          id: id,
          fullName: s['full_name'] as String,
          studentCode: s['student_code'] as String,
          totalPoints: (s['total_points'] as int?) ?? 0,
          // what is still waiting on the phone already counts as done here
          recitedToday: (recitedCount[id] ?? 0) + sync.pendingRecitationsToday(id),
          attendanceToday: sync.pendingAttendance(id, today) ?? attendance[id],
          nextPlan: s['next_plan'] as String?,
          lastRecitation: lastBy[id],
        );
      }).toList();
    });
  }

  String newSessionGroupId() => _uuid.v4();

  Future<RecitationResult> logRecitation({
    required String orgId,
    required String studentId,
    String? studentName,
    required String type,
    required SurahPart part,
    required String grade,
    String? notes,
    DateTime? recordedAt,
    String? sessionGroupId,
  }) async {
    final params = {
      'p_org': orgId,
      'p_student_id': studentId,
      'p_type': type,
      'p_surah': part.surah,
      'p_ayah_from': part.ayahFrom,
      'p_ayah_to': part.ayahTo,
      'p_grade': grade,
      'p_notes': notes,
      // Fixed BEFORE the first attempt: a retry (bad network, or the outbox
      // replaying it later) is safe because the server ignores a repeated ref.
      'p_client_ref': _uuid.v4(),
      'p_recorded_at': (recordedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'p_session_group_id': sessionGroupId,
    };
    final outcome = await SyncService.instance.submit(
      'log_recitation',
      params,
      label: fmt(currentStrings.rec.outboxRecitation, {'studentName': studentName ?? '', 'surah': part.surah, 'ayahFrom': part.ayahFrom, 'ayahTo': part.ayahTo}),
    );
    if (outcome.queued) return const RecitationResult(pointsAwarded: 0, newTotalPoints: null, wasDuplicate: false, queued: true);
    final result = outcome.data as Map<String, dynamic>;
    return RecitationResult(
      pointsAwarded: (result['points_awarded'] as num?)?.toInt() ?? 0,
      newTotalPoints: (result['new_total_points'] as num?)?.toInt(),
      wasDuplicate: result['was_duplicate'] as bool? ?? false,
    );
  }

  /// Returns true when the mark was stored on the phone instead of reaching the server.
  Future<bool> setAttendance({
    required String orgId,
    required String circleId,
    required String studentId,
    String? studentName,
    required String status,
  }) async {
    final now = DateTime.now();
    final today = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final outcome = await SyncService.instance.submit(
      'attendance',
      {
        'rows': [
          {'organization_id': orgId, 'student_id': studentId, 'circle_id': circleId, 'session_date': today, 'status': status},
        ],
      },
      label: fmt(currentStrings.rec.outboxAttendance, {'studentName': studentName ?? '', 'status': status}),
      orderKey: 'att:$studentId:$today',
    );
    return outcome.queued;
  }

  /// The student's latest new-memorization recitations, newest first - for the smart start of the
  /// recitation sheet (next_position.dart). Cached, so it works offline too.
  Future<List<MemorizedPart>> fetchMemorizationHistory(String studentId) {
    return SyncService.instance.cached<List<MemorizedPart>>(
      'memorized:$studentId',
      () => _client
          .from('daily_achievements')
          .select('surah_from, ayah_from, ayah_to')
          .eq('student_id', studentId)
          .eq('achievement_type', 'new_memorization')
          .not('surah_from', 'is', null)
          .order('created_at', ascending: false)
          .limit(12),
      (rows) => [
        for (final r in rows as List)
          MemorizedPart(
            surah: r['surah_from'] as int,
            ayahFrom: (r['ayah_from'] as int?) ?? 1,
            ayahTo: (r['ayah_to'] as int?) ?? (r['ayah_from'] as int?) ?? 1,
          ),
      ],
    );
  }

  Future<List<RecitationEntry>> fetchStudentRecitations(String studentId, {int limit = 60}) async {
    final rows = (await SyncService.instance.raw('rec.fetchStudentRecitations:$studentId:$limit', () => _client
        .from('daily_achievements')
        .select('id, achievement_type, surah_from, ayah_from, ayah_to, grade, points_awarded, notes, created_at')
        .eq('student_id', studentId)
        .order('created_at', ascending: false)
        .limit(limit))) as List<dynamic>;
    final sync = SyncService.instance;
    final deleted = {for (final i in sync.pendingOf('recitation_delete')) i.payload['p_id'] as String};
    final edits = {for (final i in sync.pendingOf('recitation_update')) i.payload['p_id'] as String: i.payload};
    return [
      // recorded on this phone and still waiting to upload - shown first, as the newest
      for (final i in sync.pendingOf('log_recitation').reversed)
        if (i.payload['p_student_id'] == studentId)
          RecitationEntry(
            id: 'local-${i.id}',
            type: i.payload['p_type'] as String,
            surah: i.payload['p_surah'] as int,
            ayahFrom: i.payload['p_ayah_from'] as int,
            ayahTo: i.payload['p_ayah_to'] as int,
            grade: i.payload['p_grade'] as String?,
            points: 0,
            createdAt: (i.payload['p_recorded_at'] as String?) ?? i.createdAt.toUtc().toIso8601String(),
            notes: i.payload['p_notes'] as String?,
            pending: true,
          ),
      for (final r in rows)
        if (!deleted.contains(r['id']))
          RecitationEntry(
            id: r['id'] as String,
            type: (edits[r['id']]?['p_type'] ?? r['achievement_type']) as String,
            surah: (edits[r['id']]?['p_surah'] ?? r['surah_from']) as int,
            ayahFrom: (edits[r['id']]?['p_ayah_from'] ?? r['ayah_from']) as int,
            ayahTo: (edits[r['id']]?['p_ayah_to'] ?? r['ayah_to']) as int,
            grade: (edits[r['id']]?['p_grade'] ?? r['grade']) as String?,
            points: (r['points_awarded'] as num?)?.toInt() ?? 0,
            createdAt: r['created_at'] as String,
            notes: (edits.containsKey(r['id']) ? edits[r['id']]!['p_notes'] : r['notes']) as String?,
            pending: edits.containsKey(r['id']),
          ),
    ];
  }

  /// Returns true when the change was kept on the phone (no connection).
  Future<bool> updateRecitation({
    required String id,
    required String type,
    required SurahPart part,
    required String grade,
    String? notes,
  }) async {
    final outcome = await SyncService.instance.submit(
      'recitation_update',
      {
        'p_id': id,
        'p_type': type,
        'p_surah': part.surah,
        'p_ayah_from': part.ayahFrom,
        'p_ayah_to': part.ayahTo,
        'p_grade': grade,
        'p_notes': notes,
      },
      label: currentStrings.ui.outboxEditRecitation,
      orderKey: 'rec:$id',
    );
    return outcome.queued;
  }

  /// Returns true when the delete was kept on the phone (no connection).
  Future<bool> deleteRecitation(String id) async =>
      (await SyncService.instance.submit('recitation_delete', {'p_id': id}, label: currentStrings.ui.outboxDeleteRecitation, orderKey: 'rec:$id')).queued;

  /// Returns true when it was kept on the phone (no connection).
  Future<bool> setStudentPlan({required String orgId, required String studentId, required String? plan}) async {
    final outcome = await SyncService.instance.submit(
      'student_plan',
      {'p_org': orgId, 'p_student': studentId, 'p_next_plan': plan},
      label: currentStrings.ui.outboxPlan,
      orderKey: 'plan:$studentId',
    );
    return outcome.queued;
  }

  /// The plan still waiting on the phone for [studentId] (null when none is waiting).
  static ({String? plan})? pendingPlan(String studentId) {
    final waiting = SyncService.instance.pendingOf('student_plan').where((i) => i.payload['p_student'] == studentId);
    return waiting.isEmpty ? null : (plan: waiting.last.payload['p_next_plan'] as String?);
  }

  Future<TeacherToday> fetchTeacherToday(String orgId) async {
    final data = (await SyncService.instance.raw('rec.fetchTeacherToday:$orgId', () => _client.rpc('get_teacher_today', params: {'p_org': orgId}))) as Map<String, dynamic>;
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
