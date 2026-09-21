import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/data/quran_data.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import '../recitation/recitation_repository.dart';
import 'gatherings_repository.dart';
import 'student_picker.dart';

const _types = {'new_memorization': 'حفظ جديد', 'recent_review': 'مراجعة قريبة', 'distant_review': 'مراجعة بعيدة'};

/// A recitation heard from a student outside the teacher's circle: recorded by name, linked by the admin.
class ExternalRecitationsScreen extends StatefulWidget {
  const ExternalRecitationsScreen({super.key});

  @override
  State<ExternalRecitationsScreen> createState() => _ExternalRecitationsScreenState();
}

class _ExternalRecitationsScreenState extends State<ExternalRecitationsScreen> {
  final _repository = GatheringsRepository(AppSupabase.client);
  Future<List<Map<String, dynamic>>>? _future;
  String? _orgId;
  bool _admin = false;
  List<GradeOption> _grades = const [];

  void _reload() => setState(() => _future = _repository.externals(_orgId!, admin: _admin));

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _guard(Future<String?> Function() action) async {
    try {
      final msg = await action();
      if (!mounted) return;
      if (msg != null) _snack(msg);
      _reload();
    } on PostgrestException catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack('تعذّر تنفيذ العملية — تحقّق من الاتصال');
    }
  }

  Future<void> _create() async {
    if (_grades.isEmpty) _grades = await RecitationRepository(AppSupabase.client).fetchGrades(_orgId!);
    if (!mounted || _grades.isEmpty) return;
    final name = TextEditingController();
    final from = TextEditingController(text: '1');
    final to = TextEditingController(text: '1');
    final notes = TextEditingController();
    var type = 'new_memorization';
    var grade = _grades.first.key;
    var surah = 1;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('تسميع خارجي', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم الطالب')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'النوع'),
                items: [for (final e in _types.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setLocal(() => type = v ?? type),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: surah,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'السورة'),
                items: [for (var i = 1; i <= 114; i++) DropdownMenuItem(value: i, child: Text('$i. ${surahName(i)}'))],
                onChanged: (v) => setLocal(() => surah = v ?? surah),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: from, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'من آية'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: to, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'إلى آية'))),
              ]),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: grade,
                decoration: const InputDecoration(labelText: 'التقدير'),
                items: [for (final g in _grades) DropdownMenuItem(value: g.key, child: Text(g.label))],
                onChanged: (v) => setLocal(() => grade = v ?? grade),
              ),
              const SizedBox(height: 10),
              TextField(controller: notes, decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)')),
              const SizedBox(height: 14),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('رفع التسميع')),
            ]),
          ),
        ),
      ),
    );
    if (ok != true) return;
    await _guard(() async {
      await _repository.submitExternal(_orgId!,
          name: name.text.trim(),
          type: type,
          surah: surah,
          from: int.tryParse(from.text) ?? 1,
          to: int.tryParse(to.text) ?? 1,
          grade: grade,
          notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
          clientRef: const Uuid().v4());
      return 'رُفع التسميع وينتظر ربط المشرف';
    });
  }

  Future<void> _match(Map<String, dynamic> r, [String? studentId]) async {
    final student = studentId ?? await pickStudent(context, _orgId!, initialQuery: '${r['raw_student_name']}');
    if (student == null) return;
    await _guard(() async => 'رُبط التسميع وسُجّل للطالب (+${await _repository.matchExternal(r['id'] as String, student)} نقطة)');
  }

  Future<void> _reject(Map<String, dynamic> r) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: TextField(controller: c, decoration: const InputDecoration(hintText: 'السبب (اختياري)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('رفض')),
        ],
      ),
    );
    if (ok == true) {
      await _guard(() async {
        await _repository.rejectExternal(r['id'] as String, c.text.trim().isEmpty ? null : c.text.trim());
        return 'رُفض الطلب';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final orgId = tenant.active?.organization.id;
    if (orgId != null && orgId != _orgId) {
      _orgId = orgId;
      _admin = tenant.active?.role == OrgRole.admin;
      _future = _repository.externals(orgId, admin: _admin);
    }
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('التسميع الخارجي')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add_rounded), label: const Text('تسميع جديد')),
      body: _future == null
          ? const SizedBox.shrink()
          : AsyncBody<List<Map<String, dynamic>>>(
              future: _future!,
              onRetry: _reload,
              builder: (context, list) => RefreshIndicator(
                onRefresh: () async => _reload(),
                child: list.isEmpty
                    ? ListView(children: const [SizedBox(height: 80), EmptyState(icon: Icons.record_voice_over_rounded, title: 'لا طلبات بعد')])
                    : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), children: [
                        for (final r in list)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text('${r['raw_student_name']}', style: const TextStyle(fontWeight: FontWeight.w800))),
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    side: BorderSide.none,
                                    backgroundColor: (r['status'] == 'matched' ? Colors.green : r['status'] == 'rejected' ? Colors.red : Colors.amber).withValues(alpha: 0.18),
                                    label: Text(r['status'] == 'matched' ? 'رُبط' : r['status'] == 'rejected' ? 'مرفوض' : 'بانتظار الربط', style: const TextStyle(fontSize: 11)),
                                  ),
                                ]),
                                Text('${_types[r['type']] ?? r['type']} · ${surahName((r['surah'] as num).toInt())} (${r['ayah_from']}–${r['ayah_to']}) · ${r['grade']}${r['teacher_name'] != null ? ' · ${r['teacher_name']}' : ''}',
                                    style: TextStyle(color: scheme.outline, fontSize: 12.5)),
                                if (r['status'] == 'matched' && r['matched_name'] != null) Text('رُبط بـ ${r['matched_name']}', style: const TextStyle(color: Colors.green, fontSize: 12.5)),
                                if (r['reject_reason'] != null) Text('السبب: ${r['reject_reason']}', style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                                if (_admin && r['status'] == 'pending') ...[
                                  const SizedBox(height: 8),
                                  Wrap(spacing: 6, runSpacing: 4, children: [
                                    for (final s in (r['suggestions'] as List? ?? const []))
                                      ActionChip(
                                        label: Text('${s['full_name']}${s['circle'] != null ? ' · ${s['circle']}' : ''} (${((s['score'] as num) * 100).round()}%)', style: const TextStyle(fontSize: 11.5)),
                                        onPressed: () => _match(r, s['student_id'] as String),
                                      ),
                                    ActionChip(avatar: const Icon(Icons.search_rounded, size: 16), label: const Text('اختيار طالب'), onPressed: () => _match(r)),
                                    ActionChip(label: const Text('رفض'), onPressed: () => _reject(r)),
                                  ]),
                                ],
                                if (_admin ? r['status'] != 'matched' : r['status'] == 'pending')
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: TextButton(
                                      onPressed: () => _guard(() async {
                                        await _repository.deleteExternal(r['id'] as String);
                                        return 'حُذف الطلب';
                                      }),
                                      child: const Text('حذف'),
                                    ),
                                  ),
                              ]),
                            ),
                          ),
                      ]),
              ),
            ),
    );
  }
}
