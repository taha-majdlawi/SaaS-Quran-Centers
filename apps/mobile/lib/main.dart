import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/supabase/supabase_client.dart';
import 'core/tenant/tenant_controller.dart';
import 'core/tenant/tenant_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppSupabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(const BustanAlQuranApp());
}

class BustanAlQuranApp extends StatelessWidget {
  const BustanAlQuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TenantController(TenantRepository(AppSupabase.client))..loadMemberships(),
      child: Builder(
        builder: (context) {
          final tenant = context.watch<TenantController>();
          final router = buildAppRouter(tenant: tenant);
          return MaterialApp.router(
            title: 'بستان القرآن',
            routerConfig: router,
          );
        },
      ),
    );
  }
}
