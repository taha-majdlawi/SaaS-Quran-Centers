import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/garden.dart';
import '../../core/widgets/org_avatar.dart';
import '../../core/widgets/ui.dart';
import '../../core/auth/auth_controller.dart';
import '../recitation/recitation_repository.dart';
import '../teacher/teacher_home_screen.dart';
import 'admin_insights_section.dart';
import 'attention_section.dart';
import '../../core/i18n/i18n.dart';
import '../../core/offline/sync_service.dart';

Map<OrgRole, String> get _roleGreeting => {
      OrgRole.admin: currentStrings.dash.centerAdmin,
      OrgRole.teacher: currentStrings.labels.roles['teacher']!,
      OrgRole.guardian: currentStrings.labels.roles['guardian']!,
      OrgRole.student: currentStrings.labels.roles['student']!,
    };

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<_DashboardStats>? _statsFuture;
  Future<TeacherToday>? _circlesFuture;
  String? _loadedForOrgId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }
  }

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _statsFuture = _loadStats(orgId);
    final membership = context.read<TenantController>().active;
    final userId = context.read<AuthController>().currentUser?.id;
    if (membership != null && userId != null && membership.hasModule('students')) {
      _circlesFuture = RecitationRepository(AppSupabase.client).fetchTeacherToday(orgId);
    }
  }

  Future<_DashboardStats> _loadStats(String orgId) async {
    final client = AppSupabase.client;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Future<int> count(String key, Future<dynamic> Function() fetch) =>
        SyncService.instance.cached<int>('dash-count:$key:$orgId', fetch, (j) => (j as num).toInt());
    final results = await Future.wait([
      count('students', () => client.from('students_profile').count().eq('organization_id', orgId)),
      count('teachers', () => client.from('organization_members').count().eq('organization_id', orgId).eq('role', 'teacher')),
      count('circles', () => client.from('circles').count().eq('organization_id', orgId)),
      count('present:$today', () => client.from('attendance').count().eq('organization_id', orgId).eq('session_date', today).eq('status', 'present')),
    ]);
    return _DashboardStats(students: results[0], teachers: results[1], circles: results[2], presentToday: results[3]);
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final membership = tenant.active;
    // teachers get the eqraa-style home (circles with their rosters); admins keep the management dashboard
    if (membership?.role == OrgRole.teacher) return const TeacherHomeScreen();

    final org = membership?.organization;
    final isAdmin = membership?.role == OrgRole.admin;

    final t = tr(context);
    final quickActions = <({IconData icon, String label, String path, Color color})>[
      if (tenant.hasModule('attendance')) (icon: Icons.fact_check_rounded, label: t.dash.takeAttendance, path: '/attendance', color: const Color(0xFF16835A)),
      if (tenant.hasModule('students')) (icon: Icons.person_add_alt_1_rounded, label: t.dash.addStudent, path: '/students/new', color: const Color(0xFF1877C9)),
      if (tenant.hasModule('serd')) (icon: Icons.menu_book_rounded, label: t.dash.serdSession, path: '/serd/new', color: const Color(0xFFB26A00)),
      if (tenant.hasModule('announcements')) (icon: Icons.campaign_rounded, label: t.dash.newAnnouncement, path: '/announcements/new', color: const Color(0xFF6D4AA8)),
      if (tenant.hasModule('calendar')) (icon: Icons.calendar_month_rounded, label: t.dash.calendar, path: '/calendar', color: const Color(0xFFC0392B)),
      if (tenant.hasModule('reports')) (icon: Icons.insights_rounded, label: t.nav.items['/reports']!, path: '/reports', color: const Color(0xFF0E7C86)),
    ];

    return Scaffold(
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_loadedForOrgId != null) setState(() => _reload(_loadedForOrgId!));
          await _statsFuture;
        },
        child: FutureBuilder<_DashboardStats>(
          future: _statsFuture,
          builder: (context, snap) {
            final stats = snap.data;
            return ListView(padding: EdgeInsets.zero, children: [
              GardenHeader(
                leading: Row(mainAxisSize: MainAxisSize.min, children: [const DrawerMenuButton(), if (org != null) OrgAvatar(name: org.name, logoUrl: org.logoUrl, brandColor: org.primaryColor, size: 34, onDark: true)]),
                greeting: '${timeGreeting()} · ${_roleGreeting[membership?.role] ?? ''}',
                title: org?.name ?? '',
                subtitle: longToday(context),
                actions: [
                  const SyncButton(),
                  IconButton(tooltip: t.nav.items['/search'], onPressed: () => context.push('/search'), icon: const Icon(Icons.search_rounded, color: Colors.white)),
                ],
                stats: stats == null
                    ? const []
                    : [
                        if (tenant.hasModule('students')) HeaderStat('${stats.students}', t.dash.students, icon: Icons.people_alt_rounded),
                        if (isAdmin) HeaderStat('${stats.teachers}', t.dash.teachers, icon: Icons.school_rounded),
                        if (tenant.hasModule('circles')) HeaderStat('${stats.circles}', t.dash.circles, icon: Icons.groups_rounded),
                        if (tenant.hasModule('attendance')) HeaderStat('${stats.presentToday}', t.dash.todayAttendance, icon: Icons.how_to_reg_rounded),
                      ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (snap.hasError) ErrorState(onRetry: () => setState(() => _reload(_loadedForOrgId!))),
                  if (quickActions.isNotEmpty)
                    GardenGrid(children: [
                      for (final a in quickActions) GardenTile(icon: a.icon, label: a.label, color: a.color, onTap: () => context.push(a.path)),
                    ]),
                  if (isAdmin && org != null) AttentionSection(orgId: org.id),
                  if (isAdmin && org != null) AdminInsightsSection(orgId: org.id),
                  if (_circlesFuture != null)
                    GardenSection(
                      title: t.dash.yourCirclesToday,
                      icon: Icons.groups_rounded,
                      child: FutureBuilder<TeacherToday>(
                        future: _circlesFuture,
                        builder: (context, snap) {
                          final today = snap.data;
                          if (snap.hasError) return ErrorState(onRetry: () => setState(() => _reload(_loadedForOrgId!)));
                          if (today == null) return const SkeletonCards(count: 2, height: 90);
                          if (today.circles.isEmpty) return Padding(padding: const EdgeInsets.all(8), child: Text(t.dash.noCircle));
                          return Column(children: [
                            if (!today.isWorkingDay)
                              Padding(padding: const EdgeInsets.only(bottom: 10), child: MessageBanner(message: t.dash.notWorkingDay, isError: false)),
                            for (final c in today.circles) _CircleTodayCard(circle: c),
                          ]);
                        },
                      ),
                    ),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

/// A circle today on the admin's home: how many recited (ring), who is here.
class _CircleTodayCard extends StatelessWidget {
  const _CircleTodayCard({required this.circle});

  final TodayCircle circle;

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final c = circle;
    final ratio = c.students == 0 ? 0.0 : c.recited / c.students;
    return GardenCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => context.push('/circle/${c.id}'),
      child: Row(children: [
        GardenRing(
          value: ratio,
          size: 52,
          center: Text('${c.recited}/${c.students}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              GardenChip(fmt(t.dash.presentN, {'present': c.present}), color: const Color(0xFF16835A), icon: Icons.check_circle_rounded),
              if (c.absent > 0) GardenChip(fmt(t.dash.absentN, {'absent': c.absent}), color: const Color(0xFFC0392B), icon: Icons.cancel_rounded),
            ]),
          ]),
        ),
        Icon(forwardChevron(context), color: Colors.grey.shade400),
      ]),
    );
  }
}

class _DashboardStats {
  const _DashboardStats({
    required this.students,
    required this.teachers,
    required this.circles,
    required this.presentToday,
  });

  final int students;
  final int teachers;
  final int circles;
  final int presentToday;
}
