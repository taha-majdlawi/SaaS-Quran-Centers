import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// One write that could not reach the server yet (a recitation, an attendance
/// sheet, a serd grading). It carries everything needed to replay it: the
/// server calls are idempotent (client_ref / upsert), so a replay after a
/// half-received response never duplicates anything.
class OutboxItem {
  OutboxItem({
    required this.id,
    required this.userId,
    required this.kind,
    required this.payload,
    required this.label,
    required this.createdAt,
    this.orderKey,
    this.status = 'pending',
    this.error,
    this.attempts = 0,
  });

  final int id;

  /// Only the account that recorded it may replay it (a teacher must never
  /// upload another teacher's queue after a sign-in on the same phone).
  final String userId;
  final String kind;
  final Map<String, dynamic> payload;

  /// Human description shown in the sync center.
  final String label;
  final DateTime createdAt;

  /// Items with the same key must reach the server in order (e.g. two attendance
  /// marks for one student on one day: the later one wins).
  final String? orderKey;

  /// 'pending' (will retry) or 'failed' (the server refused it - needs a human).
  String status;
  String? error;
  int attempts;

  Map<String, Object?> toRow() => {
        'user_id': userId,
        'kind': kind,
        'payload': jsonEncode(payload),
        'label': label,
        'created_at': createdAt.toIso8601String(),
        'order_key': orderKey,
        'status': status,
        'error': error,
        'attempts': attempts,
      };

  static OutboxItem fromRow(Map<String, Object?> r) => OutboxItem(
        id: r['id'] as int,
        userId: r['user_id'] as String,
        kind: r['kind'] as String,
        payload: jsonDecode(r['payload'] as String) as Map<String, dynamic>,
        label: r['label'] as String,
        createdAt: DateTime.parse(r['created_at'] as String),
        orderKey: r['order_key'] as String?,
        status: r['status'] as String,
        error: r['error'] as String?,
        attempts: r['attempts'] as int,
      );
}

/// Persistent storage for the outbox and the read cache.
abstract class OfflineStore {
  Future<List<OutboxItem>> items();
  Future<OutboxItem> add(OutboxItem item);
  Future<void> update(OutboxItem item);
  Future<void> remove(int id);

  Future<String?> readCache(String key);
  Future<void> writeCache(String key, String json);
}

/// sqflite-backed store (one small database on the phone).
class SqliteOfflineStore implements OfflineStore {
  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    final path = p.join(await getDatabasesPath(), 'bustan_offline.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          create table outbox (
            id integer primary key autoincrement,
            user_id text not null, kind text not null, payload text not null, label text not null,
            created_at text not null, order_key text, status text not null default 'pending',
            error text, attempts integer not null default 0
          )''');
        await db.execute('create table read_cache (key text primary key, json text not null, updated_at text not null)');
      },
    );
    return _db = db;
  }

  @override
  Future<List<OutboxItem>> items() async {
    final rows = await (await _database).query('outbox', orderBy: 'id asc');
    return rows.map(OutboxItem.fromRow).toList();
  }

  @override
  Future<OutboxItem> add(OutboxItem item) async {
    final id = await (await _database).insert('outbox', item.toRow());
    return OutboxItem(
      id: id,
      userId: item.userId,
      kind: item.kind,
      payload: item.payload,
      label: item.label,
      createdAt: item.createdAt,
      orderKey: item.orderKey,
    );
  }

  @override
  Future<void> update(OutboxItem item) async => (await _database).update('outbox', item.toRow(), where: 'id = ?', whereArgs: [item.id]);

  @override
  Future<void> remove(int id) async => (await _database).delete('outbox', where: 'id = ?', whereArgs: [id]);

  @override
  Future<String?> readCache(String key) async {
    final rows = await (await _database).query('read_cache', where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['json'] as String;
  }

  @override
  Future<void> writeCache(String key, String json) async => (await _database).insert(
        'read_cache',
        {'key': key, 'json': json, 'updated_at': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
}

/// In-memory store for tests.
class MemoryOfflineStore implements OfflineStore {
  final _items = <OutboxItem>[];
  final _cache = <String, String>{};
  var _next = 1;

  @override
  Future<List<OutboxItem>> items() async => List.of(_items);

  @override
  Future<OutboxItem> add(OutboxItem item) async {
    final saved = OutboxItem(
      id: _next++,
      userId: item.userId,
      kind: item.kind,
      payload: item.payload,
      label: item.label,
      createdAt: item.createdAt,
      orderKey: item.orderKey,
    );
    _items.add(saved);
    return saved;
  }

  @override
  Future<void> update(OutboxItem item) async {}

  @override
  Future<void> remove(int id) async => _items.removeWhere((i) => i.id == id);

  @override
  Future<String?> readCache(String key) async => _cache[key];

  @override
  Future<void> writeCache(String key, String json) async => _cache[key] = json;
}
