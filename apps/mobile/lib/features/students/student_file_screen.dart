import 'package:flutter/material.dart';
import '../quran/wird_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/api/accounts_api.dart';
import '../../core/data/quran_data.dart';
import '../../core/offline/sync_service.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/credentials_dialog.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import '../insights/student_notes_section.dart';
import '../members/members_repository.dart';
import '../my_portal/my_portal_repository.dart';
import '../recitation/recitation_repository.dart';
import '../recitation/recitation_sheet.dart';
import '../serd/serd_models.dart';
import '../serd/serd_repository.dart';
import '../serd/serd_widgets.dart';
import '../teacher/teacher_widgets.dart';
import '../profiles/profile_widgets.dart';
import '../../core/i18n/i18n.dart';

class _FileData {
  const _FileData({
    required this.dashboard,
    required this.entries,
    required this.grades,
    required this.guardians,
    this.guardianMemberId,
    this.serd,
  });
  final PortalDashboard dashboard;
  final List<RecitationEntry> entries;
  final List<GradeOption> grades;

  /// Guardian accounts of the center (loaded for admins only).
  final List<MemberRow> guardians;
  final String? guardianMemberId;
  final SerdSummary? serd;
}

/// The teacher's / admin's view of one student (eqraa's student file):
/// progress, next plan, contact, and the recitation history with edit/delete.
/// Every write goes through an RPC that checks the caller owns the circle.
class StudentFileScreen extends StatefulWidget {
  const StudentFileScreen({super.key, required this.studentId});

  final String studentId;

  @override
  State<StudentFileScreen> createState() => _StudentFileScreenState();
}

class _StudentFileScreenState extends State<StudentFileScreen> {
  final _portal = MyPortalRepository(AppSupabase.client);
  final _recitations = RecitationRepository(AppSupabase.client);
  late Future<_FileData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  String get _orgId => context.read<TenantController>().active!.organization.id;

  Future<_FileData> _load() async {
    final orgId = _orgId;
    final isAdmin = context.read<TenantController>().active?.role == OrgRole.admin;
    final results = await Future.wait<dynamic>([
      _portal.fetchDashboard(orgId, widget.studentId),
      _recitations.fetchStudentRecitations(widget.studentId),
      _recitations.fetchGrades(orgId),
      SyncService.instance.raw('student-guardian:${widget.studentId}', () => AppSupabase.client.from('students_profile').select('guardian_member_id').eq('id', widget.studentId).maybeSingle()),
      isAdmin ? MembersRepository(AppSupabase.client).fetchMembers(orgId) : Future.value(<MemberRow>[]),
      // The serd module may be off for this teacher; the file must still open.
      SerdRepository(AppSupabase.client).studentSummary(orgId, widget.studentId).then<SerdSummary?>((v) => v).catchError((_) => null),
    ]);
    final dashboard = results[0] as PortalDashboard?;
    if (dashboard == null) throw StateError('student not found');
    final waitingPlan = RecitationRepository.pendingPlan(widget.studentId);
    if (waitingPlan != null) dashboard.nextPlan = waitingPlan.plan;
    return _FileData(
      dashboard: dashboard,
      entries: results[1] as List<RecitationEntry>,
      grades: results[2] as List<GradeOption>,
      guardianMemberId: (results[3] as Map<String, dynamic>?)?['guardian_member_id'] as String?,
      guardians: (results[4] as List<MemberRow>).where((m) => m.role == 'guardian').toList(),
      serd: results[5] as SerdSummary?,
    );
  }

  void _reload() => setState(() => _future = _load());

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _addRecitation(_FileData data) async {
    final points = await showRecitationSheet(
      context,
      studentId: widget.studentId,
      studentName: data.dashboard.fullName,
      grades: data.grades,
    );
    if (points != null && mounted) {
      _toast(points == kQueuedPoints ? kQueuedMessage : fmt(tr(context).teach.savedPoints, {'points': points}));
      _reload();
    }
  }

