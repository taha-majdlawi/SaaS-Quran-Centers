import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/offline/sync_service.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/org_avatar.dart';
import '../../core/widgets/ui.dart';
import '../recitation/recitation_repository.dart';
import 'circle_roster.dart';
import 'teacher_widgets.dart';

/// The teacher's home (modelled on the eqraa teacher dashboard): a gradient
/// greeting header with quick actions, then one expandable card per circle with
/// the lesson button and the roster right inside it.
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
      final row = await AppSupabase.client.from('profiles').select('full_name').eq('id', id).maybeSingle();
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
    final sync = context.watch<SyncService>();
    final issues = sync.pendingCount + sync.failedCount;

    return Scaffold(
      backgroundColor: TeacherStyle.scaffold,
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        color: TeacherStyle.brand(context),
        onRefresh: () async {
          _reload();
          await _future;
        },
        child: CustomScrollView(slivers: [
          teacherHeader(
            context,
            title: _teacherName.isEmpty ? 'لوحة تحكم المعلم' : 'أهلاً بك، ${_teacherName.split(' ').first}',
            actions: [
              if (tenant.hasModule('students')) IconButton(tooltip: 'بحث عن طالب', onPressed: () => context.push('/students'), icon: const Icon(Icons.person_search_rounded)),
              if (tenant.hasModule('attendance')) IconButton(tooltip: 'الحضور', onPressed: () => context.push('/attendance'), icon: const Icon(Icons.fact_check_rounded)),
              IconButton(
                tooltip: 'المزامنة',
                onPressed: () => context.push('/sync'),
                icon: Badge(
                  isLabelVisible: issues > 0,
                  label: Text('$issues'),
                  backgroundColor: sync.failedCount > 0 ? Colors.red : Colors.orange,
                  child: Icon(sync.flushing ? Icons.sync_rounded : Icons.cloud_sync_outlined),
                ),
              ),
            ],
            background: Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 20, bottom: 46),
                child: Opacity(opacity: 0.25, child: OrgAvatar(name: org.name, logoUrl: org.logoUrl, brandColor: org.primaryColor, size: 72, onDark: true)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<({List<MyCircle> circles, List<GradeOption> grades, TeacherToday? today})>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) return Padding(padding: const EdgeInsets.all(24), child: ErrorState(onRetry: _reload));
                final data = snap.data;
                if (data == null) return const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()));
                if (data.circles.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyState(icon: Icons.groups_outlined, title: 'لم يتم تعيينك لأي حلقة بعد', subtitle: 'اطلب من المشرف إضافتك إلى حلقة، ثم اسحب للأسفل للتحديث.'),
                  );
                }
                final today = data.today;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (today != null && !today.isWorkingDay)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: TeacherStyle.goldLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: TeacherStyle.gold.withValues(alpha: 0.4))),
                        child: const Row(children: [
                          Icon(Icons.event_busy_rounded, color: TeacherStyle.gold),
                          SizedBox(width: 8),
                          Expanded(child: Text('اليوم ليس من أيام الدوام في مركزك', style: TextStyle(fontSize: 13))),
                        ]),
                      ),
                    SectionLabel('حلقاتك (${data.circles.length})'),
                    for (final c in data.circles)
                      _CircleCard(key: ValueKey('${c.id}-$_version'), circle: c, grades: data.grades, onChanged: _reload),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _CircleCard extends StatefulWidget {
  const _CircleCard({super.key, required this.circle, required this.grades, required this.onChanged});

  final MyCircle circle;
  final List<GradeOption> grades;
  final VoidCallback onChanged;

  @override
  State<_CircleCard> createState() => _CircleCardState();
}

class _CircleCardState extends State<_CircleCard> {
  final _repository = RecitationRepository(AppSupabase.client);
  late final Future<List<CircleStudent>> _students = _repository.fetchCircleStudents(widget.circle.id);

  @override
  Widget build(BuildContext context) {
    final brand = TeacherStyle.brand(context);
    final c = widget.circle;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      color: TeacherStyle.surface,
      shape: TeacherStyle.cardShape,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: TeacherStyle.tint(brand), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.menu_book_rounded, color: brand),
          ),
          title: Row(children: [
            Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            IconButton(tooltip: 'شاشة الحلقة', icon: Icon(Icons.open_in_new_rounded, color: brand, size: 20), onPressed: () async {
              await context.push('/circle/${c.id}');
              if (mounted) widget.onChanged();
            }),
          ]),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: FutureBuilder<List<CircleStudent>>(
              future: _students,
              builder: (context, snap) {
                final done = snap.data?.where((s) => s.recitedToday > 0).length;
                return Wrap(spacing: 6, runSpacing: 4, children: [
                  Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: TeacherStyle.chip,
                    side: BorderSide.none,
                    label: Text('المرحلة: ${c.stageName ?? 'عامة'}', style: const TextStyle(color: TeacherStyle.textMuted, fontSize: 12)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (done != null)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: TeacherStyle.tint(TeacherStyle.success),
                      side: BorderSide.none,
                      label: Text('سمّع $done من ${snap.data!.length}', style: const TextStyle(color: TeacherStyle.success, fontSize: 12, fontWeight: FontWeight.w600)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ]);
              },
            ),
          ),
          children: [
            FutureBuilder<List<CircleStudent>>(
              future: _students,
              builder: (context, snap) {
                if (snap.hasError) return Padding(padding: const EdgeInsets.all(16), child: ErrorState(onRetry: widget.onChanged));
                final students = snap.data;
                if (students == null) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: FilledButton.icon(
                      onPressed: () async {
                        await context.push('/circle/${c.id}/lesson');
                        if (mounted) widget.onChanged();
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                      label: const Text('ابدأ الحصة'),
                    ),
                  ),
                  CircleRoster(circleId: c.id, students: students, grades: widget.grades, onChanged: widget.onChanged),
                ]);
              },
            ),
          ],
        ),
      ),
    );
  }
}
