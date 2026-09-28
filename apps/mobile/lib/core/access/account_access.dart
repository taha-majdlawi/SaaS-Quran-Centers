import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart';
import '../i18n/i18n.dart';
import '../offline/sync_screen.dart';
import '../offline/sync_service.dart';

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
  bool _billingLock = false;
  String? _userId;
  String? _orgId;
  SupabaseClient? _client;
  bool _observing = false;

  bool get isReadOnly => _readOnly;

  /// Read-only because the center's subscription lapsed, not because of the account.
  bool get isBillingLock => _billingLock;

  /// The sentence to show for the current lock.
  /// What a locked account reads at every attempt (strings.banners): it says what
  /// the account IS, not that a check failed. In the viewer's language.
  String get lockMessage => _billingLock ? currentStrings.banners.billingLock : currentStrings.banners.viewer;

  /// Staff-only heads-up from the center's plan (0067): subscription ending
  /// soon / in grace, or students / teachers nearly at the plan's limit.
  /// Empty for students and guardians (the server sends no usage to them).
  List<({String text, bool urgent})> planWarnings = const [];

  /// Messages from the platform owner (maintenance, updates), shown to everyone.
  List<({String title, String? body, String level})> notices = const [];

  String get _key => 'access_ro:$_userId:$_orgId';
  String get _billingKey => 'access_bl:$_userId:$_orgId';

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
      _set(false, billing: false);
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _set(prefs.getBool(_key) ?? false, billing: prefs.getBool(_billingKey) ?? false);
    } catch (_) {}
    await refresh();
  }

  Future<void> refresh() async {
    final client = _client;
    if (client == null || _userId == null || _orgId == null) return;
    try {
      final data = await client.rpc('my_access', params: {'p_org': _orgId});
      final map = data as Map<String, dynamic>;
      final ro = map['is_read_only'] == true;
      final billing = ro && map['reason'] == 'billing';
      _set(ro, billing: billing);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, ro);
      await prefs.setBool(_billingKey, billing);
      final warnings = planWarningsFrom(map);
      if (warnings.length != planWarnings.length || warnings.any((w) => !planWarnings.contains(w))) {
        planWarnings = warnings;
        notifyListeners();
      }
    } catch (_) {
      // offline / old server: keep the last known answer
    }
    try {
      final data = await client.rpc('active_platform_notices') as List;
      final next = [
        for (final n in data) (title: (n as Map<String, dynamic>)['title'] as String, body: n['body'] as String?, level: n['level'] as String),
      ];
      if (next.length != notices.length || next.any((n) => !notices.contains(n))) {
        notices = next;
        notifyListeners();
      }
    } catch (_) {}
  }

  void _set(bool value, {required bool billing}) {
    if (_readOnly == value && _billingLock == billing) return;
    _readOnly = value;
    _billingLock = billing;
    notifyListeners();
  }

  /// Throws the sentence a viewer should read. Call BEFORE the offline queue.
  void ensureCanWrite() {
    if (_readOnly) throw StateError(lockMessage);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }
}

String _count(int n, Map<String, String> forms) => n == 1 ? forms['one']! : (n == 2 ? forms['two']! : fmt(forms['many']!, {'n': n}));

/// Same rules as the web banner (apps/web/src/lib/billing/format.ts): only for
/// staff (usage present), only while the platform enforces billing.
List<({String text, bool urgent})> planWarningsFrom(Map<String, dynamic> access) {
  final usage = access['usage'];
  if (usage is! Map) return const [];
  final t = currentStrings.plan;
  final out = <({String text, bool urgent})>[];
  final b = access['billing'];
  if (b is Map && b['enforced'] == true && b['locked'] != true) {
    final trial = b['kind'] == 'trial';
    final days = (b['days_left'] as num?)?.toInt();
    if (b['state'] == 'grace') {
      out.add((text: trial ? t.graceTrial : t.gracePaid, urgent: true));
    } else if ((b['state'] == 'trial' || b['state'] == 'active') && days != null && days <= 7) {
      out.add((text: fmt(trial ? t.soonTrial : t.soonPaid, {'days': _count(days, t.days)}), urgent: days <= 3));
    }
  }
  final sl = (usage['students_left'] as num?)?.toInt();
  if (sl != null && sl <= 5) {
    out.add((text: sl == 0 ? fmt(t.studentsFull, {'max': usage['max_students']}) : fmt(t.studentsLeft, {'n': _count(sl, t.students)}), urgent: sl == 0));
  }
  final tl = (usage['teachers_left'] as num?)?.toInt();
  if (tl != null && tl <= 1) {
    out.add((text: tl == 0 ? fmt(t.teachersFull, {'max': usage['max_teachers']}) : t.oneTeacherLeft, urgent: tl == 0));
  }
  return out;
}

/// The strip(s) under the status bar: "viewing account" and/or "waiting to
/// upload". Mounted once in MaterialApp.builder rather than in every shell.
class StatusBanners extends StatelessWidget {
  const StatusBanners({super.key, required this.onSyncTap});

  final VoidCallback onSyncTap;

  static bool isVisible(BuildContext context) {
    if (!context.watch<AuthController>().isAuthenticated) return false;
    final sync = context.watch<SyncService>();
    final access = context.watch<AccessController>();
    return access.isReadOnly || access.notices.isNotEmpty || access.planWarnings.isNotEmpty || sync.pendingCount + sync.failedCount > 0 || sync.usingCache;
  }

  @override
  Widget build(BuildContext context) {
    if (!isVisible(context)) return const SizedBox.shrink();
    final access = context.watch<AccessController>();
    final viewer = access.isReadOnly;
    final sync = context.watch<SyncService>();
    final syncShown = sync.pendingCount + sync.failedCount > 0 || sync.usingCache;
    final notices = context.watch<AccessController>().notices;
    Color noticeColor(String level) => level == 'critical' ? Colors.red.shade700 : (level == 'warning' ? Colors.orange.shade800 : Colors.blue.shade700);
    final top = notices.isNotEmpty ? noticeColor(notices.first.level) : access.planWarnings.isNotEmpty ? (access.planWarnings.first.urgent ? Colors.red.shade700 : Colors.orange.shade800) : (viewer ? (access.isBillingLock ? Colors.red.shade700 : Colors.amber.shade800) : (sync.failedCount > 0 ? Colors.red.shade700 : Colors.orange.shade800));

    return ColoredBox(
      color: top,
      child: SafeArea(
        bottom: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final n in notices)
            Material(
              color: noticeColor(n.level),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(children: [
                  const Icon(Icons.campaign_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${n.title}${n.body == null ? '' : ' — ${n.body}'}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
          for (final w in access.planWarnings)
            Material(
              color: w.urgent ? Colors.red.shade700 : Colors.orange.shade800,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(w.text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                ]),
              ),
            ),
          if (viewer)
            Material(
              color: access.isBillingLock ? Colors.red.shade700 : Colors.amber.shade800,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(children: [
                  Icon(access.isBillingLock ? Icons.lock_clock_rounded : Icons.visibility_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(access.lockMessage, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                ]),
              ),
            ),
          if (syncShown) SyncStrip(onTap: onSyncTap),
        ]),
      ),
    );
  }
}
