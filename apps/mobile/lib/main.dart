import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/auth/auth_controller.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_client.dart';
import 'core/tenant/tenant_controller.dart';
import 'core/tenant/tenant_repository.dart';
import 'core/theme/app_theme.dart';

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

  runApp(const BustanAlQuranApp());
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
  const BustanAlQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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

    final router = buildAppRouter(auth: auth, tenant: tenant);
    return MaterialApp.router(
      title: 'بستان القرآن',
      theme: buildAppTheme(tenant.active?.organization),
      routerConfig: router,
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    );
  }
}
