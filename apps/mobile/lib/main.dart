import 'dart:async';

import 'core/widgets/growing_tree.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/access/account_access.dart';
import 'core/push/push_service.dart';
import 'core/auth/auth_controller.dart';
import 'core/i18n/i18n.dart';
import 'core/monitoring/error_reporter.dart';
import 'core/offline/offline_setup.dart';
import 'core/offline/prefetch.dart';
import 'core/offline/sync_service.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'core/tenant/tenant_controller.dart';
import 'core/tenant/tenant_repository.dart';
import 'features/auth/onboarding_screen.dart';

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

  // every crash goes to the error log with the screen, the device and the last steps
  await ErrorReporter.instance.install();

  // Push notifications (Firebase): a no-op when this build has no Firebase config file.
  await PushService.instance.init();

  // Offline layer: queued writes + cached reads for the teacher's daily work.
  final sync = createSyncService(AppSupabase.client);
  // a viewing account is refused BEFORE a write can enter the offline queue
  SyncService.writeGuard = AccessController.instance.ensureCanWrite;
  await sync.start();

  // Has the animated intro already played on this device?
  final onboarding = await OnboardingGate.load();

  // The app language the person chose on this device (else the center's default).
  await LocaleController.instance.load();
  // day and month names for the dates on the home headers (ar / en)
  try {
    await initializeDateFormatting();
  } catch (_) {}

  runApp(BustanAlQuranApp(sync: sync, onboarding: onboarding));
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
  const BustanAlQuranApp({super.key, required this.sync, required this.onboarding});

  final SyncService sync;
  final OnboardingGate onboarding;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sync),
        ChangeNotifierProvider.value(value: AccessController.instance),
        ChangeNotifierProvider.value(value: LocaleController.instance),
        ChangeNotifierProvider.value(value: OfflinePrefetch.instance),
        ChangeNotifierProvider(create: (_) => AuthController(AppSupabase.client)),
        ChangeNotifierProvider(create: (_) => TenantController(TenantRepository(AppSupabase.client))),
      ],
      child: _AppRouterHost(onboarding: onboarding),
    );
  }
}

/// Loads the signed-in user's organizations the moment they authenticate,
/// and clears them on sign-out - the router's redirect logic depends on
/// `tenant.active` being up to date with the CURRENT auth state.
class _AppRouterHost extends StatefulWidget {
  const _AppRouterHost({required this.onboarding});

  final OnboardingGate onboarding;

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
    _router = buildAppRouter(auth: context.read<AuthController>(), tenant: context.read<TenantController>(), onboarding: widget.onboarding);
    // a tapped push opens the right screen (also when it launched the app)
    PushService.instance.openRoute = (route) => _router.push(route);
    // the screen showing, for crash reports
    _router.routerDelegate.addListener(() {
      try {
        ErrorReporter.instance.screen(_router.routerDelegate.currentConfiguration.uri.path);
      } catch (_) {}
    });
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
      ErrorReporter.instance.orgId = accessOrg;
      ErrorReporter.instance.locale = LocaleController.instance.effective;
      if (accessOrg != null) PushService.instance.register(AppSupabase.client, accessOrg);
      // keep what this person needs on the phone, so the app works without a connection
      OfflinePrefetch.instance.autoRun(AppSupabase.client, () => context.read<AuthController>().isAuthenticated ? context.read<TenantController>().active : null);
      final active = tenant.active;
      if (accessOrg != null && active != null) {
        unawaited(OfflinePrefetch.instance.run(AppSupabase.client, active));
      } else {
        unawaited(OfflinePrefetch.instance.bind(null, null));
      }
      if (accessOrg != null) {
        LocaleController.instance.syncProfile((lang) => AppSupabase.client.rpc('set_my_locale', params: {'p_locale': lang}));
      }
      LocaleController.instance.bindCenter(accessOrg, (orgId) async {
        final row = await AppSupabase.client
            .from('organization_settings')
            .select('value')
            .eq('organization_id', orgId)
            .eq('key', 'default_language')
            .maybeSingle();
        return row?['value'] as String?;
      });
    });

    // The person's choice, else the center's default language, else Arabic.
    final lang = context.watch<LocaleController>().effective;
    final strings = stringsFor(lang);
    currentStrings = strings;

    return MaterialApp.router(
      title: strings.common.appName,
      theme: buildAppTheme(parseBrandColor(tenant.active?.organization.primaryColor)),
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      locale: Locale(lang),
      builder: (context, child) {
        final bannerShown = StatusBanners.isVisible(context);
        return StringsScope(
          strings: strings,
          child: Directionality(
            textDirection: strings.isAr ? TextDirection.rtl : TextDirection.ltr,
            child: Column(children: [
              StatusBanners(onSyncTap: () => _router.push('/sync')),
              Expanded(
                // the banners (when shown) already sit under the status bar
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: bannerShown,
                  // the garden's tree, small and see-through, growing while the app is open
                  child: Stack(fit: StackFit.expand, children: [
                    child!,
                    // not over the mushaf's text
                    ValueListenableBuilder(
                      valueListenable: _router.routeInformationProvider,
                      builder: (context, info, _) =>
                          info.uri.path.startsWith('/quran/') ? const SizedBox.shrink() : const GrowingTreeOverlay(),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}
