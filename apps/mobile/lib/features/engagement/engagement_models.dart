/// Market / badges / challenges value types. Balances, progress and rankings are
/// computed in SQL and arrive ready-made (the same payloads the web reads).
library;

import 'package:flutter/material.dart';

import '../../core/i18n/i18n.dart';

const kRuleLabels = {
  'manual': 'يدوية (يمنحها المشرف)',
  'points_threshold': 'الوصول إلى عدد نقاط',
  'recitations_count': 'عدد التسميعات',
  'grade_count': 'عدد التسميعات بتقدير معيّن',
  'streak_days': 'أيام متتالية بتسميع',
  'weekly_attendance': 'نسبة الحضور الأسبوعية',
  'juz_complete': 'إتمام جزء كامل في السرد',
  'serd_passed_count': 'عدد السرد الناجح',
};

Map<String, String> get kMetricLabels => currentStrings.labels.metric;

Map<String, String> get kChallengeStatus => currentStrings.labels.challengeStatus;
Map<String, String> get kPurchaseLabels => currentStrings.labels.purchase;
const kPurchaseColors = <String, MaterialColor>{'pending': Colors.amber, 'fulfilled': Colors.green, 'cancelled': Colors.grey};

String ruleText(String ruleType, int threshold, String? param, Map<String, String> gradeLabels) {
  final template = currentStrings.labels.rule[ruleType];
  return template == null ? '' : fmt(template, {'n': threshold, 'grade': gradeLabels[param] ?? param ?? ''});
}

String money(num v, String symbol) {
  final s = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  return '$s $symbol';
}

