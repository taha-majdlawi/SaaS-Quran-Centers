import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/offline/sync_service.dart';

String _d(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// A date range for the profiles, and the one it is compared with.
class ProfilePeriod {
  const ProfilePeriod(this.key, this.from, this.to);

  /// 'month' (1st of this month .. today), 'last_month', '90' (last 90 days).
  final String key;
  final DateTime from;
  final DateTime to;

  String get fromIso => _d(from);
  String get toIso => _d(to);

  static ProfilePeriod of(String key, [DateTime? now]) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return switch (key) {
      'last_month' => ProfilePeriod(key, DateTime(n.year, n.month - 1, 1), DateTime(n.year, n.month, 0)),
      '90' => ProfilePeriod(key, today.subtract(const Duration(days: 89)), today),
      _ => ProfilePeriod('month', DateTime(n.year, n.month, 1), today),
    };
  }

  /// Same rule as the web: from the 1st -> the same days of the month before; otherwise the same length just before.
  ProfilePeriod get previous {
    if (from.day == 1 && from.year == to.year && from.month == to.month) {
      final lastPrev = DateTime(from.year, from.month, 0).day;
      final lastThis = DateTime(to.year, to.month + 1, 0).day;
      final day = to.day == lastThis ? lastPrev : (to.day < lastPrev ? to.day : lastPrev);
      return ProfilePeriod('$key.prev', DateTime(from.year, from.month - 1, 1), DateTime(from.year, from.month - 1, day));
    }
    final days = to.difference(from).inDays + 1;
    final end = from.subtract(const Duration(days: 1));
    return ProfilePeriod('$key.prev', end.subtract(Duration(days: days - 1)), end);
  }
}

/// The teacher / circle profiles and a student's memorization goal: all
/// computed in SQL (the same numbers as the web) and kept for offline use.
class ProfilesRepository {
  ProfilesRepository(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> teacher(String orgId, String id, ProfilePeriod p) async => (await SyncService.instance.raw(
        'prof.teacher:$orgId:$id:${p.fromIso}:${p.toIso}',
        () => _client.rpc('teacher_profile', params: {'p_org': orgId, 'p_id': id, 'p_from': p.fromIso, 'p_to': p.toIso}),
      )) as Map<String, dynamic>;

  Future<Map<String, dynamic>> circle(String orgId, String circleId, ProfilePeriod p) async => (await SyncService.instance.raw(
        'prof.circle:$orgId:$circleId:${p.fromIso}:${p.toIso}',
        () => _client.rpc('circle_profile', params: {'p_org': orgId, 'p_circle': circleId, 'p_from': p.fromIso, 'p_to': p.toIso}),
      )) as Map<String, dynamic>;

  /// The previous period's totals, or null when it cannot be had (offline and never loaded).
  Future<Map<String, dynamic>?> previousTotals(Future<Map<String, dynamic>> Function() load) async {
    try {
      return (await load())['totals'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// This week against the last (and the goal and the teacher's note) - the family's weekly report.
  Future<Map<String, dynamic>> weekly(String orgId, String studentId) async => (await SyncService.instance.raw(
        'prof.weekly:$orgId:$studentId',
        () => _client.rpc('student_weekly_report', params: {'p_org': orgId, 'p_student': studentId}),
      )) as Map<String, dynamic>;

  static String goalKey(String orgId, String studentId) => 'prof.goal:$orgId:$studentId';

  Future<Map<String, dynamic>> goal(String orgId, String studentId) async => (await SyncService.instance.raw(
        goalKey(orgId, studentId),
        () => _client.rpc('student_goal_progress', params: {'p_org': orgId, 'p_student': studentId}),
      )) as Map<String, dynamic>;

  /// Saves the goal now, or queues it (it is an upsert, safe to replay).
  Future<SubmitOutcome> setGoal(String orgId, String studentId, {required double pagesPerDay, int targetPages = 604, String? note, required String label}) =>
      SyncService.instance.submit(
        'student_goal',
        {'p_org': orgId, 'p_student': studentId, 'p_pages_per_day': pagesPerDay, 'p_target_pages': targetPages, 'p_note': note},
        label: label,
        orderKey: 'goal:$studentId',
      );

  Future<void> clearGoal(String orgId, String studentId) => _client.rpc('clear_student_goal', params: {'p_org': orgId, 'p_student': studentId});
}
