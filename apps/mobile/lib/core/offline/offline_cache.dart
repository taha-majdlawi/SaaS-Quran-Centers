import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// A generic key -> JSON-serializable-value cache backed by sqflite, for
/// screens that want "show the last known data immediately if the live
/// fetch fails" instead of a bare error/spinner with no connection. This is
/// deliberately a read-through fallback, not offline writes/sync/conflict
/// resolution - a screen calls [put] after a successful live fetch and
/// [get] only when that fetch throws (see dashboard_screen.dart for the
/// reference usage). Every table this app reads is already scoped by RLS
/// to the caller, so caching a JSON blob locally per cache key carries the
/// same exposure as the live query already did - nothing extra to guard.
class OfflineCache {
  OfflineCache._();

  static Database? _db;

  static Future<Database> _database() async {
    final existing = _db;
    if (existing != null) return existing;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'offline_cache.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) => db.execute(
        'CREATE TABLE cached_reads (cache_key TEXT PRIMARY KEY, payload TEXT NOT NULL, cached_at TEXT NOT NULL)',
      ),
    );
    _db = db;
    return db;
  }

  /// [value] must be JSON-encodable (a Map/List of primitives) - encoding
  /// happens here, not left to the caller, so every cache entry stays in
  /// the same shape regardless of which screen wrote it.
  static Future<void> put(String key, Object value) async {
    final db = await _database();
    await db.insert(
      'cached_reads',
      {'cache_key': key, 'payload': jsonEncode(value), 'cached_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Null if nothing was ever cached under [key] - the caller decides what
  /// that means (usually: let the original error propagate).
  static Future<dynamic> get(String key) async {
    final db = await _database();
    final rows = await db.query('cached_reads', columns: ['payload'], where: 'cache_key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['payload'] as String);
  }
}
