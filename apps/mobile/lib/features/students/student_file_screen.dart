import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/quran_data.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import '../my_portal/my_portal_repository.dart';
import '../recitation/recitation_repository.dart';
import '../recitation/recitation_sheet.dart';

class _FileData {
  const _FileData({required this.dashboard, required this.entries, required this.grades});
  final PortalDashboard dashboard;
  final List<RecitationEntry> entries;
  final List<GradeOption> grades;
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
    final results = await Future.wait<dynamic>([
      _portal.fetchDashboard(orgId, widget.studentId),
      _recitations.fetchStudentRecitations(widget.studentId),
      _recitations.fetchGrades(orgId),
    ]);
    final dashboard = results[0] as PortalDashboard?;
    if (dashboard == null) throw StateError('student not found');
    return _FileData(
      dashboard: dashboard,
      entries: results[1] as List<RecitationEntry>,
      grades: results[2] as List<GradeOption>,
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
      _toast('تم الحفظ ✓  +$points نقطة');
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
      _toast('تم تعديل التسميع');
      _reload();
    }
  }

  Future<void> _delete(RecitationEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف التسميع'),
        content: const Text('سيُحذف هذا التسميع وتُخصم نقاطه من رصيد الطالب. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _recitations.deleteRecitation(entry.id);
      if (mounted) {
        _toast('تم الحذف');
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
        title: const Text('الخطة القادمة'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'مثال: حفظ سورة الملك من الآية 1 إلى 15'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved == null) return;
    try {
      await _recitations.setStudentPlan(orgId: _orgId, studentId: widget.studentId, plan: saved);
      if (mounted) {
        _toast('تم حفظ الخطة');
        _reload();
      }
    } on PostgrestException catch (e) {
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
          appBar: AppBar(
            title: Text(data?.dashboard.fullName ?? 'ملف الطالب'),
            actions: [
              IconButton(
                tooltip: 'تعديل البيانات',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await context.push('/students/${widget.studentId}');
                  if (mounted) _reload();
                },
              ),
            ],
          ),
          floatingActionButton: data == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _addRecitation(data),
                  icon: const Icon(Icons.mic_none_rounded),
                  label: const Text('رصد تسميع'),
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
    final scheme = Theme.of(context).colorScheme;

    Widget info(IconData icon, String label, String? value) => ListTile(
          dense: true,
          leading: Icon(icon, size: 20),
          title: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
          subtitle: Text(value == null || value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
        );

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.fullName, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        '${d.studentCode}${d.circleName == null ? '' : '  ·  ${d.circleName}'}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text('${d.totalPoints}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    Text('نقطة', style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ],
            ),
          ),
          const SectionTitle('التقدّم'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${d.totalParts} من 30 جزءًا', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('الحضور الأسبوعي: ${d.weeklyAttendance == null ? '—' : '${d.weeklyAttendance}%'}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(value: (d.totalParts / 30).clamp(0.0, 1.0).toDouble(), minHeight: 10),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${d.totalRecitations} تسميعات  ·  سلسلة ${d.currentStreak} يوم (الأطول ${d.longestStreak})  ·  آخر تسميع ${formatDate(d.lastRecitationAt)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
          const SectionTitle('الخطة القادمة'),
          Card(
            child: ListTile(
              title: Text(d.nextPlan == null || d.nextPlan!.isEmpty ? 'لم تُحدَّد خطة بعد' : d.nextPlan!),
              trailing: IconButton(icon: const Icon(Icons.edit_note_rounded), onPressed: () => _editPlan(d)),
            ),
          ),
          const SectionTitle('بيانات التواصل'),
          Card(
            child: Column(
              children: [
                info(Icons.school_rounded, 'الشيخ', d.teacherName),
                info(Icons.stairs_rounded, 'المرحلة', d.stageName),
                info(Icons.phone_outlined, 'الجوال', d.phone),
                info(Icons.home_outlined, 'العنوان', d.address),
              ],
            ),
          ),
          const SectionTitle('سجل التسميع'),
          if (data.entries.isEmpty)
            const Padding(padding: EdgeInsets.all(12), child: Text('لا يوجد تسميعات بعد'))
          else
            for (final e in data.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    title: Text('${surahName(e.surah)}  (${e.ayahFrom}–${e.ayahTo})', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${kAchievementTypes[e.type] ?? e.type}  ·  ${gradeLabel[e.grade] ?? e.grade ?? '—'}  ·  ${formatDate(e.createdAt)}'
                      '${e.notes == null ? '' : '\n${e.notes}'}',
                    ),
                    isThreeLine: e.notes != null,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) => v == 'edit' ? _edit(data, e) : _delete(e),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('تعديل')),
                        PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
                      child: StatusChip(label: '+${e.points}', color: Colors.green),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
