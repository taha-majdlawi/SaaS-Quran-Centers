import 'package:supabase_flutter/supabase_flutter.dart';

class ChallengeSummary {
  const ChallengeSummary({
    required this.id,
    required this.title,
    required this.metric,
    required this.startsOn,
    required this.endsOn,
  });

  final String id;
  final String title;
  final String metric;
  final String startsOn;
  final String endsOn;
}

class ChallengeCircleScore {
  const ChallengeCircleScore({required this.circleId, required this.circleName, required this.score});
  final String circleId;
  final String circleName;
  final num score;
}

/// Mirrors apps/web's circle-challenges/actions.ts - a challenge per org
/// with one score per circle, upserted on (challenge_id, circle_id).
class CircleChallengesRepository {
  CircleChallengesRepository(this._client);

  final SupabaseClient _client;

  Future<List<ChallengeSummary>> fetchChallenges(String organizationId) async {
    final rows = await _client
        .from('circle_challenges')
        .select('id, title, metric, starts_on, ends_on')
        .eq('organization_id', organizationId)
        .order('starts_on', ascending: false);
    return (rows as List)
        .map((r) => ChallengeSummary(
              id: r['id'] as String,
              title: r['title'] as String,
              metric: r['metric'] as String,
              startsOn: r['starts_on'] as String,
              endsOn: r['ends_on'] as String,
            ))
        .toList();
  }

  Future<void> createChallenge({
    required String organizationId,
    required String title,
    required String metric,
    required String startsOn,
    required String endsOn,
  }) {
    return _client.from('circle_challenges').insert({
      'organization_id': organizationId,
      'title': title,
      'metric': metric,
      'starts_on': startsOn,
      'ends_on': endsOn,
    });
  }

  Future<void> deleteChallenge(String id) {
    return _client.from('circle_challenges').delete().eq('id', id);
  }

  Future<ChallengeSummary?> fetchChallenge(String id) async {
    final row = await _client
        .from('circle_challenges')
        .select('id, title, metric, starts_on, ends_on')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return ChallengeSummary(
      id: row['id'] as String,
      title: row['title'] as String,
      metric: row['metric'] as String,
      startsOn: row['starts_on'] as String,
      endsOn: row['ends_on'] as String,
    );
  }

  Future<List<ChallengeCircleScore>> fetchScoreboard(String organizationId, String challengeId) async {
    final results = await Future.wait([
      _client.from('circles').select('id, name').eq('organization_id', organizationId).order('name'),
      _client.from('circle_challenge_entries').select('circle_id, score').eq('challenge_id', challengeId),
    ]);
    final circles = results[0] as List;
    final entries = results[1] as List;
    final scoreByCircle = {for (final e in entries) e['circle_id'] as String: e['score'] as num};
    return circles
        .map((c) => ChallengeCircleScore(
              circleId: c['id'] as String,
              circleName: c['name'] as String,
              score: scoreByCircle[c['id']] ?? 0,
            ))
        .toList();
  }

  Future<void> saveScores(String challengeId, Map<String, num> scoreByCircleId) async {
    if (scoreByCircleId.isEmpty) return;
    final rows = scoreByCircleId.entries
        .map((e) => {'challenge_id': challengeId, 'circle_id': e.key, 'score': e.value})
        .toList();
    await _client.from('circle_challenge_entries').upsert(rows, onConflict: 'challenge_id,circle_id');
  }
}
