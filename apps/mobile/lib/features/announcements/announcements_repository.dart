import 'package:supabase_flutter/supabase_flutter.dart';

const kAnnouncementAudienceLabels = {
  'all': 'الكل',
  'teachers': 'المعلمون',
  'students': 'الطلاب',
  'guardians': 'أولياء الأمور',
};

class AnnouncementSummary {
  const AnnouncementSummary({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String body;
  final String audience;
  final String? publishedAt;
}

/// Mirrors apps/web's announcements/actions.ts.
class AnnouncementsRepository {
  AnnouncementsRepository(this._client);

  final SupabaseClient _client;

  Future<List<AnnouncementSummary>> fetchAnnouncements(String organizationId) async {
    final rows = await _client
        .from('announcements')
        .select('id, title, body, audience, published_at')
        .eq('organization_id', organizationId)
        .order('published_at', ascending: false);
    return (rows as List)
        .map((r) => AnnouncementSummary(
              id: r['id'] as String,
              title: r['title'] as String,
              body: r['body'] as String,
              audience: r['audience'] as String,
              publishedAt: r['published_at'] as String?,
            ))
        .toList();
  }

  Future<AnnouncementSummary?> fetchAnnouncement(String id) async {
    final row = await _client
        .from('announcements')
        .select('id, title, body, audience, published_at')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return AnnouncementSummary(
      id: row['id'] as String,
      title: row['title'] as String,
      body: row['body'] as String,
      audience: row['audience'] as String,
      publishedAt: row['published_at'] as String?,
    );
  }

  Future<void> createAnnouncement({
    required String organizationId,
    required String title,
    required String body,
    required String audience,
    required String? createdBy,
  }) {
    return _client.from('announcements').insert({
      'organization_id': organizationId,
      'title': title,
      'body': body,
      'audience': audience,
      'created_by': createdBy,
      'published_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String body,
    required String audience,
  }) {
    return _client.from('announcements').update({'title': title, 'body': body, 'audience': audience}).eq('id', id);
  }

  Future<void> deleteAnnouncement(String id) {
    return _client.from('announcements').delete().eq('id', id);
  }
}
