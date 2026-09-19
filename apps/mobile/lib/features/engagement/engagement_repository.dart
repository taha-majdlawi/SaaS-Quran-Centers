import 'package:supabase_flutter/supabase_flutter.dart';

import 'engagement_models.dart';

/// Mirrors apps/web's market / badges / circle-challenges actions. Every rule
/// (balance, stock, conversion rate, who may award, ranking) lives in SQL RPCs.
class EngagementRepository {
  EngagementRepository(this._client);

  final SupabaseClient _client;

  Map<String, dynamic> _map(dynamic v) => v as Map<String, dynamic>;
  List<Map<String, dynamic>> _list(dynamic v) => [for (final e in (v as List? ?? const [])) e as Map<String, dynamic>];

  // ---- market: family ------------------------------------------------------

  Future<StudentMarket> studentMarket(String orgId, String studentId) async =>
      StudentMarket.fromJson(_map(await _client.rpc('get_student_market', params: {'p_org': orgId, 'p_student': studentId})));

  Future<void> buy(String orgId, String studentId, String itemId) =>
      _client.rpc('purchase_market_item', params: {'p_org': orgId, 'p_student': studentId, 'p_item': itemId});

  Future<void> cancelPurchase(String purchaseId) => _client.rpc('cancel_my_purchase', params: {'p_purchase': purchaseId});

  // ---- market: admin -------------------------------------------------------

  Future<MarketOverview> marketOverview(String orgId) async =>
      MarketOverview.fromJson(_map(await _client.rpc('admin_market_overview', params: {'p_org': orgId})));

  Future<List<WalletRow>> marketWallets(String orgId) async {
    final rows = _list(await _client.rpc('admin_market_wallets', params: {'p_org': orgId}));
    return [
      for (final r in rows)
        WalletRow(studentId: r['student_id'] as String, name: r['student_name'] as String, code: (r['student_code'] as String?) ?? '', wallet: Wallet.fromJson(r)),
    ];
  }

  Future<void> setPurchaseStatus(String purchaseId, String status) =>
      _client.rpc('admin_set_purchase_status', params: {'p_purchase': purchaseId, 'p_status': status});

  Future<void> saveConfig(String orgId, {required int pointsPerUnit, required num unitValue, required String symbol}) => _client.rpc(
        'set_market_config',
        params: {'p_org': orgId, 'p_points_per_unit': pointsPerUnit, 'p_unit_value': unitValue, 'p_symbol': symbol},
      );

  Future<void> saveItem(
    String orgId, {
    String? id,
    required String name,
    String? description,
    String? imageUrl,
    required num price,
    int? stock,
    required bool isActive,
  }) {
    return _client.rpc('save_market_item', params: {
      'p_org': orgId,
      'p_id': id,
      'p_name': name,
      'p_description': description,
      'p_image_url': imageUrl,
      'p_price': price,
      'p_stock': stock,
      'p_is_active': isActive,
    });
  }

  Future<void> deleteItem(String orgId, String id) => _client.rpc('delete_market_item', params: {'p_org': orgId, 'p_id': id});

  // ---- badges --------------------------------------------------------------

  Future<List<BadgeProgress>> studentBadges(String orgId, String studentId) async => [
        for (final b in _list(await _client.rpc('get_student_badges', params: {'p_org': orgId, 'p_student': studentId})))
          BadgeProgress.fromJson(b),
      ];

  Future<List<BadgeDef>> badgeDefs(String orgId) async {
    final rows = await _client.from('badges').select('*').eq('organization_id', orgId).order('sort_order').order('name');
    return [for (final r in rows as List) BadgeDef.fromJson(r as Map<String, dynamic>)];
  }

  Future<void> saveBadge(
    String orgId, {
    String? id,
    required String name,
    String? description,
    required String icon,
    required String color,
    required String ruleType,
    required int threshold,
    String? param,
    int? durationDays,
    required bool isActive,
    required int sortOrder,
  }) {
    return _client.rpc('save_badge', params: {
      'p_org': orgId,
      'p_id': id,
      'p_name': name,
      'p_description': description,
      'p_icon': icon,
      'p_color': color,
      'p_rule_type': ruleType,
      'p_threshold': threshold,
      'p_param': param,
      'p_duration_days': durationDays,
      'p_is_active': isActive,
      'p_sort_order': sortOrder,
    });
  }

