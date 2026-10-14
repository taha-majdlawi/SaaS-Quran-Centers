import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'encrypted_store.dart';
import 'outbox.dart';
import '../monitoring/error_reporter.dart';
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
  SyncService(
    this._store, {
    String? Function()? currentUser,
    Stream<dynamic>? connectivity,
    this.readTimeout = const Duration(seconds: 12),
    Future<void> Function()? probe,
    this.probeEvery = const Duration(seconds: 15),
  })  : _currentUser = currentUser ?? (() => null),
        _connectivity = connectivity,
        _probe = probe;

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
  Timer? _probeTimer;

  /// A tiny request that succeeds only when the server can really be reached
  /// (being on a Wi-Fi is not the same as having internet).
  final Future<void> Function()? _probe;

  /// How often an unreachable server is tried again.
  final Duration probeEvery;

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
    // keep the phone's copy lean: what nobody opened for 45 days goes
    try {
      await _store.pruneCache(const Duration(days: 45));
    } catch (_) {}
    notifyListeners();
    WidgetsBinding.instance.addObserver(this);
    _connectivitySub = (_connectivity ?? Connectivity().onConnectivityChanged).listen((r) {
      _setNetwork(_hasNetwork(r));
      unawaited(checkReachable().then((_) => flush()));
    });
    if (_connectivity == null) {
      try {
        _setNetwork(_hasNetwork(await Connectivity().checkConnectivity()));
      } catch (_) {}
    }
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => flush());
    // opening the app: find out at once whether the server answers, then upload
    unawaited(checkReachable().then((_) => flush()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _timer?.cancel();
    _probeTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(checkReachable().then((_) => flush()));
  }

  static bool _hasNetwork(dynamic result) {
    final list = result is List ? result : [result];
    return list.any((r) => r != ConnectivityResult.none);
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
    ErrorReporter.instance.crumb('save $kind');
    final user = _currentUser();
    if (user == null) throw StateError('not signed in');
    final handler = _handlers[kind];

    // Something older for the same thing is still waiting: stay behind it.
    if (_hasPendingWithKey(orderKey, user)) return _enqueue(user, kind, payload, label, orderKey);

    // no way through right now: keep it on the phone at once, no waiting
    if (!online) return _enqueue(user, kind, payload, label, orderKey);

    try {
      final data = await (send != null ? send() : handler!(payload)).timeout(readTimeout);
      _markCache(false);
      _setReachable(true);
      return SubmitOutcome(queued: false, data: data);
    } catch (e) {
      if (isNetworkError(e)) {
        _setReachable(false);
        return _enqueue(user, kind, payload, label, orderKey);
      }
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
    if (_flushing || !online) return;
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
          _setReachable(true);
          await _store.remove(item.id);
          _items.removeWhere((i) => i.id == item.id);
          _lastSync = DateTime.now();
        } catch (e) {
          if (isNetworkError(e)) {
            await _store.update(item);
            _setReachable(false);
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
    // nothing left to send: it can only be discarded
    if (item.error == EncryptedOfflineStore.unreadable && item.payload.isEmpty) return;
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

  /// How long a read (or an immediate send) may take before the saved copy is
  /// used / the write is queued instead - a weak signal should not freeze a screen.
  final Duration readTimeout;

  bool _network = true;
  bool _reachable = true;

  /// False while the phone has no network, or has one that does not reach the
  /// server (a Wi-Fi without internet, a captive portal). Reads then go
  /// straight to the saved copy and writes straight to the queue.
  bool get online => _network && _reachable;

  /// The phone has a network but the server does not answer through it.
  bool get unreachable => _network && !_reachable;

  /// What the phone reports about its network (also called by tests).
  void reportConnectivity(bool value) => _setNetwork(value);

  void _setNetwork(bool value) {
    if (_network == value) return;
    ErrorReporter.instance.crumb(value ? 'network on' : 'network off');
    final was = online;
    _network = value;
    // a new network: assume it works until a request says otherwise
    if (value) _reachable = true;
    _changed(was);
  }

  void _setReachable(bool value) {
    // without a way to ask the server again, never get stuck on "unreachable"
    if (_reachable == value || (!value && _probe == null)) return;
    final was = online;
    _reachable = value;
    _probeTimer?.cancel();
    _probeTimer = null;
    // keep knocking until the server answers again
    if (!value && _probe != null) _probeTimer = Timer.periodic(probeEvery, (_) => checkReachable());
    _changed(was);
  }

  void _changed(bool was) {
    notifyListeners();
    if (online && !was) unawaited(flush());
  }

  bool _probing = false;

  /// Asks the server a tiny question to learn whether it can really be reached.
  Future<bool> checkReachable() async {
    final probe = _probe;
    if (probe == null || !_network) return online;
    if (_probing) return online;
    _probing = true;
    try {
      await probe().timeout(const Duration(seconds: 6));
      _setReachable(true);
    } catch (e) {
      if (isNetworkError(e)) _setReachable(false);
    } finally {
      _probing = false;
    }
    return online;
  }

  /// Fetches JSON-able data from the network and remembers it; when the network
  /// is down (or too slow), serves the last copy and raises [usingCache].
  /// Throws only when there is neither.
  Future<T> cached<T>(String key, Future<dynamic> Function() fetch, T Function(dynamic json) parse) async {
    final user = _currentUser() ?? '';
    final k = '$user|$key';
    if (!online) {
      final saved = await _store.readCache(k);
      if (saved != null) {
        _markCache(true);
        return parse(jsonDecode(saved));
      }
      // nothing saved yet: still try the network (the connectivity report can lag)
    }
    try {
      final data = await fetch().timeout(readTimeout);
      await _store.writeCache(k, jsonEncode(data));
      _markCache(false);
      _setReachable(true);
      return parse(data);
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      if (_network) _setReachable(false);
      final saved = await _store.readCache(k);
      if (saved == null) rethrow;
      _markCache(true);
      return parse(jsonDecode(saved));
    }
  }

  /// [cached] for data that is used as it comes (maps / lists straight from the server).
  Future<dynamic> raw(String key, Future<dynamic> Function() fetch) => cached<dynamic>(key, fetch, (j) => j);

  /// The saved copy of [key] without touching the network (null when there is none).
  Future<dynamic> peek(String key) async {
    final saved = await _store.readCache('${_currentUser() ?? ''}|$key');
    return saved == null ? null : jsonDecode(saved);
  }

  /// Saves [data] as the copy of [key] (used when a local change should show before the next sync).
  Future<void> remember(String key, dynamic data) => _store.writeCache('${_currentUser() ?? ''}|$key', jsonEncode(data));

  void _markCache(bool value) {
    if (_usingCache == value) return;
    _usingCache = value;
    notifyListeners();
  }

  // ---- what is waiting, for screens that show live state ------------------------

  /// This account's queued (not yet uploaded) writes of [kind], oldest first, so
  /// screens can already show them.
  List<OutboxItem> pendingOf(String kind) => mine.where((i) => i.kind == kind && i.status == 'pending').toList();

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
