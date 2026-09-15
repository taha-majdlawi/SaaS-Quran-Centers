import 'package:supabase_flutter/supabase_flutter.dart';

class MarketItemSummary {
  const MarketItemSummary({
    required this.id,
    required this.name,
    required this.cost,
    required this.isActive,
    this.stock,
  });

  final String id;
  final String name;
  final int cost;
  final bool isActive;
  final int? stock;
}

class MarketStudentOption {
  const MarketStudentOption({required this.id, required this.fullName, required this.balance});
  final String id;
  final String fullName;
  final int balance;
}

class InsufficientBalanceException implements Exception {
  const InsufficientBalanceException();
}

/// Mirrors apps/web's market/actions.ts - a per-org item catalog, purchases
/// that debit student_wallets, and manual balance adjustments.
class MarketRepository {
  MarketRepository(this._client);

  final SupabaseClient _client;

  Future<List<MarketItemSummary>> fetchItems(String organizationId) async {
    final rows = await _client
        .from('market_items')
        .select('id, name, cost, stock, is_active')
        .eq('organization_id', organizationId)
        .order('name');
    return (rows as List)
        .map((r) => MarketItemSummary(
              id: r['id'] as String,
              name: r['name'] as String,
              cost: r['cost'] as int,
              isActive: r['is_active'] as bool,
              stock: r['stock'] as int?,
            ))
        .toList();
  }

  Future<List<MarketStudentOption>> fetchActiveStudentsWithBalance(String organizationId) async {
    final results = await Future.wait([
      _client
          .from('students_profile')
          .select('id, full_name')
          .eq('organization_id', organizationId)
          .eq('status', 'active')
          .order('full_name'),
      _client.from('student_wallets').select('student_id, balance').eq('organization_id', organizationId),
    ]);
    final students = results[0] as List;
    final wallets = results[1] as List;
    final balanceByStudent = {for (final w in wallets) w['student_id'] as String: w['balance'] as int};
    return students
        .map((s) => MarketStudentOption(
              id: s['id'] as String,
              fullName: s['full_name'] as String,
              balance: balanceByStudent[s['id']] ?? 0,
            ))
        .toList();
  }

  Future<MarketItemSummary?> fetchItem(String id) async {
    final row = await _client
        .from('market_items')
        .select('id, name, cost, stock, is_active')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return MarketItemSummary(
      id: row['id'] as String,
      name: row['name'] as String,
      cost: row['cost'] as int,
      isActive: row['is_active'] as bool,
      stock: row['stock'] as int?,
    );
  }

  Future<void> createItem({required String organizationId, required String name, required int cost, int? stock}) {
    return _client.from('market_items').insert({
      'organization_id': organizationId,
      'name': name,
      'cost': cost,
      'stock': stock,
    });
  }

  Future<void> updateItem({
    required String id,
    required String name,
    required int cost,
    required bool isActive,
    int? stock,
  }) {
    return _client.from('market_items').update({
      'name': name,
      'cost': cost,
      'stock': stock,
      'is_active': isActive,
    }).eq('id', id);
  }

  Future<void> deleteItem(String id) {
    return _client.from('market_items').delete().eq('id', id);
  }

  Future<void> recordPurchase({required String organizationId, required String studentId, required String itemId}) async {
    final item = await _client.from('market_items').select('cost').eq('id', itemId).maybeSingle();
    if (item == null) throw Exception('العنصر غير موجود');
    final cost = item['cost'] as int;

    final wallet = await _client.from('student_wallets').select('balance').eq('student_id', studentId).maybeSingle();
    final balance = (wallet?['balance'] as int?) ?? 0;
    if (balance < cost) throw const InsufficientBalanceException();

    await _client.from('market_purchases').insert({
      'organization_id': organizationId,
      'student_id': studentId,
      'item_id': itemId,
      'cost': cost,
      'status': 'fulfilled',
    });

    await _client.from('student_wallets').upsert({
      'student_id': studentId,
      'organization_id': organizationId,
      'balance': balance - cost,
    });
  }

  Future<void> adjustPoints({required String organizationId, required String studentId, required int amount}) async {
    final wallet = await _client.from('student_wallets').select('balance').eq('student_id', studentId).maybeSingle();
    final newBalance = ((wallet?['balance'] as int?) ?? 0) + amount;
    await _client.from('student_wallets').upsert({
      'student_id': studentId,
      'organization_id': organizationId,
      'balance': newBalance,
    });
  }
}
