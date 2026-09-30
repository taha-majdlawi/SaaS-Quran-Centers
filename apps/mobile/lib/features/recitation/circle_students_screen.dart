import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import '../teacher/circle_roster.dart';
import '../teacher/teacher_widgets.dart';
import 'recitation_repository.dart';
import '../../core/i18n/i18n.dart';
import '../../core/offline/sync_service.dart';

class _CircleData {
  const _CircleData({required this.name, required this.students, required this.grades});
  final String name;
  final List<CircleStudent> students;
  final List<GradeOption> grades;
}

/// One circle as a page: gradient header with today's progress, the lesson
/// button, and the roster (search / filter / sort, one-tap attendance and
/// recitation) - the eqraa circle card as its own screen.
class CircleStudentsScreen extends StatefulWidget {
  const CircleStudentsScreen({super.key, required this.circleId});

  final String circleId;

  @override
  State<CircleStudentsScreen> createState() => _CircleStudentsScreenState();
}

class _CircleStudentsScreenState extends State<CircleStudentsScreen> {
  final _repository = RecitationRepository(AppSupabase.client);
  late Future<_CircleData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CircleData> _load() async {
    final orgId = context.read<TenantController>().active!.organization.id;
    final results = await Future.wait<dynamic>([
      SyncService.instance.raw('circle-name:${widget.circleId}', () => AppSupabase.client.from('circles').select('name').eq('id', widget.circleId).single()),
      _repository.fetchCircleStudents(widget.circleId),
      _repository.fetchGrades(orgId),
    ]);
    return _CircleData(
      name: (results[0] as Map<String, dynamic>)['name'] as String,
      students: results[1] as List<CircleStudent>,
      grades: results[2] as List<GradeOption>,
    );
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CircleData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final done = data?.students.where((s) => s.recitedToday > 0).length ?? 0;
        final total = data?.students.length ?? 0;
        return Scaffold(
          backgroundColor: TeacherStyle.scaffold,
          body: RefreshIndicator(
            color: TeacherStyle.brand(context),
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: CustomScrollView(slivers: [
              teacherHeader(
                context,
                title: data?.name ?? tr(context).rec.circle,
                expandedHeight: 150,
                actions: [
                  IconButton(
                    tooltip: tr(context).prof.profile,
                    icon: const Icon(Icons.insights_rounded),
                    onPressed: () => context.push('/circles/${widget.circleId}/profile'),
                  ),
                ],
                background: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 52),
                    child: total == 0
                        ? const SizedBox.shrink()
                        : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(fmt(tr(context).rec.doneToday, {'done': done, 'total': total}), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 220,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(value: done / total, minHeight: 8, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(TeacherStyle.gold)),
                              ),
                            ),
                          ]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: snapshot.hasError
                    ? Padding(padding: const EdgeInsets.all(24), child: ErrorState(onRetry: _reload))
                    : data == null
                        ? const Padding(padding: EdgeInsets.all(16), child: SkeletonCards(count: 4, height: 96))
                        : Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 24),
                            child: Column(children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                                child: FilledButton.icon(
                                  onPressed: () async {
                                    await context.push('/circle/${widget.circleId}/lesson');
                                    if (mounted) _reload();
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                                  label: Text(tr(context).teach.startLesson),
                                ),
                              ),
                              CircleRoster(circleId: widget.circleId, students: data.students, grades: data.grades, onChanged: _reload),
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
