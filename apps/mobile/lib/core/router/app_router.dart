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
import '../../features/serd/serd_list_screen.dart';
import '../../features/serd/serd_form_screen.dart';
import '../../features/points/points_screen.dart';
import '../../features/badges/badges_screen.dart';
import '../../features/badges/badge_form_screen.dart';
import '../../features/market/market_screen.dart';
import '../../features/market/market_item_form_screen.dart';
import '../../features/circle_challenges/circle_challenges_list_screen.dart';
import '../../features/circle_challenges/challenge_form_screen.dart';
import '../../features/circle_challenges/challenge_detail_screen.dart';
import '../../features/activities/activities_list_screen.dart';
import '../../features/activities/activity_form_screen.dart';
import '../../features/announcements/announcements_list_screen.dart';
import '../../features/announcements/announcement_form_screen.dart';
import '../../features/calendar/calendar_list_screen.dart';
import '../../features/calendar/event_form_screen.dart';
import '../../features/calendar/event_detail_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/new_chat_screen.dart';
import '../../features/chat/chat_thread_screen.dart';
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
      GoRoute(path: '/serd', builder: (context, state) => const SerdListScreen()),
      GoRoute(path: '/serd/new', builder: (context, state) => const SerdFormScreen()),
      GoRoute(
        path: '/serd/:id',
        builder: (context, state) => SerdFormScreen(sessionId: state.pathParameters['id']),
      ),
      GoRoute(path: '/points', builder: (context, state) => const PointsScreen()),
      GoRoute(path: '/badges', builder: (context, state) => const BadgesScreen()),
      GoRoute(path: '/badges/new', builder: (context, state) => const BadgeFormScreen()),
      GoRoute(
        path: '/badges/:id',
        builder: (context, state) => BadgeFormScreen(badgeId: state.pathParameters['id']),
      ),
      GoRoute(path: '/market', builder: (context, state) => const MarketScreen()),
      GoRoute(path: '/market/new', builder: (context, state) => const MarketItemFormScreen()),
      GoRoute(
        path: '/market/:id',
        builder: (context, state) => MarketItemFormScreen(itemId: state.pathParameters['id']),
      ),
      GoRoute(path: '/circle-challenges', builder: (context, state) => const CircleChallengesListScreen()),
      GoRoute(path: '/circle-challenges/new', builder: (context, state) => const ChallengeFormScreen()),
      GoRoute(
        path: '/circle-challenges/:id',
        builder: (context, state) => ChallengeDetailScreen(challengeId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/activities', builder: (context, state) => const ActivitiesListScreen()),
      GoRoute(path: '/activities/new', builder: (context, state) => const ActivityFormScreen()),
      GoRoute(
        path: '/activities/:id',
        builder: (context, state) => ActivityFormScreen(activityId: state.pathParameters['id']),
      ),
      GoRoute(path: '/announcements', builder: (context, state) => const AnnouncementsListScreen()),
      GoRoute(path: '/announcements/new', builder: (context, state) => const AnnouncementFormScreen()),
      GoRoute(
        path: '/announcements/:id',
        builder: (context, state) => AnnouncementFormScreen(announcementId: state.pathParameters['id']),
      ),
      GoRoute(path: '/calendar', builder: (context, state) => const CalendarListScreen()),
      GoRoute(path: '/calendar/new', builder: (context, state) => const EventFormScreen()),
      GoRoute(
        path: '/calendar/:id',
        builder: (context, state) => EventDetailScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/chat', builder: (context, state) => const ChatListScreen()),
      GoRoute(path: '/chat/new', builder: (context, state) => const NewChatScreen()),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatThreadScreen(threadId: state.pathParameters['id']!),
      ),
    ],
  );
}
