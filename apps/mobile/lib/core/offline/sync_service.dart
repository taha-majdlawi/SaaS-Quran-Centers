import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'outbox.dart';
import '../../core/i18n/i18n.dart';

/// Was this failure "no usable network" (retry later) rather than a refusal by
/// the server (a rule the user has to see)?
bool isNetworkError(Object e) {
  if (e is PostgrestException || e is AuthException) {
    // supabase wraps a few transport problems; a real refusal has a code
    return e is AuthRetryableFetchException;
  }
  if (e is SocketException || e is TimeoutException || e is HandshakeException) return true;
  final name = e.runtimeType.toString();
  return name.contains('ClientException') || name.contains('Retryable') || name.contains('Socket');
}

/// Shown when a save was kept on the phone because there is no connection.
String get kQueuedMessage => currentStrings.ui.savedOffline;

/// What the recitation sheet returns when everything it saved is still waiting on the phone.
const kQueuedPoints = -1;

/// Runs one queued write against the server.
typedef OutboxHandler = Future<dynamic> Function(Map<String, dynamic> payload);

class SubmitOutcome {
  const SubmitOutcome({required this.queued, this.data});

  /// True when it could not reach the server and was stored on the phone.
  final bool queued;

  /// The server's answer when it was sent right away.
  final dynamic data;
}

/// The offline layer for teacher work: writes are sent immediately when
/// possible and otherwise wait in the outbox and are uploaded, in order, when
/// the connection returns. Reads that were served from the cache raise
/// [usingCache] so the UI can say so.
class SyncService extends ChangeNotifier with WidgetsBindingObserver {
  SyncService(this._store, {String? Function()? currentUser, Stream<dynamic>? connectivity})
      : _currentUser = currentUser ?? (() => null),
        _connectivity = connectivity;

  /// The app-wide instance (repositories are not widgets, so they reach it here).
  static late SyncService instance;

  /// Runs before anything is sent or queued; throws to refuse (e.g. a viewing account).
  static void Function()? writeGuard;

  final OfflineStore _store;
  final String? Function() _currentUser;
  final Stream<dynamic>? _connectivity;
  final Map<String, OutboxHandler> _handlers = {};

  List<OutboxItem> _items = [];
  bool _flushing = false;
  bool _usingCache = false;
  DateTime? _lastSync;
  StreamSubscription<dynamic>? _connectivitySub;
  Timer? _timer;

  List<OutboxItem> get items => List.unmodifiable(_items);
  List<OutboxItem> get mine => _items.where((i) => i.userId == _currentUser()).toList();
  int get pendingCount => mine.where((i) => i.status == 'pending').length;
  int get failedCount => mine.where((i) => i.status == 'failed').length;
  bool get flushing => _flushing;
  bool get usingCache => _usingCache;
  DateTime? get lastSync => _lastSync;

  void register(String kind, OutboxHandler handler) => _handlers[kind] = handler;

