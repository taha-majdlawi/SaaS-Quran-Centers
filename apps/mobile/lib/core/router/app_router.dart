import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../tenant/tenant_controller.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/tenant/org_picker_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/students/students_list_screen.dart';
import '../../features/students/student_form_screen.dart';
import '../../features/students/student_file_screen.dart';
import '../../features/my_portal/my_portal_screen.dart';
import '../../features/recitation/circle_students_screen.dart';
import '../../features/recitation/lesson_mode_screen.dart';
import '../../features/circles/circles_list_screen.dart';
import '../../features/circles/circle_form_screen.dart';
import '../../features/attendance/attendance_screen.dart';
import '../../features/serd/serd_list_screen.dart';
import '../../features/serd/serd_entry_screen.dart';
import '../../features/serd/serd_report_screen.dart';
import '../../features/serd/serd_schedule_screen.dart';
import '../../features/serd/serd_settings_screen.dart';
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
import '../../features/calendar/calendar_list_screen.dart';
import '../../features/calendar/event_form_screen.dart';
import '../../features/calendar/event_detail_screen.dart';
import '../../features/calendar/calendar_types_screen.dart';
import '../offline/sync_screen.dart';
import '../../features/privacy/privacy_screens.dart';
import '../../features/auth/join_screen.dart';
import '../../features/certificates/certificates_screens.dart';
import '../../features/reports/reports_screens.dart';
import '../../features/quran/quran_screens.dart';
import '../../features/comms/announcements_screens.dart';
import '../../features/comms/chat_screens.dart';
import '../../features/comms/notification_prefs_screen.dart';
import '../../features/gatherings/external_recitations_screen.dart';
import '../../features/gatherings/gathering_detail_screen.dart';
import '../../features/gatherings/gatherings_screen.dart';
import '../../features/insights/reviews_screen.dart';
import '../../features/insights/search_screen.dart';
import '../../features/comms/notifications_screen.dart';
import '../../features/comms/comms_repository.dart' show Announcement;
import '../../features/my_portal/portal_engagement_screens.dart';
import '../../features/stages/stages_list_screen.dart';
import '../../features/stages/stage_form_screen.dart';
import '../../features/members/members_list_screen.dart';
import '../../features/profiles/circle_profile_screen.dart';
import '../../features/profiles/teacher_profile_screen.dart';
import '../../features/attention/attention_screen.dart';
import '../../features/profiles/weekly_report_screen.dart';
import '../../features/members/member_edit_screen.dart';
import '../../features/members/teacher_form_screen.dart';
import '../../features/audit/audit_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/site/site_screen.dart';
import '../tenant/organization.dart';
import '../../app_shell.dart';
import '../../features/more/more_screen.dart';

