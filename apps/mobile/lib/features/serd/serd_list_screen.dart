import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/ui.dart';
import '../students/students_repository.dart';
import 'serd_models.dart';
import 'serd_repository.dart';
import 'serd_widgets.dart';

class _QueueData {
  const _QueueData({this.page, this.scheduled = const [], this.mine = const [], this.students = const []});
  final SerdListPage? page;
  final List<SerdRow> scheduled;
  final List<SerdRow> mine;
  final List<StudentSummary> students;
}

/// The serd hub. Admin: the approval queue (waiting work first) with filters.
/// Teacher: tasks waiting to be heard, plus what they graded themselves.
class SerdListScreen extends StatefulWidget {
  const SerdListScreen({super.key});

  @override
  State<SerdListScreen> createState() => _SerdListScreenState();
}

class _SerdListScreenState extends State<SerdListScreen> {
  final _repository = SerdRepository(AppSupabase.client);
  Future<_QueueData>? _future;
  String? _loadedForOrgId;
  String? _status;
  int _page = 1;

  bool get _isAdmin => context.read<TenantController>().active?.role == OrgRole.admin;

  Future<_QueueData> _load(String orgId) async {
    if (_isAdmin) {
      final results = await Future.wait<dynamic>([
        _repository.adminList(orgId, status: _status, page: _page),
        StudentsRepository(AppSupabase.client).fetchStudents(orgId),
      ]);
      return _QueueData(page: results[0] as SerdListPage, students: results[1] as List<StudentSummary>);
    }
    final results = await Future.wait<dynamic>([_repository.teacherScheduled(orgId), _repository.teacherMy(orgId)]);
    return _QueueData(scheduled: results[0] as List<SerdRow>, mine: results[1] as List<SerdRow>);
  }

  void _reload() => setState(() => _future = _load(_loadedForOrgId!));

  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
        _reload();
      }
    } on PostgrestException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _approve(SerdRow row, List<StudentSummary> students) async {
    String? studentId;
    if (row.studentId == null) {
      studentId = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('اربط السرد بطالب'),
          children: [
            SizedBox(
              height: 320,
              width: double.maxFinite,
              child: ListView(
                children: [
                  for (final s in students)
                    ListTile(
                      dense: true,
                      title: Text(s.fullName),
                      subtitle: Text(s.studentCode),
                      onTap: () => Navigator.pop(context, s.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
      if (studentId == null) return;
    }
    await _run(() => _repository.review(row.id, 'approve', studentId: studentId), 'تم الاعتماد');
  }

  Future<void> _reject(SerdRow row) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض السرد'),
        content: TextField(controller: reason, decoration: const InputDecoration(labelText: 'سبب الرفض (اختياري)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44), backgroundColor: Colors.red),
            child: const Text('رفض'),
          ),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (ok == true) await _run(() => _repository.review(row.id, 'reject', reason: text.isEmpty ? null : text), 'تم الرفض');
  }

  Future<void> _delete(SerdRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف السرد'),
        content: const Text('سيُحذف هذا السرد وتُخصم نقاطه إن كان معتمدًا. متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) await _run(() => _repository.delete(row.id), 'تم الحذف');
  }

  Widget? _adminActions(SerdRow row, List<StudentSummary> students) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (row.status == 'submitted') ...[
          FilledButton.icon(
            onPressed: () => _approve(row, students),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('اعتماد'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          ),
          OutlinedButton(
            onPressed: () => _reject(row),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), foregroundColor: Colors.red),
            child: const Text('رفض'),
          ),
        ],
        if (row.status == 'rejected' && row.scorePercent != null)
          OutlinedButton(
            onPressed: () => _approve(row, students),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
            child: const Text('إعادة اعتماد'),
          ),
        TextButton(onPressed: () => _delete(row), child: const Text('حذف', style: TextStyle(color: Colors.red))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final membership = context.watch<TenantController>().active;
    final orgId = membership?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _loadedForOrgId = orgId;
      _future = _load(orgId);
    }
    final isAdmin = membership?.role == OrgRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('السرد القرآني'),
        actions: [
          if (isAdmin)
            PopupMenuButton<String>(
              onSelected: (v) async {
                await context.push('/serd/$v');
                if (mounted) _reload();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'schedule', child: Text('جدولة سرد')),
                PopupMenuItem(value: 'report', child: Text('التقرير')),
                PopupMenuItem(value: 'settings', child: Text('الإعدادات')),
              ],
            ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/serd/new');
          if (mounted) _reload();
        },
        icon: const Icon(Icons.mic_none_rounded),
        label: const Text('رصد سرد'),
      ),
      body: _future == null
          ? const SizedBox.shrink()
          : AsyncBody<_QueueData>(
              future: _future!,
              onRetry: _reload,
              builder: (context, data) => RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  children: isAdmin ? _adminBody(data) : _teacherBody(data),
                ),
              ),
            ),
    );
  }

  List<Widget> _adminBody(_QueueData data) {
    final page = data.page!;
    const filters = [(null, 'الكل'), ('submitted', 'بانتظار الاعتماد'), ('scheduled', 'مجدول'), ('approved', 'معتمد'), ('rejected', 'مرفوض')];
    final pages = (page.total / 30).ceil().clamp(1, 1 << 30);
    return [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final f in filters)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(f.$2),
                  selected: _status == f.$1,
                  onSelected: (_) {
                    _status = f.$1;
                    _page = 1;
                    _reload();
                  },
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (page.rows.isEmpty) const Padding(padding: EdgeInsets.only(top: 60), child: EmptyState(icon: Icons.menu_book_outlined, title: 'لا يوجد سرد')),
      for (final r in page.rows)
        Padding(padding: const EdgeInsets.only(bottom: 10), child: SerdSessionCard(row: r, actions: _adminActions(r, data.students))),
      if (pages > 1)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: _page > 1 ? () { _page--; _reload(); } : null, icon: const Icon(Icons.chevron_right_rounded)),
            Text('$_page / $pages'),
            IconButton(onPressed: _page < pages ? () { _page++; _reload(); } : null, icon: const Icon(Icons.chevron_left_rounded)),
          ],
        ),
    ];
  }

  List<Widget> _teacherBody(_QueueData data) {
    return [
      if (data.scheduled.isNotEmpty) ...[
        SectionTitle('سرد مطلوب (${data.scheduled.length})'),
        for (final r in data.scheduled)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SerdSessionCard(
              row: r,
              actions: Row(
                children: [
                  Expanded(
                    child: Text(
                      r.assignedToMe ? 'مخصّص لك' : 'عام — أي معلم يستطيع رصده${r.overdue ? '  ·  متأخر' : ''}',
                      style: TextStyle(color: r.overdue ? Colors.red : Colors.grey.shade600, fontSize: 12.5),
                    ),
                  ),
                  FilledButton(
                    onPressed: () async {
                      await context.push('/serd/new?session=${r.id}');
                      if (mounted) _reload();
                    },
                    style: FilledButton.styleFrom(minimumSize: const Size(90, 40)),
                    child: const Text('رصد'),
                  ),
                ],
              ),
            ),
          ),
      ],
      const SectionTitle('سردي'),
      if (data.mine.isEmpty)
        const Padding(padding: EdgeInsets.all(12), child: Text('لم ترصد أي سرد بعد. استخدم زر «رصد سرد».')),
      for (final r in data.mine) Padding(padding: const EdgeInsets.only(bottom: 10), child: SerdSessionCard(row: r)),
    ];
  }
}
