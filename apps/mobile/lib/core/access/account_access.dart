import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../offline/sync_screen.dart';
import '../offline/sync_service.dart';

/// What a viewing account reads at every attempt: it says what the account IS,
/// not that a check failed (a "no permission" message invites a second try).
const kViewerMessage = 'هذا حساب عرض — البيانات للاطّلاع فقط';

/// Is the signed-in person a viewing (read-only) account in the active center?
///
/// The database refuses every write of such an account (a trigger under all
/// write paths), so this flag only drives the banner and lets us refuse BEFORE
/// a write enters the offline queue - a refusal at sync time would arrive
/// minutes after the tap and strand a record the teacher believes is saved.
///
/// The last answer is cached so the banner and guard are right on a cold start
/// without signal; a network failure never flips it (a teacher in a building
/// with no reception must not be told their account is a viewing account).
class AccessController extends ChangeNotifier with WidgetsBindingObserver {
  AccessController._();
  static final AccessController instance = AccessController._();

  bool _readOnly = false;
  String? _userId;
  String? _orgId;
  SupabaseClient? _client;
  bool _observing = false;

  bool get isReadOnly => _readOnly;

  String get _key => 'access_ro:$_userId:$_orgId';

  Future<void> bind(SupabaseClient client, String? orgId) async {
    _client = client;
    final user = client.auth.currentUser?.id;
    if (user == _userId && orgId == _orgId) return;
    _userId = user;
    _orgId = orgId;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    if (user == null || orgId == null) {
      _set(false);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _set(prefs.getBool(_key) ?? false);
    } catch (_) {}
    await refresh();
  }

  Future<void> refresh() async {
    final client = _client;
    if (client == null || _userId == null || _orgId == null) return;
    try {
      final data = await client.rpc('my_access', params: {'p_org': _orgId});
      final ro = (data as Map<String, dynamic>)['is_read_only'] == true;
      _set(ro);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, ro);
    } catch (_) {
      // offline / old server: keep the last known answer
    }
  }

  void _set(bool value) {
    if (_readOnly == value) return;
    _readOnly = value;
    notifyListeners();
  }

  /// Throws the sentence a viewer should read. Call BEFORE the offline queue.
  void ensureCanWrite() {
    if (_readOnly) throw StateError(kViewerMessage);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }
}

/// The strip(s) under the status bar: "viewing account" and/or "waiting to
/// upload". Mounted once in MaterialApp.builder rather than in every shell.
class StatusBanners extends StatelessWidget {
  const StatusBanners({super.key, required this.onSyncTap});

  final VoidCallback onSyncTap;

  static bool isVisible(BuildContext context) {
    if (!context.watch<AuthController>().isAuthenticated) return false;
    final sync = context.watch<SyncService>();
    return context.watch<AccessController>().isReadOnly || sync.pendingCount + sync.failedCount > 0 || sync.usingCache;
  }

  @override
  Widget build(BuildContext context) {
    if (!isVisible(context)) return const SizedBox.shrink();
    final viewer = context.watch<AccessController>().isReadOnly;
    final sync = context.watch<SyncService>();
    final syncShown = sync.pendingCount + sync.failedCount > 0 || sync.usingCache;
    final top = viewer ? Colors.amber.shade800 : (sync.failedCount > 0 ? Colors.red.shade700 : Colors.orange.shade800);

    return ColoredBox(
      color: top,
      child: SafeArea(
        bottom: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (viewer)
            Material(
              color: Colors.amber.shade800,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(children: [
                  Icon(Icons.visibility_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text(kViewerMessage, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                ]),
              ),
            ),
          if (syncShown) SyncStrip(onTap: onSyncTap),
        ]),
      ),
    );
  }
}
