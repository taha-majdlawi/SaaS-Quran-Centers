import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/i18n/i18n.dart';

/// System-tray messages while the app is closed or in the background are shown by Android
/// itself (the server sends a "notification" message); this only has to exist and be top-level.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

/// Where a tapped push should lead: chats open the chat list, everything else the inbox.
String routeForPush(Map<String, dynamic> data) {
  if (data['kind'] == 'chat') return '/chat';
  final ref = '${data['ref_id'] ?? ''}';
  // the weekly report opens itself; the rest go to the inbox
  if (data['event_key'] == 'weekly_digest' && ref.isNotEmpty) return '/weekly/$ref';
  if ((data['event_key'] == 'fee_payment' || data['event_key'] == 'fee_overdue') && ref.isNotEmpty) return '/fees/$ref';
  return '/notifications';
}

/// Firebase Cloud Messaging on the phone. Completely optional: when the Firebase config is not
/// in the build, [init] quietly turns push off and the rest of the app is unaffected.
/// Android reads `android/app/google-services.json`; iOS takes the same project's values as
/// build variables (codemagic.yaml: FIREBASE_IOS_*), so no file has to be added to Xcode.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  static const _channelId = 'bustan_default';

  /// The iOS app of the Firebase project, from --dart-define (null = push off on iOS).
  static FirebaseOptions? get _iosOptions {
    const apiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
    const sender = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const project = String.fromEnvironment('FIREBASE_PROJECT_ID');
    if (apiKey.isEmpty || appId.isEmpty || sender.isEmpty || project.isEmpty) return null;
    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: sender,
      projectId: project,
      iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: 'com.bustanalquran.bustanAlquranApp'),
    );
  }

  /// device_tokens.platform
  static String get _platform => Platform.isIOS ? 'ios' : 'android';

  final _local = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _token;
  String? _registeredFor;
  StreamSubscription<String>? _refreshSub;

  /// Set by the app once the router exists; a tap that arrives earlier waits in [_pending].
  void Function(String route)? openRoute;
  String? _pending;

  bool get isReady => _ready;

  /// Whether the phone currently lets this app show notifications (for the preferences screen).
  Future<bool> notificationsAllowed() async {
    if (!_ready) return false;
    try {
      final s = await FirebaseMessaging.instance.getNotificationSettings();
      return s.authorizationStatus != AuthorizationStatus.denied;
    } catch (_) {
      return true;
    }
  }

  void _open(Map<String, dynamic> data) {
    final route = routeForPush(data);
    final handler = openRoute;
    if (handler == null) {
      _pending = route;
    } else {
      handler(route);
    }
  }

  /// Call once the router can navigate: delivers a tap that opened the app from a closed state.
  void flushPending() {
    final route = _pending;
    if (route != null && openRoute != null) {
      _pending = null;
      openRoute!(route);
    }
  }

  Future<void> init() async {
    if (_ready) return;
    try {
      final ios = _iosOptions;
      if (Platform.isIOS && ios == null) throw StateError('no FIREBASE_IOS_* values');
      await Firebase.initializeApp(options: Platform.isIOS ? ios : null);
    } catch (e) {
      debugPrint('Push disabled (no Firebase config in this build): $e');
      return;
    }
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

      await _local.initialize(
        // iOS: Firebase asks for the permission (register), not this plugin
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        ),
        onDidReceiveNotificationResponse: (r) {
          final payload = r.payload;
          if (payload != null && payload.isNotEmpty) _open(Map<String, dynamic>.from(jsonDecode(payload) as Map));
        },
      );
      final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(AndroidNotificationChannel(
        _channelId,
        currentStrings.ui.channelName,
        description: currentStrings.ui.channelDesc,
        importance: Importance.high,
      ));

      // iPhone: the system shows the banner itself while the app is open, too
      if (Platform.isIOS) {
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
      }
      // Android: while the app is open FCM shows nothing by itself: draw the banner ourselves
      FirebaseMessaging.onMessage.listen((m) {
        if (Platform.isIOS) return;
        final n = m.notification;
        if (n == null) return;
        _local.show(
          id: m.hashCode & 0x7fffffff,
          title: n.title,
          body: n.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(_channelId, currentStrings.ui.channelName, importance: Importance.high, priority: Priority.high),
          ),
          payload: jsonEncode(m.data),
        );
      });
      FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data));
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _open(initial.data);
      _ready = true;
    } catch (e) {
      debugPrint('Push init failed: $e');
    }
  }

  /// Ask for permission (Android 13+), get this phone's token and hand it to the server for
  /// the signed-in account. Safe to call again on every center switch.
  Future<void> register(SupabaseClient client, String orgId) async {
    if (!_ready) return;
    final user = client.auth.currentUser?.id;
    if (user == null) return;
    final key = '$user:$orgId';
    if (_registeredFor == key && _token != null) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      _token = token;
      String? version;
      try {
        version = (await PackageInfo.fromPlatform()).version;
      } catch (_) {}
      await client.rpc('register_device_token', params: {'p_org': orgId, 'p_token': token, 'p_platform': _platform, 'p_app_version': version});
      _registeredFor = key;
      _refreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen((fresh) async {
        _token = fresh;
        final u = client.auth.currentUser?.id;
        final o = _registeredFor?.split(':').last;
        if (u != null && o != null) {
          try {
            await client.rpc('register_device_token', params: {'p_org': o, 'p_token': fresh, 'p_platform': _platform});
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  /// On sign-out: stop delivering this account's messages to this phone.
  Future<void> unregister(SupabaseClient client) async {
    final token = _token;
    _registeredFor = null;
    if (!_ready || token == null) return;
    try {
      await client.rpc('unregister_device_token', params: {'p_token': token});
    } catch (_) {}
  }
}
