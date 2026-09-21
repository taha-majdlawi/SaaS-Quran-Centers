import 'package:supabase_flutter/supabase_flutter.dart';

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
        for (final r in _list(await _client.rpc('due_reviews', params: {'p_org': orgId, 'p_circle': circleId})))
          DueReview(
            studentId: r['student_id'] as String,
            studentName: r['student_name'] as String,
            circleName: r['circle_name'] as String?,
            surah: (r['surah'] as num).toInt(),
            daysOverdue: (r['days_overdue'] as num).toInt(),
          ),
      ];

  Future<Set<String>> checkedInCircles(String orgId) async =>
      {for (final r in _list(await _client.rpc('teacher_today_attendance', params: {'p_org': orgId}))) r['circle_id'] as String};

  Future<void> checkIn(String orgId, String circleId) => _client.rpc('teacher_check_in', params: {'p_org': orgId, 'p_circle': circleId, 'p_date': null});

  Future<List<StudentNote>> notes(String orgId, String studentId) async => [
        for (final n in _list(await _client.rpc('list_student_notes', params: {'p_org': orgId, 'p_student': studentId})))
          StudentNote(id: n['id'] as String, body: n['body'] as String, visibility: n['visibility'] as String, createdAt: n['created_at'] as String, author: n['author'] as String?),
      ];

  Future<void> addNote(String orgId, String studentId, String body, {bool guardianVisible = false}) => _client.rpc('add_student_note', params: {
        'p_org': orgId,
        'p_student': studentId,
        'p_body': body,
        'p_visibility': guardianVisible ? 'guardian_visible' : 'staff_only',
      });

  Future<SearchResults> search(String orgId, String q) async {
    final j = Map<String, dynamic>.from(await _client.rpc('search_global', params: {'p_org': orgId, 'p_q': q, 'p_limit': 20}) as Map);
    return SearchResults(students: _list(j['students']), teachers: _list(j['teachers']), circles: _list(j['circles']));
  }

  Future<List<Map<String, dynamic>>> dropoutRisk(String orgId) async => _list(await _client.rpc('admin_dropout_risk', params: {'p_org': orgId, 'p_limit': 8}));

  Future<List<Map<String, dynamic>>> teacherPerformance(String orgId) async =>
      _list(await _client.rpc('admin_teacher_performance', params: {'p_org': orgId, 'p_days': 7}));
}
