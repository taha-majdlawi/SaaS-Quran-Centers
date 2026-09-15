import 'package:supabase_flutter/supabase_flutter.dart';

class ActivitySummary {
  const ActivitySummary({required this.id, required this.title, this.description, this.scheduledAt});
  final String id;
  final String title;
  final String? description;
  final String? scheduledAt;
}

/// Mirrors apps/web's activities/actions.ts.
class ActivitiesRepository {
  ActivitiesRepository(this._client);

  final SupabaseClient _client;

  Future<List<ActivitySummary>> fetchActivities(String organizationId) async {
    final rows = await _client
        .from('activities')
        .select('id, title, description, scheduled_at')
        .eq('organization_id', organizationId)
        .order('scheduled_at', ascending: false);
    return (rows as List)
        .map((r) => ActivitySummary(
              id: r['id'] as String,
              title: r['title'] as String,
              description: r['description'] as String?,
              scheduledAt: r['scheduled_at'] as String?,
            ))
        .toList();
  }

  Future<ActivitySummary?> fetchActivity(String id) async {
    final row = await _client
        .from('activities')
        .select('id, title, description, scheduled_at')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return ActivitySummary(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      scheduledAt: row['scheduled_at'] as String?,
    );
  }

  Future<void> createActivity({
    required String organizationId,
    required String title,
    String? description,
    String? scheduledAt,
    required String? createdBy,
  }) {
    return _client.from('activities').insert({
      'organization_id': organizationId,
      'title': title,
      'description': description,
      'scheduled_at': scheduledAt,
      'created_by': createdBy,
    });
  }

  Future<void> updateActivity({
    required String id,
    required String title,
    String? description,
    String? scheduledAt,
  }) {
    return _client.from('activities').update({
      'title': title,
      'description': description,
      'scheduled_at': scheduledAt,
    }).eq('id', id);
  }

  Future<void> deleteActivity(String id) {
    return _client.from('activities').delete().eq('id', id);
  }
}
