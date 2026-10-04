import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/i18n.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/garden.dart';
import '../../core/widgets/ui.dart';
import '../recitation/recitation_repository.dart';
import 'profile_widgets.dart';
import 'profiles_repository.dart';

/// Everything about one teacher: circles, the period's work against the one
/// before, their own attendance, and what they recorded lately. [teacherId]
/// is a membership id or a user id.
class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key, required this.teacherId});
  final String teacherId;

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
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
      _repo.teacher(orgId, widget.teacherId, p),
      _repo.previousTotals(() => _repo.teacher(orgId, widget.teacherId, p.previous)),
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
          final x = r['teacher'] as Map<String, dynamic>;
          final tt = r['totals'] as Map<String, dynamic>;
          final circles = (r['circles'] as List).cast<Map<String, dynamic>>();
          final att = (r['attendance'] as List).cast<Map<String, dynamic>>();
          final me = Supabase.instance.client.auth.currentUser?.id;
          final phone = x['phone'] as String?;
          final whatsapp = (x['whatsapp'] as String?)?.replaceAll(RegExp(r'\D'), '');
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(padding: EdgeInsets.zero, children: [
              GardenHeader(
                leading: const BackButton(color: Colors.white),
                title: '${x['name'] ?? x['email'] ?? '—'}',
                greeting: t.labels.roles[x['role']] ?? '${x['role']}',
                subtitle: fmt(P.lastRec, {'v': relDay(context, x['last_active'] as String?)}),
                actions: [
                  if (phone != null && phone.isNotEmpty)
                    IconButton(tooltip: P.call, onPressed: () => launchUrl(Uri.parse('tel:$phone')), icon: const Icon(Icons.call_rounded, color: Colors.white)),
                  if (whatsapp != null && whatsapp.isNotEmpty)
                    IconButton(
                      tooltip: P.whatsapp,
                      onPressed: () => launchUrl(Uri.parse('https://wa.me/$whatsapp'), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.forum_rounded, color: Colors.white),
                    ),
                  if (x['user_id'] != me)
                    IconButton(tooltip: P.message, onPressed: () => context.push('/chat/${x['user_id']}'), icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white)),
                ],
                stats: [
                  HeaderStat('${tt['students']}', P.students, icon: Icons.people_alt_rounded),
                  HeaderStat('${circles.length}', P.circles, icon: Icons.groups_rounded),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  PeriodPicker(value: _period, onChanged: _setPeriod),
                  if (prev != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(P.vsPrev, style: const TextStyle(fontSize: 11.5, color: kInkMuted))),
                  const SizedBox(height: 12),
                  ProfileStatGrid(children: [
                    ProfileStat(icon: Icons.menu_book_rounded, label: P.recitations, value: '${tt['recitations']}', now: tt['recitations'], prev: prev?['recitations']),
                    ProfileStat(icon: Icons.record_voice_over_rounded, label: P.reciting, value: '${tt['reciting_students']}', now: tt['reciting_students'], prev: prev?['reciting_students'], color: TeacherStyle.blue),
                    ProfileStat(icon: Icons.stars_rounded, label: P.points, value: '${tt['points']}', now: tt['points'], prev: prev?['points'], color: TeacherStyle.gold),
                    ProfileStat(icon: Icons.fact_check_rounded, label: P.serdHeard, value: '${tt['serd']}', now: tt['serd'], prev: prev?['serd'], color: TeacherStyle.success),
                    ProfileStat(
                      icon: Icons.how_to_reg_rounded,
                      label: P.daysPresent,
                      value: '${(tt['present'] as num) + (tt['late'] as num)}',
                      now: (tt['present'] as num) + (tt['late'] as num),
                      prev: prev == null ? null : (prev['present'] as num) + (prev['late'] as num),
                      color: TeacherStyle.success,
                    ),
                  ]),
                  GardenSection(
                    title: P.circles,
                    icon: Icons.groups_rounded,
                    child: GardenCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(children: [
                        for (final c in circles)
                          ListTile(
                            onTap: () => context.push('/circles/${c['id']}/profile'),
                            title: Text('${c['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text([
                              if (c['kind'] == 'assistant') P.assistant,
                              if (c['stage'] != null) '${c['stage']}',
                              '${c['students']} ${P.students}',
                              '${P.attendance} ${c['attendance_rate'] == null ? '—' : '${c['attendance_rate']}%'}',
                            ].join('  ·  ')),
                            trailing: Text('${c['recitations']}', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
                          ),
                        if (circles.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(P.nothing, style: const TextStyle(color: kInkMuted))),
                      ]),
                    ),
                  ),
                  GardenSection(
                    title: P.recent,
                    icon: Icons.history_rounded,
                    child: RecentRecitations(rows: r['recent'] as List, grades: grades, onStudent: (id) => context.push('/students/$id/file')),
                  ),
                  GardenSection(
                    title: P.teacherAtt,
                    icon: Icons.how_to_reg_rounded,
                    child: GardenCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(children: [
                        for (final a in att.take(20))
                          ListTile(
                            dense: true,
                            title: Text('${formatDate(a['date'] as String?)}  ·  ${a['circle']}'),
                            subtitle: a['checked_in_at'] == null ? null : Text(formatDateTime(a['checked_in_at'] as String?)),
                            trailing: GardenChip(t.labels.attendance[a['status']] ?? '${a['status']}',
                                color: a['status'] == 'present' ? TeacherStyle.success : a['status'] == 'absent' ? TeacherStyle.danger : TeacherStyle.warning),
                          ),
                        if (att.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(P.nothing, style: const TextStyle(color: kInkMuted))),
                      ]),
                    ),
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
