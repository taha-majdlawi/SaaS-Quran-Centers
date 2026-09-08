import 'package:go_router/go_router.dart';

import '../tenant/organization.dart';
import '../tenant/tenant_controller.dart';

/// Route guard mirrors eqraa_app's role-prefix redirect
/// (lib/core/router/app_router.dart there), extended with an organization
/// gate: a signed-in user with zero active memberships is sent to
/// /select-organization before any role-scoped route is reachable.
GoRouter buildAppRouter({required TenantController tenant}) {
  return GoRouter(
    refreshListenable: tenant,
    initialLocation: '/',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      final selectingOrg = state.matchedLocation == '/select-organization';

      // TODO: wire real auth-session check (mirrors eqraa_app's approach of
      // caching role/session in SharedPreferences after Supabase sign-in).
      final isAuthenticated = true;
      if (!isAuthenticated) return loggingIn ? null : '/login';

      if (tenant.active == null && !selectingOrg) return '/select-organization';

      final active = tenant.active;
      if (active != null) {
        final path = state.matchedLocation;
        final rolePrefix = switch (active.role) {
          OrgRole.student => '/student',
          OrgRole.teacher => '/teacher',
          OrgRole.admin => '/admin',
          OrgRole.guardian => '/guardian',
        };
        final onForeignRolePrefix = ['/student', '/teacher', '/admin', '/guardian']
            .where((p) => p != rolePrefix)
            .any(path.startsWith);
        if (onForeignRolePrefix) return rolePrefix;
      }

      return null;
    },
    routes: [
      // Feature route builders are registered here, one per lib/features/*
      // module - see apps/mobile/README.md for the porting checklist.
    ],
  );
}
