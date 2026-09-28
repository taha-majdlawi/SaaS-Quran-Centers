import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/offline/sync_service.dart';
import '../../core/i18n/i18n.dart';

List<Map<String, dynamic>> _list(dynamic v) => [for (final e in (v as List? ?? const [])) Map<String, dynamic>.from(e as Map)];

/// One spaced-review item: a surah a student should review today.
class DueReview {
  const DueReview({required this.studentId, required this.studentName, required this.circleName, required this.surah, required this.daysOverdue});
  final String studentId;
  final String studentName;
  final String? circleName;
  final int surah;
  final int daysOverdue;
}

class StudentNote {
  const StudentNote({required this.id, required this.body, required this.visibility, required this.createdAt, this.author});
  final String id;
  final String body;
  final String visibility;
  final String createdAt;
  final String? author;
}

class SearchResults {
  const SearchResults({required this.students, required this.teachers, required this.circles});
  final List<Map<String, dynamic>> students;
  final List<Map<String, dynamic>> teachers;
  final List<Map<String, dynamic>> circles;
}

/// Spaced review, teacher check-in, notes, search and the admin insight RPCs (0044).
class InsightsRepository {
  InsightsRepository(this._client);
  final SupabaseClient _client;

  Future<List<DueReview>> dueReviews(String orgId, {String? circleId}) async => [
        for (final r in _list((await SyncService.instance.raw('ins.dueReviews:$orgId:$circleId', () => _client.rpc('due_reviews', params: {'p_org': orgId, 'p_circle': circleId})))))
          DueReview(
            studentId: r['student_id'] as String,
            studentName: r['student_name'] as String,
            circleName: r['circle_name'] as String?,
            surah: (r['surah'] as num).toInt(),
            daysOverdue: (r['days_overdue'] as num).toInt(),
          ),
      ];

  static final Map<String, ({DateTime at, Future<Set<String>> future})> _checkedInMemo = {};

  /// Circles the signed-in teacher already checked in to today. Cards on the same screen share one request.
  Future<Set<String>> checkedInCircles(String orgId) {
    final memo = _checkedInMemo[orgId];
    if (memo != null && DateTime.now().difference(memo.at) < const Duration(seconds: 20)) return memo.future;
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    Future<Set<String>> fetch() async => {
          for (final r in _list((await SyncService.instance.raw('ins.checkedInCircles:$orgId', () => _client.rpc('teacher_today_attendance', params: {'p_org': orgId}))))) r['circle_id'] as String,
          // a check-in still waiting on the phone already counts
          for (final i in SyncService.instance.pendingOf('teacher_check_in'))
            if (i.payload['p_date'] == today) i.payload['p_circle'] as String,
        };
    final future = fetch();
    _checkedInMemo[orgId] = (at: DateTime.now(), future: future);
    future.catchError((_) {
      _checkedInMemo.remove(orgId);
      return <String>{};
    });
    return future;
  }

  /// Returns true when it was kept on the phone (no connection) - it uploads by itself later.
  Future<bool> checkIn(String orgId, String circleId) async {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    // the day is fixed now, so a check-in queued before midnight still counts for today
    final outcome = await SyncService.instance.submit(
      'teacher_check_in',
      {'p_org': orgId, 'p_circle': circleId, 'p_date': today},
      label: currentStrings.ui.outboxCheckIn,
      orderKey: 'checkin:$circleId:$today',
    );
    _checkedInMemo.remove(orgId);
    return outcome.queued;
  }

  Future<List<StudentNote>> notes(String orgId, String studentId) async => [
        // written on this phone, not uploaded yet
        for (final i in SyncService.instance.pendingOf('student_note').reversed)
          if (i.payload['p_student'] == studentId)
            StudentNote(
              id: 'local-${i.id}',
              body: i.payload['p_body'] as String,
              visibility: i.payload['p_visibility'] as String,
              createdAt: i.createdAt.toUtc().toIso8601String(),
              author: currentStrings.ui.waitingUpload,
            ),
        for (final n in _list((await SyncService.instance.raw('ins.notes:$orgId:$studentId', () => _client.rpc('list_student_notes', params: {'p_org': orgId, 'p_student': studentId})))))
          StudentNote(id: n['id'] as String, body: n['body'] as String, visibility: n['visibility'] as String, createdAt: n['created_at'] as String, author: n['author'] as String?),
      ];

  /// Returns true when it was kept on the phone (no connection).
  Future<bool> addNote(String orgId, String studentId, String body, {bool guardianVisible = false}) async {
    final outcome = await SyncService.instance.submit(
      'student_note',
      {
        'p_org': orgId,
        'p_student': studentId,
        'p_body': body,
        'p_visibility': guardianVisible ? 'guardian_visible' : 'staff_only',
        'p_client_ref': const Uuid().v4(), // a replay never adds it twice (0070)
      },
      label: currentStrings.ui.outboxNote,
    );
    return outcome.queued;
  }

  Future<SearchResults> search(String orgId, String q) async {
    final j = Map<String, dynamic>.from(await _client.rpc('search_global', params: {'p_org': orgId, 'p_q': q, 'p_limit': 20}) as Map);
    return SearchResults(students: _list(j['students']), teachers: _list(j['teachers']), circles: _list(j['circles']));
  }

  Future<List<Map<String, dynamic>>> dropoutRisk(String orgId) async => _list((await SyncService.instance.raw('ins.dropoutRisk:$orgId', () => _client.rpc('admin_dropout_risk', params: {'p_org': orgId, 'p_limit': 8}))));

  Future<List<Map<String, dynamic>>> teacherPerformance(String orgId) async =>
      _list((await SyncService.instance.raw('ins.teacherPerformance:$orgId', () => _client.rpc('admin_teacher_performance', params: {'p_org': orgId, 'p_days': 7}))));
}
