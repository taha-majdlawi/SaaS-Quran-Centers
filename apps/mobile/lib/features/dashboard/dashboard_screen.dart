import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/ui.dart';
import '../../core/auth/auth_controller.dart';
import '../recitation/recitation_repository.dart';

const _roleGreeting = {
  OrgRole.admin: 'مدير المركز',
  OrgRole.teacher: 'معلم',
  OrgRole.guardian: 'ولي أمر',
  OrgRole.student: 'طالب',
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
    final results = await Future.wait([
      client.from('students_profile').count().eq('organization_id', orgId),
      client.from('organization_members').count().eq('organization_id', orgId).eq('role', 'teacher'),
      client.from('circles').count().eq('organization_id', orgId),
      client
          .from('attendance')
          .count()
          .eq('organization_id', orgId)
          .eq('session_date', today)
          .eq('status', 'present'),
    ]);
    return _DashboardStats(students: results[0], teachers: results[1], circles: results[2], presentToday: results[3]);
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final membership = tenant.active;
    final org = membership?.organization;
    final isAdmin = membership?.role == OrgRole.admin;
    final scheme = Theme.of(context).colorScheme;

    final quickActions = <_QuickAction>[
      if (tenant.hasModule('attendance'))
        const _QuickAction(Icons.fact_check_rounded, 'تسجيل الحضور', '/attendance'),
      if (tenant.hasModule('students'))
        const _QuickAction(Icons.person_add_alt_1_rounded, 'إضافة طالب', '/students/new'),
      if (tenant.hasModule('serd'))
        const _QuickAction(Icons.menu_book_rounded, 'جلسة سرد', '/serd/new'),
      if (tenant.hasModule('announcements'))
        const _QuickAction(Icons.campaign_rounded, 'إعلان جديد', '/announcements/new'),
      if (tenant.hasModule('chat')) const _QuickAction(Icons.chat_bubble_rounded, 'المحادثات', '/chat'),
      if (tenant.hasModule('calendar'))
        const _QuickAction(Icons.calendar_month_rounded, 'التقويم', '/calendar'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة التحكم')),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_loadedForOrgId != null) setState(() => _reload(_loadedForOrgId!));
          await _statsFuture;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [scheme.primary, Color.lerp(scheme.primary, Colors.black, 0.3)!],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('السلام عليكم',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(org?.name ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        StatusChip(label: _roleGreeting[membership?.role] ?? '', color: Colors.teal),
                      ],
                    ),
                  ),
                  Icon(Icons.auto_stories_rounded, size: 56, color: Colors.white.withValues(alpha: 0.25)),
                ],
              ),
            ),
            if (_circlesFuture != null) ...[
              const SectionTitle('حلقاتك اليوم'),
              AsyncBody<TeacherToday>(
                future: _circlesFuture!,
                onRetry: () => setState(() => _reload(_loadedForOrgId!)),
                builder: (context, today) {
                  if (today.circles.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('لم يتم تعيينك لأي حلقة بعد - اطلب من المشرف إضافتك.'),
                    );
                  }
                  return Column(
                    children: [
                      if (!today.isWorkingDay)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: MessageBanner(message: 'اليوم ليس من أيام الدوام في مركزك', isError: false),
                        ),
                      for (final c in today.circles)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: const Icon(Icons.groups_rounded),
                              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    StatusChip(label: '${c.students} طالب', color: Colors.blue),
                                    StatusChip(label: 'سمّع ${c.recited}', color: Colors.green),
                                    StatusChip(label: 'حاضر ${c.present}', color: Colors.teal),
                                    if (c.absent > 0) StatusChip(label: 'غائب ${c.absent}', color: Colors.red),
                                  ],
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_left_rounded),
                              onTap: () => context.push('/circle/${c.id}'),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 20),
            if (_statsFuture == null)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else
              AsyncBody<_DashboardStats>(
              future: _statsFuture!,
              onRetry: () => setState(() => _reload(_loadedForOrgId!)),
              builder: (context, stats) {
                final cards = <Widget>[
                  if (tenant.hasModule('students'))
                    _StatCard(icon: Icons.people_alt_rounded, label: 'الطلاب', value: stats.students, color: Colors.blue),
                  if (isAdmin)
                    _StatCard(icon: Icons.school_rounded, label: 'المعلمون', value: stats.teachers, color: Colors.purple),
                  if (tenant.hasModule('circles'))
                    _StatCard(icon: Icons.groups_rounded, label: 'الحلقات', value: stats.circles, color: Colors.orange),
                  if (tenant.hasModule('attendance'))
                    _StatCard(icon: Icons.how_to_reg_rounded, label: 'حضور اليوم', value: stats.presentToday, color: Colors.green),
                ];
                if (cards.isEmpty) return const SizedBox.shrink();
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.45,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: cards,
                );
              },
            ),
            if (quickActions.isNotEmpty) ...[
              const SectionTitle('اختصارات سريعة'),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [for (final a in quickActions) _QuickActionTile(action: a)],
              ),
            ],
          ],
        ),
      ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final int value;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color.shade700, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1)),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.icon, this.label, this.path);

  final IconData icon;
  final String label;
  final String path;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push(action.path),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: primary, size: 28),
            const SizedBox(height: 8),
            Text(action.label,
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
