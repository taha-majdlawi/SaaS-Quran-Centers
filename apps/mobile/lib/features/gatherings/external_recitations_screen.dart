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
import '../../core/i18n/i18n.dart';

Map<String, String> get _types => currentStrings.labels.recitationType;

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
      if (mounted) _snack(tr(context).gather.actionFailed);
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
              Text(tr(context).gather.extNew, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(controller: name, decoration: InputDecoration(labelText: tr(context).gather.studentName)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: InputDecoration(labelText: tr(context).gather.type),
                items: [for (final e in _types.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setLocal(() => type = v ?? type),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: surah,
                isExpanded: true,
                decoration: InputDecoration(labelText: tr(context).gather.surah),
                items: [for (var i = 1; i <= 114; i++) DropdownMenuItem(value: i, child: Text('$i. ${surahName(i)}'))],
                onChanged: (v) => setLocal(() => surah = v ?? surah),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(controller: from, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr(context).gather.fromAyah))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: to, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr(context).gather.toAyah))),
              ]),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: grade,
                decoration: InputDecoration(labelText: tr(context).gather.grade),
                items: [for (final g in _grades) DropdownMenuItem(value: g.key, child: Text(g.label))],
                onChanged: (v) => setLocal(() => grade = v ?? grade),
              ),
              const SizedBox(height: 10),
              TextField(controller: notes, decoration: InputDecoration(labelText: tr(context).serd.notesOpt)),
              const SizedBox(height: 14),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(context).gather.extUpload)),
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
      return currentStrings.gather.extUploaded;
    });
  }

  Future<void> _match(Map<String, dynamic> r, [String? studentId]) async {
    final student = studentId ?? await pickStudent(context, _orgId!, initialQuery: '${r['raw_student_name']}');
    if (student == null) return;
    await _guard(() async => fmt(currentStrings.gather.extLinked, {'v': await _repository.matchExternal(r['id'] as String, student)}));
  }

  Future<void> _reject(Map<String, dynamic> r) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).gather.rejectTitle),
        content: TextField(controller: c, decoration: InputDecoration(hintText: tr(context).gather.reasonOpt)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).common.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(context).gather.reject)),
        ],
      ),
    );
    if (ok == true) {
      await _guard(() async {
        await _repository.rejectExternal(r['id'] as String, c.text.trim().isEmpty ? null : c.text.trim());
        return currentStrings.gather.rejected;
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
      appBar: AppBar(title: Text(tr(context).nav.items['/external-recitations']!)),
      floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: Icon(Icons.add_rounded), label: Text(tr(context).gather.extNewShort)),
      body: _future == null
          ? const SizedBox.shrink()
          : AsyncBody<List<Map<String, dynamic>>>(
              future: _future!,
              onRetry: _reload,
              builder: (context, list) => RefreshIndicator(
                onRefresh: () async => _reload(),
                child: list.isEmpty
                    ? ListView(children: [SizedBox(height: 80), EmptyState(icon: Icons.record_voice_over_rounded, title: tr(context).gather.noRequests)])
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
                                    label: Text(r['status'] == 'matched' ? tr(context).gather.linked : r['status'] == 'rejected' ? tr(context).gather.rejectedChip : tr(context).gather.pending, style: const TextStyle(fontSize: 11)),
                                  ),
                                ]),
                                Text('${_types[r['type']] ?? r['type']} · ${surahName((r['surah'] as num).toInt())} (${r['ayah_from']}–${r['ayah_to']}) · ${r['grade']}${r['teacher_name'] != null ? ' · ${r['teacher_name']}' : ''}',
                                    style: TextStyle(color: scheme.outline, fontSize: 12.5)),
                                if (r['status'] == 'matched' && r['matched_name'] != null) Text(fmt(tr(context).gather.linkedTo, {'matched_name': r['matched_name']}), style: const TextStyle(color: Colors.green, fontSize: 12.5)),
                                if (r['reject_reason'] != null) Text(fmt(tr(context).gather.reasonV, {'reject_reason': r['reject_reason']}), style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                                if (_admin && r['status'] == 'pending') ...[
                                  const SizedBox(height: 8),
                                  Wrap(spacing: 6, runSpacing: 4, children: [
                                    for (final s in (r['suggestions'] as List? ?? const []))
                                      ActionChip(
                                        label: Text('${s['full_name']}${s['circle'] != null ? ' · ${s['circle']}' : ''} (${((s['score'] as num) * 100).round()}%)', style: const TextStyle(fontSize: 11.5)),
                                        onPressed: () => _match(r, s['student_id'] as String),
                                      ),
                                    ActionChip(avatar: Icon(Icons.search_rounded, size: 16), label: Text(tr(context).gather.pickStudent), onPressed: () => _match(r)),
                                    ActionChip(label: Text(tr(context).gather.reject), onPressed: () => _reject(r)),
                                  ]),
                                ],
                                if (_admin ? r['status'] != 'matched' : r['status'] == 'pending')
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: TextButton(
                                      onPressed: () => _guard(() async {
                                        await _repository.deleteExternal(r['id'] as String);
                                        return currentStrings.gather.deletedReq;
                                      }),
                                      child: Text(tr(context).common.delete),
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
