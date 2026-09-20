import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/auth/auth_controller.dart';
import 'core/offline/offline_setup.dart';
import 'core/offline/sync_screen.dart';
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

  // Offline layer: queued writes + cached reads for the teacher's daily work.
  final sync = createSyncService(AppSupabase.client);
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

    return MaterialApp.router(
      title: 'بستان القرآن',
      theme: buildAppTheme(parseBrandColor(tenant.active?.organization.primaryColor)),
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      locale: const Locale('ar'),
      builder: (context, child) {
        final sync = context.watch<SyncService>();
        final bannerShown = auth.isAuthenticated && (sync.pendingCount + sync.failedCount > 0 || sync.usingCache);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(children: [
            if (auth.isAuthenticated) SyncBanner(onTap: () => _router.push('/sync')),
            Expanded(
              // the banner (when shown) already sits under the status bar
              child: MediaQuery.removePadding(
                context: context,
                removeTop: bannerShown,
                child: child!,
              ),
            ),
          ]),
        );
      },
    );
  }
}
