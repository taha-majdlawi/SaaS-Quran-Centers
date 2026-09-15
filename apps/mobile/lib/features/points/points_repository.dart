import 'package:supabase_flutter/supabase_flutter.dart';

class PointsConfigData {
  const PointsConfigData({
    required this.newMemorization,
    required this.recentReview,
    required this.distantReview,
    required this.currencyName,
  });

  final int newMemorization;
  final int recentReview;
  final int distantReview;
  final String currencyName;
}

/// Mirrors apps/web's points/actions.ts - one row per org in each of
/// points_config and currency_config, upserted together.
class PointsRepository {
  PointsRepository(this._client);

  final SupabaseClient _client;

  Future<PointsConfigData> fetchConfig(String organizationId) async {
    final results = await Future.wait([
      _client.from('points_config').select('rules').eq('organization_id', organizationId).maybeSingle(),
      _client
          .from('currency_config')
          .select('currency_name')
          .eq('organization_id', organizationId)
          .maybeSingle(),
    ]);
    final rules = (results[0]?['rules'] as Map<String, dynamic>?) ?? const {};
    return PointsConfigData(
      newMemorization: (rules['new_memorization'] as num?)?.toInt() ?? 10,
      recentReview: (rules['recent_review'] as num?)?.toInt() ?? 5,
      distantReview: (rules['distant_review'] as num?)?.toInt() ?? 3,
      currencyName: (results[1]?['currency_name'] as String?) ?? 'نقاط',
    );
  }

  Future<void> saveConfig({
    required String organizationId,
    required int newMemorization,
    required int recentReview,
    required int distantReview,
    required String currencyName,
  }) async {
    final now = DateTime.now().toIso8601String();
    await Future.wait([
      _client.from('points_config').upsert({
        'organization_id': organizationId,
        'rules': {
          'new_memorization': newMemorization,
          'recent_review': recentReview,
          'distant_review': distantReview,
        },
        'updated_at': now,
      }),
      _client.from('currency_config').upsert({
        'organization_id': organizationId,
        'currency_name': currencyName,
        'updated_at': now,
      }),
    ]);
  }
}