  Future<void> _edit(_FileData data, RecitationEntry entry) async {
    final done = await showRecitationSheet(
      context,
      studentId: widget.studentId,
      studentName: data.dashboard.fullName,
      grades: data.grades,
      editing: entry,
    );
    if (done != null && mounted) {
      _toast(tr(context).stu.recEdited);
      _reload();
    }
  }

  Future<void> _delete(RecitationEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).stu.recDeleteTitle),
        content: Text(tr(context).stu.recDeleteBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).common.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(context).common.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final queued = await _recitations.deleteRecitation(entry.id);
      if (mounted) {
        _toast(queued ? kQueuedMessage : tr(context).stu.deleted);
        _reload();
      }
    } on PostgrestException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  Future<void> _editPlan(PortalDashboard d) async {
    final controller = TextEditingController(text: d.nextPlan ?? '');
    final saved = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).stu.nextPlan),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: tr(context).stu.planPh),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(context).common.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            child: Text(tr(context).common.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved == null) return;
    try {
      final queued = await _recitations.setStudentPlan(orgId: _orgId, studentId: widget.studentId, plan: saved);
      if (mounted) {
        _toast(queued ? kQueuedMessage : tr(context).stu.planSaved);
        _reload();
      }
    } on PostgrestException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  Future<void> _linkGuardian(String? memberId) async {
    try {
      await AccountsApi().linkGuardian(orgId: _orgId, studentId: widget.studentId, guardianMemberId: memberId);
      if (mounted) {
        _toast(tr(context).stu.linkUpdated);
        _reload();
      }
    } on AccountsApiException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  Future<void> _pickGuardian(_FileData data) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(tr(context).stu.pickGuardian),
        children: [
          for (final g in data.guardians)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, g.id),
              child: Text(g.fullName ?? g.email ?? '—'),
            ),
          if (data.guardians.isEmpty) Padding(padding: EdgeInsets.all(16), child: Text(tr(context).stu.noGuardians)),
        ],
      ),
    );
    if (picked != null) await _linkGuardian(picked);
  }

  Future<void> _createGuardian() async {
    final name = TextEditingController();
    final identifier = TextEditingController();
    final phone = TextEditingController();
    final password = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).stu.newGuardian),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: InputDecoration(labelText: tr(context).stu.guardianName)),
              const SizedBox(height: 10),
              TextField(
                controller: identifier,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: tr(context).stu.loginId),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: tr(context).stu.phoneOpt),
              ),
              const SizedBox(height: 10),
              TextField(controller: password, decoration: InputDecoration(labelText: tr(context).stu.password8)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).common.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            child: Text(tr(context).stu.create),
          ),
        ],
      ),
    );
    final values = (name.text.trim(), identifier.text.trim(), phone.text.trim(), password.text.trim());
    name.dispose();
    identifier.dispose();
    phone.dispose();
    password.dispose();
    if (ok != true || !mounted) return;
    if (values.$1.isEmpty || values.$2.isEmpty || values.$4.length < 8) {
      _toast(tr(context).stu.guardianIncomplete);
      return;
    }
    try {
      final org = context.read<TenantController>().active!.organization;
      final created = await AccountsApi().createGuardian(
        orgId: org.id,
        studentId: widget.studentId,
        fullName: values.$1,
        identifier: values.$2,
        password: values.$4,
        phone: values.$3.isEmpty ? null : values.$3,
      );
      if (!mounted) return;
      _reload();
      await showCredentialsDialog(
        context,
        title: tr(context).stu.guardianCreated,
        centerCode: org.slug,
        loginId: created.loginId,
        password: values.$4,
      );
    } on AccountsApiException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FileData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Scaffold(
          backgroundColor: TeacherStyle.scaffold,
          floatingActionButton: data == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _addRecitation(data),
                  icon: const Icon(Icons.mic_none_rounded),
                  label: Text(tr(context).teach.record),
                ),
          body: snapshot.hasError
              ? ErrorState(onRetry: _reload)
              : data == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBody(context, data),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, _FileData data) {
    final d = data.dashboard;
    final gradeLabel = {for (final g in data.grades) g.key: g.label};

    Widget info(IconData icon, String label, String? value) => ListTile(
          dense: true,
          leading: Icon(icon, size: 20),
          title: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
          subtitle: Text(value == null || value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
        );

    final brand = TeacherStyle.brand(context);
    final last = data.entries.isEmpty ? null : data.entries.first;
    final stats = <Widget>[
      StatCard(icon: Icons.mic_rounded, label: tr(context).stu.allRecitations, value: '${d.totalRecitations}', color: brand),
      StatCard(icon: Icons.date_range_rounded, label: tr(context).dash.thisWeek, value: '${d.thisWeek}', color: TeacherStyle.blue),
      StatCard(icon: Icons.local_fire_department_rounded, label: tr(context).stu.streak, value: '${d.currentStreak}', color: TeacherStyle.warning),
      StatCard(icon: Icons.how_to_reg_rounded, label: tr(context).stu.weeklyAttendance, value: d.weeklyAttendance == null ? '—' : '${d.weeklyAttendance}%', color: TeacherStyle.success),
    ];

    return RefreshIndicator(
      color: brand,
      onRefresh: () async => _reload(),
      child: CustomScrollView(slivers: [
        teacherHeader(
          context,
          title: d.fullName,
          expandedHeight: 210,
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: tr(context).stu.editDetails,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await context.push('/students/${widget.studentId}');
                if (mounted) _reload();
              },
            ),
          ],
          background: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(initialsOf(d.fullName), style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(fmt(tr(context).teach.pointsN, {'totalPoints': d.totalPoints}), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
                const SizedBox(height: 2),
                Text('${d.studentCode}${d.circleName == null ? '' : '  ·  ${d.circleName}'}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
              ]),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.9,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: stats,
          ),
          const SizedBox(height: 14),
          GoalCard(studentId: widget.studentId, studentName: d.fullName),
          if (!context.watch<TenantController>().isDisabled('wird')) WirdCard(studentId: widget.studentId),
          if (!context.watch<TenantController>().isDisabled('recitations')) MistakeStatsCard(studentId: widget.studentId),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => context.push('/weekly/${widget.studentId}'),
              icon: const Icon(Icons.insights_rounded, size: 18),
              label: Text(tr(context).weekly.open),
            ),
          ),
          if (last != null) ...[
            SectionTitle(tr(context).stu.lastRecitation),
            Builder(builder: (context) {
              final color = TeacherStyle.gradeColor(data.grades, last.grade);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.menu_book_rounded, color: color, size: 20)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(fmt(tr(context).stu.surahV, {'v': surahName(last.surah)}), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                      child: Text(gradeLabel[last.grade] ?? last.grade ?? '—', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text(fmt(tr(context).stu.recLine, {'type': kAchievementTypes[last.type] ?? last.type, 'ayahFrom': last.ayahFrom, 'ayahTo': last.ayahTo}), style: const TextStyle(color: TeacherStyle.textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(formatDate(last.createdAt), style: const TextStyle(color: TeacherStyle.textMuted, fontSize: 12)),
                  if (last.notes != null && last.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('"${last.notes}"', style: const TextStyle(color: TeacherStyle.textMuted, fontSize: 12.5, fontStyle: FontStyle.italic)),
                  ],
                ]),
              );
            }),
          ],
          SectionTitle(tr(context).stu.progress),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fmt(tr(context).stu.partsOf30, {'totalParts': d.totalParts}), style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(fmt(tr(context).stu.weeklyAttendanceV, {'v': d.weeklyAttendance == null ? '—' : '${d.weeklyAttendance}%'})),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: (d.totalParts / 30).clamp(0.0, 1.0).toDouble(), minHeight: 10),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fmt(tr(context).stu.statsLine, {'totalRecitations': d.totalRecitations, 'currentStreak': d.currentStreak, 'longestStreak': d.longestStreak, 'v': formatDate(d.lastRecitationAt)}),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
          SectionTitle(tr(context).stu.nextPlan),
          Card(
            child: ListTile(
              title: Text(d.nextPlan == null || d.nextPlan!.isEmpty ? tr(context).stu.noPlan : d.nextPlan!),
              trailing: IconButton(icon: const Icon(Icons.edit_note_rounded), onPressed: () => _editPlan(d)),
            ),
          ),
          SectionTitle(tr(context).stu.contact),
          Card(
            child: Column(
              children: [
                info(Icons.school_rounded, tr(context).stu.sheikh, d.teacherName),
                info(Icons.stairs_rounded, tr(context).stu.stage, d.stageName),
                info(Icons.phone_outlined, tr(context).stu.phone2, d.phone),
                info(Icons.home_outlined, tr(context).stu.addressLabel, d.address),
              ],
            ),
          ),
          if (context.read<TenantController>().active?.role == OrgRole.admin) ...[
            SectionTitle(tr(context).stu.guardian),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.guardianMemberId == null
                          ? tr(context).stu.noGuardian
                          : fmt(tr(context).stu.linkedTo, {'v': data.guardians.where((g) => g.id == data.guardianMemberId).map((g) => g.fullName ?? g.email).firstOrNull ?? '—'}),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (data.guardianMemberId == null)
                          FilledButton.tonalIcon(
                            onPressed: _createGuardian,
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: Text(tr(context).stu.newAccount),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => _pickGuardian(data),
                          icon: const Icon(Icons.link_rounded),
                          label: Text(tr(context).stu.linkExisting),
                        ),
                        if (data.guardianMemberId != null)
                          TextButton(onPressed: () => _linkGuardian(null), child: Text(tr(context).stu.unlink)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          SectionTitle(tr(context).nav.items['/serd']!),
          SerdSummaryCard(summary: data.serd),
          StudentNotesSection(orgId: _orgId, studentId: widget.studentId),
          SectionTitle(tr(context).stu.log),
          if (data.entries.isEmpty)
            Padding(padding: EdgeInsets.all(12), child: Text(tr(context).stu.noRecitations, style: TextStyle(color: TeacherStyle.textMuted)))
          else
            for (final e in data.entries)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: TeacherStyle.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: TeacherStyle.border)),
                child: Row(children: [
                  Container(width: 6, height: 42, decoration: BoxDecoration(color: TeacherStyle.gradeColor(data.grades, e.grade), borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${surahName(e.surah)} (${e.ayahFrom}–${e.ayahTo})', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text('${kAchievementTypes[e.type] ?? e.type} • ${formatDate(e.createdAt)}${e.notes == null ? '' : ' • ${e.notes}'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: TeacherStyle.textMuted, fontSize: 11.5)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(gradeLabel[e.grade] ?? e.grade ?? '', style: TextStyle(color: TeacherStyle.gradeColor(data.grades, e.grade), fontWeight: FontWeight.bold, fontSize: 12)),
                    if (e.pending)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.cloud_upload_outlined, size: 13, color: TeacherStyle.warning),
                        const SizedBox(width: 3),
                        Text(tr(context).ui.waitingUpload, style: const TextStyle(color: TeacherStyle.warning, fontSize: 10.5, fontWeight: FontWeight.w700)),
                      ])
                    else
                      Text('+${e.points}', style: const TextStyle(color: TeacherStyle.success, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ]),
                  // recorded on this phone: it can be changed once it has uploaded
                  if (e.id.startsWith('local-'))
                    const SizedBox(width: 12)
                  else
                  PopupMenuButton<String>(
                    onSelected: (v) => v == 'edit' ? _edit(data, e) : _delete(e),
                    itemBuilder: (context) => [PopupMenuItem(value: 'edit', child: Text(tr(context).common.edit)), PopupMenuItem(value: 'delete', child: Text(tr(context).common.delete))],
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: TeacherStyle.textMuted),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