/// Deliberately flat for this first pass: every signed-in member (whatever
/// their role) lands in the same /dashboard, /students, ... routes, same as
/// apps/web where role differences are handled INSIDE each page rather than
/// via separate route prefixes per role. Splitting by role can come back
/// once there's more than one role's worth of screens actually built.
GoRouter buildAppRouter({required AuthController auth, required TenantController tenant, required OnboardingGate onboarding}) {
  return GoRouter(
    refreshListenable: Listenable.merge([auth, tenant]),
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final path = state.matchedLocation;

      // Invitation links: the join screen handles sign-in / sign-up itself
      if (path == '/join') return null;

      if (!auth.isAuthenticated) {
        // The animated intro plays once per install, before the very first login.
        if (!onboarding.seen) {
          return path == '/onboarding' ? null : '/onboarding';
        }
        return path == '/login' ? null : '/login';
      }
      if (path == '/onboarding') return '/dashboard';

      // Nothing is built until the first membership load finishes, so no screen
      // ever renders without an active center.
      if (tenant.loading || !tenant.loaded) return path == '/splash' ? null : '/splash';

      if (tenant.active == null) {
        return path == '/select-organization' ? null : '/select-organization';
      }

      // "تبديل المركز" in AppDrawer navigates here deliberately even with an
      // active org already set, so only bounce away from /login.
      if (path == '/login' || path == '/splash') {
        return '/dashboard';
      }

      // Students/guardians never see the staff screens - same boundary as
      // apps/web's (staff) route group. RLS already blocks the data; this
      // just sends them straight to their own portal instead of a staff
      // screen that would render empty for them.
      final role = tenant.active!.role;
      final isPortalOnly = role == OrgRole.student || role == OrgRole.guardian;
      // Portal users may also open the calendar and one entry of it (register /
      // cancel); new/edit/types are admin screens and stay closed to them.
      final segments = Uri.parse(path).pathSegments;
      final calendarOk = segments.isNotEmpty &&
          segments.first == 'calendar' &&
          (segments.length == 1 || (segments.length == 2 && segments[1] != 'new' && segments[1] != 'types'));
      final portalOk = path == '/chat' || path == '/chat/new' || (segments.length == 2 && segments.first == 'chat') ||
          path == '/announcements' || path == '/notifications' || path == '/notifications/prefs' || path == '/quran' || (segments.length == 2 && segments.first == 'quran');
      if (isPortalOnly && path != '/my' && !path.startsWith('/my/') && !calendarOk && !portalOk) {
        return '/my';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => OnboardingScreen(gate: onboarding)),
      GoRoute(path: '/select-organization', builder: (context, state) => const OrgPickerScreen()),
      // the staff tabs (bottom bar); every other screen opens on top of them
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/students', builder: (context, state) => const StudentsListScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/serd', builder: (context, state) => const SerdListScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/chat', builder: (context, state) => const ChatListScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/more', builder: (context, state) => const MoreScreen())]),
        ],
      ),
      GoRoute(path: '/my', builder: (context, state) => const MyPortalScreen()),
      GoRoute(path: '/sync', builder: (context, state) => const SyncScreen()),
      GoRoute(path: '/deletion-requests', builder: (context, state) => const DeletionRequestsScreen()),
      GoRoute(path: '/my/privacy', builder: (context, state) => const MyPrivacyScreen()),
      GoRoute(path: '/join', builder: (context, state) => JoinScreen(token: state.uri.queryParameters['token'])),
      GoRoute(path: '/reports', builder: (context, state) => const ReportsScreen()),
      GoRoute(path: '/students/:id/report', builder: (context, state) => StudentReportScreen(studentId: state.pathParameters['id']!)),
      GoRoute(path: '/certificates', builder: (context, state) => const CertificatesScreen()),
      GoRoute(path: '/certificates/:id', builder: (context, state) => CertificateScreen(certificateId: state.pathParameters['id']!)),
      GoRoute(path: '/my/report', builder: (context, state) => const StudentReportScreen(portal: true)),
      GoRoute(path: '/my/certificates', builder: (context, state) => const CertificatesScreen(portal: true)),
      GoRoute(path: '/my/certificates/:id', builder: (context, state) => CertificateScreen(certificateId: state.pathParameters['id']!)),
      GoRoute(path: '/quran', builder: (context, state) => const QuranScreen()),
      GoRoute(
        path: '/quran/:surah',
        builder: (context, state) => SurahReaderScreen(
          surah: int.tryParse(state.pathParameters['surah'] ?? '') ?? 1,
          startAyah: int.tryParse(state.uri.queryParameters['ayah'] ?? ''),
        ),
      ),
      GoRoute(path: '/my/market', builder: (context, state) => const PortalMarketScreen()),
      GoRoute(path: '/my/badges', builder: (context, state) => const PortalBadgesScreen()),
      GoRoute(
        path: '/circle/:id',
        builder: (context, state) => CircleStudentsScreen(circleId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/circle/:id/lesson',
        builder: (context, state) => LessonModeScreen(circleId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/students/new', builder: (context, state) => const StudentFormScreen()),
      GoRoute(
        path: '/students/:id/file',
        builder: (context, state) => StudentFileScreen(studentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/students/:id',
        builder: (context, state) => StudentFormScreen(studentId: state.pathParameters['id']),
      ),
      GoRoute(path: '/circles', builder: (context, state) => const CirclesListScreen()),
      GoRoute(path: '/circles/:id/profile', builder: (context, state) => CircleProfileScreen(circleId: state.pathParameters['id']!)),
      GoRoute(path: '/attention', builder: (context, state) => const AttentionScreen()),
      GoRoute(path: '/weekly/:id', builder: (context, state) => WeeklyReportScreen(studentId: state.pathParameters['id']!)),
      GoRoute(path: '/teachers/:id', builder: (context, state) => TeacherProfileScreen(teacherId: state.pathParameters['id']!)),
      GoRoute(path: '/circles/new', builder: (context, state) => const CircleFormScreen()),
      GoRoute(
        path: '/circles/:id',
        builder: (context, state) => CircleFormScreen(circleId: state.pathParameters['id']),
      ),
      GoRoute(path: '/attendance', builder: (context, state) => const AttendanceScreen()),
      GoRoute(
        path: '/serd/new',
        builder: (context, state) => SerdEntryScreen(sessionId: state.uri.queryParameters['session']),
      ),
      GoRoute(path: '/serd/schedule', builder: (context, state) => const SerdScheduleScreen()),
      GoRoute(path: '/serd/settings', builder: (context, state) => const SerdSettingsScreen()),
      GoRoute(path: '/serd/report', builder: (context, state) => const SerdReportScreen()),
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
        builder: (context, state) => AnnouncementFormScreen(announcement: state.extra as Announcement?),
      ),
      GoRoute(path: '/calendar', builder: (context, state) => const CalendarListScreen()),
      GoRoute(
        path: '/calendar/new',
        builder: (context, state) => EventFormScreen(initialDate: state.uri.queryParameters['date']),
      ),
      GoRoute(path: '/calendar/types', builder: (context, state) => const CalendarTypesScreen()),
      GoRoute(
        path: '/calendar/:id/edit',
        builder: (context, state) => EventFormScreen(entryId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/calendar/:id',
        builder: (context, state) => EventDetailScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
      GoRoute(path: '/gatherings', builder: (context, state) => const GatheringsScreen()),
      GoRoute(path: '/gatherings/:id', builder: (context, state) => GatheringDetailScreen(gatheringId: state.pathParameters['id']!)),
      GoRoute(path: '/external-recitations', builder: (context, state) => const ExternalRecitationsScreen()),
      GoRoute(path: '/reviews', builder: (context, state) => const ReviewsScreen()),
      GoRoute(path: '/search', builder: (context, state) => const GlobalSearchScreen()),
      GoRoute(path: '/notifications/prefs', builder: (context, state) => const NotificationPrefsScreen()),
      GoRoute(path: '/chat/new', builder: (context, state) => const NewChatScreen()),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatThreadScreen(otherId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/stages', builder: (context, state) => const StagesListScreen()),
      GoRoute(path: '/stages/new', builder: (context, state) => const StageFormScreen()),
      GoRoute(
        path: '/stages/:id',
        builder: (context, state) => StageFormScreen(stageId: state.pathParameters['id']),
      ),
      GoRoute(path: '/members', builder: (context, state) => const MembersListScreen()),
      GoRoute(path: '/members/new-teacher', builder: (context, state) => const TeacherFormScreen()),
      GoRoute(
        path: '/members/:id',
        builder: (context, state) => MemberEditScreen(memberId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/audit', builder: (context, state) => const AuditScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(path: '/site', builder: (context, state) => const SiteScreen()),
    ],
  );
}
