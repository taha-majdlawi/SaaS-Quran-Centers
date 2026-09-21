import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/access/account_access.dart';
import 'core/push/push_service.dart';
import 'core/auth/auth_controller.dart';
import 'core/offline/offline_setup.dart';
import 'core/offline/sync_service.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'core/tenant/tenant_controller.dart';
import 'core/tenant/tenant_repository.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Both are compile-time --dart-define values (see .vscode/launch.json or
  // README.md) - not build-time secrets, this is the same publishable/anon
  // key already shipped in the web app's client bundle. Missing them used
  // to crash cryptically deep inside Supabase.initialize; show a screen
  // that actually explains the fix instead.
  if (_supabaseUrl.isEmpty || _supabasePublishableKey.isEmpty) {
    runApp(const _MissingConfigApp());
    return;
  }

  await AppSupabase.initialize(url: _supabaseUrl, publishableKey: _supabasePublishableKey);

  // Push notifications (Firebase): a no-op when this build has no Firebase config file.
  await PushService.instance.init();

  // Offline layer: queued writes + cached reads for the teacher's daily work.
  final sync = createSyncService(AppSupabase.client);
  // a viewing account is refused BEFORE a write can enter the offline queue
  SyncService.writeGuard = AccessController.instance.ensureCanWrite;
  await sync.start();

  runApp(BustanAlQuranApp(sync: sync));
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.settings_suggest, size: 48, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'إعدادات الاتصال بالخادم مفقودة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'شغّل التطبيق عبر ملف .vscode/launch.json الجاهز، أو راجع README.md '
                  'لمعرفة قيمتي --dart-define=SUPABASE_URL و --dart-define=SUPABASE_PUBLISHABLE_KEY.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BustanAlQuranApp extends StatelessWidget {
  const BustanAlQuranApp({super.key, required this.sync});

  final SyncService sync;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sync),
        ChangeNotifierProvider.value(value: AccessController.instance),
        ChangeNotifierProvider(create: (_) => AuthController(AppSupabase.client)),
        ChangeNotifierProvider(create: (_) => TenantController(TenantRepository(AppSupabase.client))),
      ],
      child: const _AppRouterHost(),
    );
  }
}

/// Loads the signed-in user's organizations the moment they authenticate,
/// and clears them on sign-out - the router's redirect logic depends on
/// `tenant.active` being up to date with the CURRENT auth state.
class _AppRouterHost extends StatefulWidget {
  const _AppRouterHost();

  @override
  State<_AppRouterHost> createState() => _AppRouterHostState();
}

class _AppRouterHostState extends State<_AppRouterHost> {
  bool _wasAuthenticated = false;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Built once - the router listens to auth/tenant itself (refreshListenable),
    // rebuilding it on every state change would reset the user's navigation.
    _router = buildAppRouter(auth: context.read<AuthController>(), tenant: context.read<TenantController>());
    // a tapped push opens the right screen (also when it launched the app)
    PushService.instance.openRoute = (route) => _router.push(route);
    WidgetsBinding.instance.addPostFrameCallback((_) => PushService.instance.flushPending());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final tenant = context.watch<TenantController>();

    if (auth.isAuthenticated && !_wasAuthenticated) {
      _wasAuthenticated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => tenant.loadMemberships());
    } else if (!auth.isAuthenticated && _wasAuthenticated) {
      _wasAuthenticated = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => tenant.clear());
    }

    // who am I in THIS center (viewing account?) - re-read when the center or account changes
    final accessOrg = auth.isAuthenticated ? tenant.active?.organization.id : null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessController.instance.bind(AppSupabase.client, accessOrg);
      if (accessOrg != null) PushService.instance.register(AppSupabase.client, accessOrg);
    });

    return MaterialApp.router(
      title: 'بستان القرآن',
      theme: buildAppTheme(parseBrandColor(tenant.active?.organization.primaryColor)),
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      locale: const Locale('ar'),
      builder: (context, child) {
        final bannerShown = StatusBanners.isVisible(context);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(children: [
            StatusBanners(onSyncTap: () => _router.push('/sync')),
            Expanded(
              // the banners (when shown) already sit under the status bar
              child: MediaQuery.removePadding(context: context, removeTop: bannerShown, child: child!),
            ),
          ]),
        );
      },
    );
  }
}