  Future<void> deleteBadge(String orgId, String id) => _client.rpc('delete_badge', params: {'p_org': orgId, 'p_id': id});

  Future<void> awardBadge(String badgeId, String studentId, {bool revoke = false}) =>
      _client.rpc('award_badge', params: {'p_badge': badgeId, 'p_student': studentId, 'p_revoke': revoke});

  Future<int> awardToCircle(String badgeId, String circleId) async =>
      (await _client.rpc('award_badge_to_circle', params: {'p_badge': badgeId, 'p_circle': circleId}) as num).toInt();

  Future<List<BadgeHolder>> badgeHolders(String orgId, String badgeId) async => [
        for (final h in _list(await _client.rpc('badge_holders', params: {'p_org': orgId, 'p_badge': badgeId})))
          BadgeHolder(
            studentId: h['student_id'] as String,
            name: h['student_name'] as String,
            code: (h['student_code'] as String?) ?? '',
            awardedAt: h['awarded_at'] as String,
            expiresAt: h['expires_at'] as String?,
            manual: h['manual'] as bool? ?? false,
          ),
      ];

  Future<void> evaluateAll(String orgId) => _client.rpc('evaluate_org_badges', params: {'p_org': orgId});

  Future<Map<String, String>> gradeLabels(String orgId) async {
    final rows = await _client.from('recitation_grades').select('key, label').eq('organization_id', orgId).order('sort_order');
    return {for (final r in rows as List) r['key'] as String: r['label'] as String};
  }

  Future<List<({String id, String name})>> students(String orgId) async {
    final rows = await _client.from('students_profile').select('id, full_name').eq('organization_id', orgId).order('full_name');
    return [for (final r in rows as List) (id: r['id'] as String, name: r['full_name'] as String)];
  }

  Future<List<({String id, String name})>> circles(String orgId) async {
    final rows = await _client.from('circles').select('id, name').eq('organization_id', orgId).order('name');
    return [for (final r in rows as List) (id: r['id'] as String, name: r['name'] as String)];
  }

  // ---- leaderboard & challenges ---------------------------------------------

  Future<Leaderboard> leaderboard(String orgId) async {
    final j = _map(await _client.rpc('get_circle_leaderboard', params: {'p_org': orgId, 'p_circle': null}));
    return Leaderboard(
      enabled: j['enabled'] as bool? ?? false,
      circleName: j['circle_name'] as String?,
      rows: [
        for (final r in _list(j['rows']))
          LeaderRow(rank: (r['rank'] as num).toInt(), name: r['name'] as String, points: (r['points'] as num).toInt(), isMe: r['is_me'] as bool? ?? false),
      ],
    );
  }

  Future<List<Challenge>> challenges(String orgId) async =>
      [for (final c in _list(await _client.rpc('list_challenges', params: {'p_org': orgId}))) Challenge.fromJson(c)];

  Future<ChallengeBoard> challengeBoard(String orgId, String id) async {
    final j = _map(await _client.rpc('challenge_board', params: {'p_org': orgId, 'p_challenge': id}));
    return ChallengeBoard(
      challenge: Challenge.fromJson(j),
      rows: [
        for (final r in _list(j['rows']))
          ChallengeRow(
            rank: (r['rank'] as num).toInt(),
            circleName: r['circle_name'] as String,
            students: (r['students'] as num).toInt(),
            total: r['total'] as num,
            average: r['average'] as num,
            mine: r['mine'] as bool? ?? false,
          ),
      ],
    );
  }

  Future<void> saveChallenge(String orgId, {String? id, required String title, String? description, required String metric, required DateTime starts, required DateTime ends}) {
    String d(DateTime x) => '${x.year.toString().padLeft(4, '0')}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    return _client.rpc('admin_save_challenge', params: {
      'p_org': orgId,
      'p_id': id,
      'p_title': title,
      'p_description': description,
      'p_metric': metric,
      'p_starts': d(starts),
      'p_ends': d(ends),
    });
  }

  Future<void> deleteChallenge(String orgId, String id) => _client.rpc('admin_delete_challenge', params: {'p_org': orgId, 'p_id': id});
}