Color hexColor(String? hex, [Color fallback = const Color(0xFFF59E0B)]) {
  if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return fallback;
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

class MarketItem {
  const MarketItem({required this.id, required this.name, required this.price, required this.isActive, this.description, this.imageUrl, this.stock});
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final num price;
  final int? stock;
  final bool isActive;

  factory MarketItem.fromJson(Map<String, dynamic> j) => MarketItem(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        imageUrl: j['image_url'] as String?,
        price: j['price'] as num,
        stock: (j['stock'] as num?)?.toInt(),
        isActive: j['is_active'] as bool? ?? true,
      );
}

class Wallet {
  const Wallet({required this.earnedPoints, required this.pendingPoints, required this.spent, required this.balance});
  final int earnedPoints;
  final int pendingPoints;
  final num spent;
  final num balance;

  factory Wallet.fromJson(Map<String, dynamic> j) => Wallet(
        earnedPoints: (j['earned_points'] as num?)?.toInt() ?? 0,
        pendingPoints: (j['pending_points'] as num?)?.toInt() ?? 0,
        spent: (j['spent'] as num?) ?? 0,
        balance: (j['balance'] as num?) ?? 0,
      );
}

class Purchase {
  const Purchase({required this.id, required this.itemName, required this.spent, required this.status, required this.createdAt, this.studentName, this.studentCode});
  final String id;
  final String itemName;
  final num spent;
  final String status;
  final String createdAt;
  final String? studentName;
  final String? studentCode;

  factory Purchase.fromJson(Map<String, dynamic> j) => Purchase(
        id: j['id'] as String,
        itemName: j['item_name'] as String,
        spent: j['spent'] as num,
        status: j['status'] as String,
        createdAt: j['created_at'] as String,
        studentName: j['student_name'] as String?,
        studentCode: j['student_code'] as String?,
      );
}

class StudentMarket {
  const StudentMarket({required this.enabled, required this.symbol, required this.wallet, required this.items, required this.purchases});
  final bool enabled;
  final String symbol;
  final Wallet wallet;
  final List<MarketItem> items;
  final List<Purchase> purchases;

  factory StudentMarket.fromJson(Map<String, dynamic> j) => StudentMarket(
        enabled: j['enabled'] as bool? ?? false,
        symbol: (j['symbol'] as String?) ?? '',
        wallet: Wallet.fromJson(j['wallet'] as Map<String, dynamic>),
        items: [for (final i in (j['items'] as List)) MarketItem.fromJson(i as Map<String, dynamic>)],
        purchases: [for (final p in (j['purchases'] as List)) Purchase.fromJson(p as Map<String, dynamic>)],
      );
}

class MarketOverview {
  const MarketOverview({
    required this.enabled,
    required this.pointsPerUnit,
    required this.unitValue,
    required this.symbol,
    required this.items,
    required this.purchases,
  });
  final bool enabled;
  final int pointsPerUnit;
  final num unitValue;
  final String symbol;
  final List<MarketItem> items;
  final List<Purchase> purchases;

  factory MarketOverview.fromJson(Map<String, dynamic> j) {
    final c = j['config'] as Map<String, dynamic>;
    return MarketOverview(
      enabled: j['enabled'] as bool? ?? false,
      pointsPerUnit: (c['points_per_unit'] as num).toInt(),
      unitValue: c['unit_value'] as num,
      symbol: c['currency_symbol'] as String,
      items: [for (final i in (j['items'] as List)) MarketItem.fromJson(i as Map<String, dynamic>)],
      purchases: [for (final p in (j['purchases'] as List)) Purchase.fromJson(p as Map<String, dynamic>)],
    );
  }
}

class WalletRow {
  const WalletRow({required this.studentId, required this.name, required this.code, required this.wallet});
  final String studentId;
  final String name;
  final String code;
  final Wallet wallet;
}

class BadgeDef {
  const BadgeDef({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.ruleType,
    required this.threshold,
    required this.isActive,
    required this.sortOrder,
    this.description,
    this.param,
    this.durationDays,
  });
  final String id;
  final String name;
  final String? description;
  final String icon;
  final String colorHex;
  final String ruleType;
  final int threshold;
  final String? param;
  final int? durationDays;
  final bool isActive;
  final int sortOrder;

  Color get color => hexColor(colorHex);

  factory BadgeDef.fromJson(Map<String, dynamic> j) => BadgeDef(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        icon: (j['icon'] as String?) ?? '🏅',
        colorHex: (j['color'] as String?) ?? '#f59e0b',
        ruleType: j['rule_type'] as String,
        threshold: (j['threshold'] as num?)?.toInt() ?? 0,
        param: j['param'] as String?,
        durationDays: (j['duration_days'] as num?)?.toInt(),
        isActive: j['is_active'] as bool? ?? true,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      );
}

class BadgeProgress {
  const BadgeProgress({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.ruleType,
    required this.threshold,
    required this.progress,
    required this.goal,
    required this.earned,
    this.description,
    this.param,
    this.awardedAt,
    this.expiresAt,
  });
  final String id;
  final String name;
  final String? description;
  final String icon;
  final String colorHex;
  final String ruleType;
  final int threshold;
  final String? param;
  final num progress;
  final num goal;
  final bool earned;
  final String? awardedAt;
  final String? expiresAt;

  Color get color => hexColor(colorHex);
  double get fraction => goal > 0 ? (progress / goal).clamp(0, 1).toDouble() : 0;

  factory BadgeProgress.fromJson(Map<String, dynamic> j) => BadgeProgress(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        icon: (j['icon'] as String?) ?? '🏅',
        colorHex: (j['color'] as String?) ?? '#f59e0b',
        ruleType: j['rule_type'] as String,
        threshold: (j['threshold'] as num?)?.toInt() ?? 0,
        param: j['param'] as String?,
        progress: (j['progress'] as num?) ?? 0,
        goal: (j['goal'] as num?) ?? 0,
        earned: j['earned'] as bool? ?? false,
        awardedAt: j['awarded_at'] as String?,
        expiresAt: j['expires_at'] as String?,
      );
}

class BadgeHolder {
  const BadgeHolder({required this.studentId, required this.name, required this.code, required this.awardedAt, required this.manual, this.expiresAt});
  final String studentId;
  final String name;
  final String code;
  final String awardedAt;
  final String? expiresAt;
  final bool manual;
}

class LeaderRow {
  const LeaderRow({required this.rank, required this.name, required this.points, required this.isMe});
  final int rank;
  final String name;
  final int points;
  final bool isMe;
}

class Leaderboard {
  const Leaderboard({required this.enabled, required this.rows, this.circleName});
  final bool enabled;
  final String? circleName;
  final List<LeaderRow> rows;
}

class Challenge {
  const Challenge({required this.id, required this.title, required this.metric, required this.startsOn, required this.endsOn, required this.status, this.description});
  final String id;
  final String title;
  final String? description;
  final String metric;
  final String startsOn;
  final String endsOn;
  final String status;

  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        metric: j['metric'] as String,
        startsOn: j['starts_on'] as String,
        endsOn: j['ends_on'] as String,
        status: (j['status'] as String?) ?? 'active',
      );
}

class ChallengeRow {
  const ChallengeRow({required this.rank, required this.circleName, required this.students, required this.total, required this.average, required this.mine});
  final int rank;
  final String circleName;
  final int students;
  final num total;
  final num average;
  final bool mine;
}

class ChallengeBoard {
  const ChallengeBoard({required this.challenge, required this.rows});
  final Challenge challenge;
  final List<ChallengeRow> rows;
}
