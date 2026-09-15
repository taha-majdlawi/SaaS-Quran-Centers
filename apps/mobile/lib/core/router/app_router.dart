import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../tenant/tenant_controller.dart';
import '../../features/auth/login_screen.dart';
import '../../features/tenant/org_picker_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/students/students_list_screen.dart';
import '../../features/students/student_form_screen.dart';
import '../../features/my_portal/my_portal_screen.dart';
import '../../features/circles/circles_list_screen.dart';
import '../../features/circles/circle_form_screen.dart';
import '../../features/attendance/attendance_screen.dart';
import '../tenant/organization.dart';

/// Deliberately flat for this first pass: every signed-in member (whatever
/// their role) lands in the same /dashboard, /students, ... routes, same as
/// apps/web where role differences are handled INSIDE each page rather than
/// via separate route prefixes per role. Splitting by role can come back
/// once there's more than one role's worth of screens actually built.
GoRouter buildAppRouter({required AuthController auth, required TenantController tenant}) {
  return GoRouter(
    refreshListenable: Listenable.merge([auth, tenant]),
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final path = state.matchedLocation;

      if (!auth.isAuthenticated) {
        return path == '/login' ? null : '/login';
      }

      if (tenant.loading) return null;

      if (tenant.active == null) {
        return path == '/select-organization' ? null : '/select-organization';
      }

      // "تبديل المركز" in AppDrawer navigates here deliberately even with an
      // active org already set, so only bounce away from /login.
      if (path == '/login') {
        return '/dashboard';
      }

      // Students/guardians never see the staff screens - same boundary as
      // apps/web's (staff) route group. RLS already blocks the data; this
      // just sends them straight to their own portal instead of a staff
      // screen that would render empty for them.
      final role = tenant.active!.role;
      final isPortalOnly = role == OrgRole.student || role == OrgRole.guardian;
      if (isPortalOnly && path != '/my') {
        return '/my';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/select-organization', builder: (context, state) => const OrgPickerScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/my', builder: (context, state) => const MyPortalScreen()),
      GoRoute(path: '/students', builder: (context, state) => const StudentsListScreen()),
      GoRoute(path: '/students/new', builder: (context, state) => const StudentFormScreen()),
      GoRoute(
        path: '/students/:id',
        builder: (context, state) => StudentFormScreen(studentId: state.pathParameters['id']),
      ),
      GoRoute(path: '/circles', builder: (context, state) => const CirclesListScreen()),
      GoRoute(path: '/circles/new', builder: (context, state) => const CircleFormScreen()),
      GoRoute(
        path: '/circles/:id',
        builder: (context, state) => CircleFormScreen(circleId: state.pathParameters['id']),
      ),
      GoRoute(path: '/attendance', builder: (context, state) => const AttendanceScreen()),
    ],
  );
}