  Future<void> start() async {
    _items = await _store.items();
    notifyListeners();
    WidgetsBinding.instance.addObserver(this);
    _connectivitySub = (_connectivity ?? Connectivity().onConnectivityChanged).listen((_) => flush());
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => flush());
    unawaited(flush());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(flush());
  }

  bool _hasPendingWithKey(String? key, String user) =>
      key != null && _items.any((i) => i.userId == user && i.orderKey == key && i.status == 'pending');

  /// Sends [payload] through [kind]'s handler now, or queues it when there is no
  /// network. A refusal from the server is thrown to the caller (it must show
  /// the user why), never queued.
  Future<SubmitOutcome> submit(
    String kind,
    Map<String, dynamic> payload, {
    required String label,
    String? orderKey,
    Future<dynamic> Function()? send,
  }) async {
    writeGuard?.call();
    final user = _currentUser();
    if (user == null) throw StateError('not signed in');
    final handler = _handlers[kind];

    // Something older for the same thing is still waiting: stay behind it.
    if (_hasPendingWithKey(orderKey, user)) return _enqueue(user, kind, payload, label, orderKey);

    try {
      final data = send != null ? await send() : await handler!(payload);
      _usingCache = false;
      notifyListeners();
      return SubmitOutcome(queued: false, data: data);
    } catch (e) {
      if (isNetworkError(e)) return _enqueue(user, kind, payload, label, orderKey);
      rethrow;
    }
  }

  Future<SubmitOutcome> _enqueue(String user, String kind, Map<String, dynamic> payload, String label, String? orderKey) async {
    final saved = await _store.add(OutboxItem(
      id: 0,
      userId: user,
      kind: kind,
      payload: payload,
      label: label,
      createdAt: DateTime.now(),
      orderKey: orderKey,
    ));
    _items = [..._items, saved];
    notifyListeners();
    return const SubmitOutcome(queued: true);
  }

  /// Uploads this account's pending items, oldest first. Stops at the first
  /// network failure; marks an item failed when the server refuses it.
  Future<void> flush() async {
    if (_flushing) return;
    final user = _currentUser();
    if (user == null) return;
    _flushing = true;
    notifyListeners();
    try {
      for (final item in _items.where((i) => i.userId == user && i.status == 'pending').toList()) {
        final handler = _handlers[item.kind];
        if (handler == null) continue;
        item.attempts++;
        try {
          await handler(item.payload);
          await _store.remove(item.id);
          _items.removeWhere((i) => i.id == item.id);
          _lastSync = DateTime.now();
        } catch (e) {
          if (isNetworkError(e)) {
            await _store.update(item);
            break;
          }
          item.status = 'failed';
          item.error = e is PostgrestException ? e.message : e.toString();
          await _store.update(item);
        }
        notifyListeners();
      }
    } finally {
      _flushing = false;
      notifyListeners();
    }
  }

  Future<void> retry(OutboxItem item) async {
    item.status = 'pending';
    item.error = null;
    await _store.update(item);
    notifyListeners();
    await flush();
  }

  Future<void> discard(OutboxItem item) async {
    await _store.remove(item.id);
    _items.removeWhere((i) => i.id == item.id);
    notifyListeners();
  }

  // ---- read cache ------------------------------------------------------------------

  /// Fetches JSON-able data from the network and remembers it; when the network
  /// is down, serves the last copy (and raises [usingCache]). Throws only when
  /// there is neither.
  Future<T> cached<T>(String key, Future<dynamic> Function() fetch, T Function(dynamic json) parse) async {
    final user = _currentUser() ?? '';
    final k = '$user|$key';
    try {
      final data = await fetch();
      await _store.writeCache(k, jsonEncode(data));
      if (_usingCache) {
        _usingCache = false;
        notifyListeners();
      }
      return parse(data);
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      final saved = await _store.readCache(k);
      if (saved == null) rethrow;
      if (!_usingCache) {
        _usingCache = true;
        notifyListeners();
      }
      return parse(jsonDecode(saved));
    }
  }

  // ---- what is waiting, for screens that show live state ------------------------

  /// Recitations of [studentId] that are queued for today (so the circle list
  /// can already show them as done).
  int pendingRecitationsToday(String studentId) {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return mine.where((i) => i.kind == 'log_recitation' && i.status == 'pending' && i.payload['p_student_id'] == studentId).where((i) {
      final at = i.payload['p_recorded_at'] as String?;
      return at == null || DateTime.parse(at).toLocal().toIso8601String().startsWith(today);
    }).length;
  }

  /// The status of a queued attendance mark for [studentId] on [date], if any.
  String? pendingAttendance(String studentId, String date) {
    String? found;
    for (final i in mine.where((i) => i.kind == 'attendance' && i.status == 'pending')) {
      for (final r in (i.payload['rows'] as List)) {
        if (r['student_id'] == studentId && r['session_date'] == date) found = r['status'] as String;
      }
    }
    return found;
  }
}
