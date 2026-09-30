import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/widgets/garden.dart';
import '../../core/widgets/ui.dart';
import '../recitation/recitation_repository.dart';
import 'profile_widgets.dart';
import 'profiles_repository.dart';

/// Everything about one circle: its teachers, the period against the one
/// before, a ranked roster and the latest recitations.
class CircleProfileScreen extends StatefulWidget {
  const CircleProfileScreen({super.key, required this.circleId});
  final String circleId;

  @override
  State<CircleProfileScreen> createState() => _CircleProfileScreenState();
}

class _CircleProfileScreenState extends State<CircleProfileScreen> {
  final _repo = ProfilesRepository(Supabase.instance.client);
  String _period = 'month';
  late Future<(Map<String, dynamic>, Map<String, dynamic>?, Map<String, String>)> _future;

  String get _orgId => context.read<TenantController>().active!.organization.id;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(Map<String, dynamic>, Map<String, dynamic>?, Map<String, String>)> _load() async {
    final orgId = _orgId;
    final p = ProfilePeriod.of(_period);
    final results = await Future.wait<dynamic>([
      _repo.circle(orgId, widget.circleId, p),
      _repo.previousTotals(() => _repo.circle(orgId, widget.circleId, p.previous)),
      RecitationRepository(Supabase.instance.client).fetchGrades(orgId),
    ]);
    return (results[0] as Map<String, dynamic>, results[1] as Map<String, dynamic>?, {for (final g in results[2] as List<GradeOption>) g.key: g.label});
  }

  void _setPeriod(String p) => setState(() {
        _period = p;
        _future = _load();
      });

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final P = t.prof;
    return Scaffold(
      body: FutureBuilder<(Map<String, dynamic>, Map<String, dynamic>?, Map<String, String>)>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Scaffold(appBar: AppBar(), body: ErrorState(message: P.notAllowed, onRetry: () => setState(() => _future = _load())));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final (r, prev, grades) = snap.data!;
          final c = r['circle'] as Map<String, dynamic>;
          final teacher = r['teacher'] as Map<String, dynamic>?;
          final assistants = (r['assistants'] as List).cast<Map<String, dynamic>>();
          final tt = r['totals'] as Map<String, dynamic>;
          final students = (r['students'] as List).cast<Map<String, dynamic>>();
          final brand = Theme.of(context).colorScheme.primary;
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(padding: EdgeInsets.zero, children: [
              GardenHeader(
                leading: const BackButton(color: Colors.white),
                title: '${c['name']}',
                greeting: c['stage'] as String?,
                subtitle: teacher == null ? null : '${P.teacher}: ${teacher['name'] ?? '—'}',
                actions: [
                  IconButton(tooltip: t.prof.recitations, onPressed: () => context.push('/circle/${c['id']}'), icon: const Icon(Icons.groups_rounded, color: Colors.white)),
                  if (context.read<TenantController>().active?.role == OrgRole.admin)
                    IconButton(
                      tooltip: t.stu.editDetails,
                      onPressed: () async {
                        await context.push('/circles/${c['id']}');
                        if (mounted) setState(() => _future = _load());
                      },
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                    ),
                ],
                stats: [
                  HeaderStat('${tt['students']}${c['capacity'] == null ? '' : '/${c['capacity']}'}', P.students, icon: Icons.people_alt_rounded),
                  HeaderStat(tt['attendance_rate'] == null ? '—' : '${tt['attendance_rate']}%', P.attendance, icon: Icons.how_to_reg_rounded),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (teacher != null || assistants.isNotEmpty)
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      if (teacher != null)
                        ActionChip(
                          avatar: const Icon(Icons.school_rounded, size: 18),
                          label: Text('${teacher['name'] ?? '—'}'),
                          onPressed: () => context.push('/teachers/${teacher['member_id']}'),
                        ),
                      for (final a in assistants)
                        ActionChip(
                          avatar: const Icon(Icons.handshake_rounded, size: 18),
                          label: Text('${a['name'] ?? '—'} · ${P.assistant}'),
                          onPressed: () => context.push('/teachers/${a['member_id']}'),
                        ),
                    ]),
                  const SizedBox(height: 12),
                  PeriodPicker(value: _period, onChanged: _setPeriod),
                  if (prev != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(P.vsPrev, style: const TextStyle(fontSize: 11.5, color: kInkMuted))),
                  const SizedBox(height: 12),
                  ProfileStatGrid(children: [
                    ProfileStat(icon: Icons.menu_book_rounded, label: P.recitations, value: '${tt['recitations']}', now: tt['recitations'], prev: prev?['recitations']),
                    ProfileStat(icon: Icons.record_voice_over_rounded, label: P.reciting, value: '${tt['reciting_students']}/${tt['students']}', now: tt['reciting_students'], prev: prev?['reciting_students'], color: TeacherStyle.blue),
                    ProfileStat(icon: Icons.stars_rounded, label: P.points, value: '${tt['points']}', now: tt['points'], prev: prev?['points'], color: TeacherStyle.gold),
                    ProfileStat(
                      icon: Icons.how_to_reg_rounded,
                      label: P.attendance,
                      value: tt['attendance_rate'] == null ? '—' : '${tt['attendance_rate']}%',
                      now: tt['attendance_rate'],
                      prev: prev?['attendance_rate'],
                      points: true,
                      color: TeacherStyle.success,
                    ),
                    ProfileStat(icon: Icons.fact_check_rounded, label: P.serdApproved, value: '${tt['serd_approved']}', now: tt['serd_approved'], prev: prev?['serd_approved'], color: TeacherStyle.success),
                    ProfileStat(icon: Icons.badge_rounded, label: P.teacherDays, value: '${tt['teacher_days']}', now: tt['teacher_days'], prev: prev?['teacher_days'], color: TeacherStyle.warning),
                  ]),
                  GardenSection(
                    title: P.students,
                    icon: Icons.people_alt_rounded,
                    child: GardenCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(children: [
                        for (var i = 0; i < students.length; i++)
                          Builder(builder: (context) {
                            final s = students[i];
                            final active = s['status'] == 'active';
                            final last = s['last_recited'] as String?;
                            final stale = active && (last == null || DateTime.now().difference(DateTime.parse(last)).inDays > 7);
                            return ListTile(
                              onTap: () => context.push('/students/${s['id']}/file'),
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: brand.withValues(alpha: 0.1),
                                child: Text('${i + 1}', style: TextStyle(color: brand, fontWeight: FontWeight.w800, fontSize: 13)),
                              ),
                              title: Text('${s['name']}', style: TextStyle(fontWeight: FontWeight.w700, color: active ? kInk : kInkMuted)),
                              subtitle: Text(
                                '${s['recitations']} ${P.recitations}  ·  ${P.attendance} ${s['attendance_rate'] == null ? '—' : '${s['attendance_rate']}%'}\n${fmt(P.lastRec, {'v': relDay(context, last)})}',
                                style: TextStyle(fontSize: 12, color: stale ? TeacherStyle.warning : kInkMuted),
                              ),
                              isThreeLine: true,
                              trailing: Text('${s['total_points']}', style: const TextStyle(fontWeight: FontWeight.w800, color: TeacherStyle.gold)),
                            );
                          }),
                        if (students.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(P.nothing, style: const TextStyle(color: kInkMuted))),
                      ]),
                    ),
                  ),
                  GardenSection(
                    title: P.recent,
                    icon: Icons.history_rounded,
                    child: RecentRecitations(rows: r['recent'] as List, grades: grades, onStudent: (id) => context.push('/students/$id/file')),
                  ),
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }
}
