import 'package:supabase_flutter/supabase_flutter.dart';

class BadgeSummary {
  const BadgeSummary({required this.id, required this.name, this.description});
  final String id;
  final String name;
  final String? description;
}

class BadgeStudentOption {
  const BadgeStudentOption({required this.id, required this.fullName});
  final String id;
  final String fullName;
}

class RecentAward {
  const RecentAward({required this.studentName, required this.badgeName});
  final String studentName;
  final String badgeName;
}

/// Mirrors apps/web's badges/actions.ts - a per-org badge catalog plus
/// awards (student_badges), unique on (badge_id, student_id).
class BadgesRepository {
  BadgesRepository(this._client);

  final SupabaseClient _client;

  Future<List<BadgeSummary>> fetchBadges(String organizationId) async {
    final rows = await _client
        .from('badges')
        .select('id, name, description')
        .eq('organization_id', organizationId)
        .order('name');
    return (rows as List)
        .map((r) => BadgeSummary(id: r['id'] as String, name: r['name'] as String, description: r['description'] as String?))
        .toList();
  }

  Future<List<BadgeStudentOption>> fetchActiveStudents(String organizationId) async {
    final rows = await _client
        .from('students_profile')
        .select('id, full_name')
        .eq('organization_id', organizationId)
        .eq('status', 'active')
        .order('full_name');
    return (rows as List)
        .map((r) => BadgeStudentOption(id: r['id'] as String, fullName: r['full_name'] as String))
        .toList();
  }

  Future<List<RecentAward>> fetchRecentAwards(String organizationId) async {
    final rows = await _client
        .from('student_badges')
        .select('id, awarded_at, badges!inner(name, organization_id), students_profile(full_name)')
        .eq('badges.organization_id', organizationId)
        .order('awarded_at', ascending: false)
        .limit(10);
    return (rows as List).map((r) {
      final badge = r['badges'] as Map<String, dynamic>?;
      final student = r['students_profile'] as Map<String, dynamic>?;
      return RecentAward(
        studentName: (student?['full_name'] as String?) ?? '—',
        badgeName: (badge?['name'] as String?) ?? '—',
      );
    }).toList();
  }

  Future<BadgeSummary?> fetchBadge(String id) async {
    final row = await _client.from('badges').select('id, name, description').eq('id', id).maybeSingle();
    if (row == null) return null;
    return BadgeSummary(id: row['id'] as String, name: row['name'] as String, description: row['description'] as String?);
  }

  Future<void> createBadge({required String organizationId, required String name, String? description}) {
    return _client.from('badges').insert({'organization_id': organizationId, 'name': name, 'description': description});
  }

  Future<void> updateBadge({required String id, required String name, String? description}) {
    return _client.from('badges').update({'name': name, 'description': description}).eq('id', id);
  }

  Future<void> deleteBadge(String id) {
    return _client.from('badges').delete().eq('id', id);
  }

  /// Throws a PostgrestException with code 23505 if already awarded.
  Future<void> awardBadge({required String badgeId, required String studentId, required String? awardedBy}) {
    return _client.from('student_badges').insert({
      'badge_id': badgeId,
      'student_id': studentId,
      'awarded_by': awardedBy,
    });
  }
}
