import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/offline/sync_service.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/garden.dart';
import '../../core/widgets/org_avatar.dart';
import '../../core/widgets/ui.dart';
import '../insights/insights_repository.dart';
import '../recitation/recitation_repository.dart';
import 'circle_roster.dart';
import 'teacher_home_widgets.dart';
import '../../core/i18n/i18n.dart';

/// The teacher's home: the garden header with today's numbers, the shortcuts
/// a teacher needs first, then one card per circle (progress ring, check-in,
/// start the lesson) with its roster folded underneath. Works from the phone's
/// copy when there is no connection.
class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final _repository = RecitationRepository(AppSupabase.client);
  Future<({List<MyCircle> circles, List<GradeOption> grades, TeacherToday? today})>? _future;
  String? _orgId;
  String _teacherName = '';
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final id = context.read<AuthController>().currentUser?.id;
    if (id == null) return;
    try {
      final row = await SyncService.instance.raw('my-name', () => AppSupabase.client.from('profiles').select('full_name').eq('id', id).maybeSingle());
      final name = (row?['full_name'] as String?)?.trim() ?? '';
      if (mounted && name.isNotEmpty) setState(() => _teacherName = name);
    } catch (_) {}
  }

  Future<({List<MyCircle> circles, List<GradeOption> grades, TeacherToday? today})> _load() async {
    final userId = context.read<AuthController>().currentUser!.id;
    final circles = await _repository.fetchMyCircles(_orgId!, userId: userId, isAdmin: false);
    final grades = await _repository.fetchGrades(_orgId!);
    TeacherToday? today;
    try {
      today = await _repository.fetchTeacherToday(_orgId!);
    } catch (_) {}
    return (circles: circles, grades: grades, today: today);
  }

  void _reload() => setState(() {
        _version++;
        _future = _load();
      });

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final org = tenant.active?.organization;
    if (org == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_orgId != org.id) {
      _orgId = org.id;
      _future = _load();
    }
    final t = tr(context);

    return Scaffold(
      body: RefreshIndicator(
        color: TeacherStyle.brand(context),
        onRefresh: () async {
          _reload();
          await _future;
        },
        child: FutureBuilder<({List<MyCircle> circles, List<GradeOption> grades, TeacherToday? today})>(
          future: _future,
          builder: (context, snap) {
            final data = snap.data;
            final today = data?.today;
            final circlesToday = today?.circles ?? const <TodayCircle>[];
            int sum(int Function(TodayCircle c) f) => circlesToday.fold(0, (a, c) => a + f(c));
            return ListView(padding: EdgeInsets.zero, children: [
              GardenHeader(
                leading: OrgAvatar(name: org.name, logoUrl: org.logoUrl, brandColor: org.primaryColor, size: 34, onDark: true),
                greeting: timeGreeting(),
                title: _teacherName.isEmpty ? org.name : _teacherName,
                subtitle: longToday(context),
                actions: [
                  if (tenant.hasModule('students'))
                    IconButton(tooltip: t.teach.findStudent, onPressed: () => context.push('/search'), icon: const Icon(Icons.person_search_rounded, color: Colors.white)),
                ],
                stats: data == null
                    ? const []
                    : [
                        HeaderStat('${data.circles.length}', t.garden.statCircles, icon: Icons.groups_rounded),
                        HeaderStat('${today == null ? data.circles.fold<int>(0, (a, c) => a + c.studentCount) : sum((c) => c.students)}', t.garden.statStudents, icon: Icons.people_alt_rounded),
                        if (today != null) HeaderStat('${sum((c) => c.recited)}', t.garden.statRecited, icon: Icons.menu_book_rounded),
                        if (today != null) HeaderStat('${sum((c) => c.present)}', t.garden.statPresent, icon: Icons.check_circle_rounded),
                      ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TeacherQuickActions(actions: [
                    if (tenant.hasModule('attendance'))
                      (icon: Icons.fact_check_rounded, label: t.nav.items['/attendance']!, color: TeacherStyle.success, onTap: () => context.push('/attendance')),
                    if (tenant.hasModule('students'))
                      (icon: Icons.person_search_rounded, label: t.teach.findStudent, color: TeacherStyle.blue, onTap: () => context.push('/search')),
                    if (tenant.hasModule('serd'))
                      (icon: Icons.menu_book_rounded, label: t.serd.record, color: TeacherStyle.warning, onTap: () => context.push('/serd/new')),
                    if (tenant.hasModule('students'))
                      (icon: Icons.record_voice_over_rounded, label: t.gather.extNew, color: const Color(0xFF8E44AD), onTap: () => context.push('/external-recitations')),
                  ]),
                  if (snap.hasError)
                    Padding(padding: const EdgeInsets.only(top: 24), child: ErrorState(onRetry: _reload))
                  else if (data == null)
                    const Padding(padding: EdgeInsets.only(top: 22), child: SkeletonCards(count: 2, height: 150))
                  else if (data.circles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: EmptyState(icon: Icons.groups_outlined, title: t.teach.noCircle, subtitle: t.teach.noCircleHint),
                    )
                  else ...[
                    if (today != null && !today.isWorkingDay)
                      Container(
                        margin: const EdgeInsets.only(top: 18),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: TeacherStyle.goldLight, borderRadius: BorderRadius.circular(14)),
                        child: Row(children: [
                          const Icon(Icons.event_busy_rounded, color: TeacherStyle.gold),
                          const SizedBox(width: 8),
                          Expanded(child: Text(t.dash.notWorkingDay, style: const TextStyle(fontSize: 13))),
                        ]),
                      ),
                    GardenSection(
                      title: fmt(t.teach.yourCircles, {'n': data.circles.length}),
                      icon: Icons.groups_rounded,
                      child: Column(children: [
                        for (final c in data.circles)
                          _CircleCard(
                            key: ValueKey('${c.id}-$_version'),
                            circle: c,
                            grades: data.grades,
                            today: circlesToday.where((x) => x.id == c.id).firstOrNull,
                            // one circle: its students are open right away
                            startOpen: data.circles.length == 1,
                            onChanged: _reload,
                          ),
                      ]),
                    ),
                  ],
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _CircleCard extends StatefulWidget {
  const _CircleCard({super.key, required this.circle, required this.grades, required this.onChanged, this.today, this.startOpen = false});

  final MyCircle circle;
  final List<GradeOption> grades;
  final TodayCircle? today;
  final bool startOpen;
  final VoidCallback onChanged;

  @override
  State<_CircleCard> createState() => _CircleCardState();
}

class _CircleCardState extends State<_CircleCard> {
  final _repository = RecitationRepository(AppSupabase.client);
  late final Future<List<CircleStudent>> _students = _repository.fetchCircleStudents(widget.circle.id);
  final _insights = InsightsRepository(AppSupabase.client);
  bool? _checkedIn;
  late bool _open = widget.startOpen;

  @override
  void initState() {
    super.initState();
    _loadCheckIn();
  }

  String get _orgId => context.read<TenantController>().active!.organization.id;

  Future<void> _loadCheckIn() async {
    try {
      final set = await _insights.checkedInCircles(_orgId);
      if (mounted) setState(() => _checkedIn = set.contains(widget.circle.id));
    } catch (_) {}
  }

  Future<void> _checkIn() async {
    try {
      final queued = await _insights.checkIn(_orgId, widget.circle.id);
      if (mounted) {
        setState(() => _checkedIn = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(queued ? kQueuedMessage : tr(context).teach.checkedIn)));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context).teach.checkInFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.circle;
    return FutureBuilder<List<CircleStudent>>(
      future: _students,
      builder: (context, snap) {
        final students = snap.data;
        // the students list already counts what is waiting on the phone; the day summary is the fallback
        final done = students?.where((s) => s.recitedToday > 0).length ?? widget.today?.recited;
        final present = students != null ? students.where((s) => s.attendanceToday == 'present' || s.attendanceToday == 'late').length : widget.today?.present;
        final absent = students != null ? students.where((s) => s.attendanceToday == 'absent').length : widget.today?.absent;
        return TeacherCircleCard(
          circle: c,
          done: done,
          total: students?.length ?? widget.today?.students,
          present: present,
          absent: absent,
          checkedIn: _checkedIn,
          onOpen: () async {
            await context.push('/circle/${c.id}');
            if (mounted) widget.onChanged();
          },
          onStart: () async {
            await context.push('/circle/${c.id}/lesson');
            if (mounted) widget.onChanged();
          },
          onCheckIn: _checkIn,
          rosterOpen: _open,
          onToggleRoster: () => setState(() => _open = !_open),
          roster: snap.hasError
              ? Padding(padding: const EdgeInsets.all(16), child: ErrorState(onRetry: widget.onChanged))
              : students == null
                  ? const Padding(padding: EdgeInsets.all(12), child: SkeletonCards(count: 2, height: 80))
                  : CircleRoster(circleId: c.id, students: students, grades: widget.grades, onChanged: widget.onChanged),
        );
      },
    );
  }
}
