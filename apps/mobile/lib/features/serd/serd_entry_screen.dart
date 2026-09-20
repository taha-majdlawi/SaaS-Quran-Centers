import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/offline/sync_service.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import '../students/students_repository.dart';
import 'serd_models.dart';
import 'serd_repository.dart';
import 'serd_widgets.dart';

class _EntryData {
  const _EntryData({required this.setup, required this.students, this.task});
  final SerdSetup setup;
  final List<StudentSummary> students;
  final SerdRow? task;
}

/// Grade a recital (eqraa's serd entry): pick the student (or type a name for
/// someone outside your circles), the juz and amount, count the mistakes. The
/// server computes the score; an admin approves it before it counts.
class SerdEntryScreen extends StatefulWidget {
  const SerdEntryScreen({super.key, this.sessionId});

  /// Set when completing a scheduled task.
  final String? sessionId;

  @override
  State<SerdEntryScreen> createState() => _SerdEntryScreenState();
}

class _SerdEntryScreenState extends State<SerdEntryScreen> {
  final _repository = SerdRepository(AppSupabase.client);
  late Future<_EntryData> _future;
  final _name = TextEditingController();
  final _notes = TextEditingController();
  final _counts = <String, int>{};
  StudentSummary? _student;
  List<SerdPart> _parts = [];
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  String get _orgId => context.read<TenantController>().active!.organization.id;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<_EntryData> _load() async {
    final orgId = _orgId;
    final results = await Future.wait<dynamic>([
      _repository.fetchSetup(orgId),
      StudentsRepository(AppSupabase.client).fetchStudents(orgId).catchError((_) => <StudentSummary>[]),
      widget.sessionId == null ? Future.value(<SerdRow>[]) : _repository.teacherScheduled(orgId),
    ]);
    final task = (results[2] as List<SerdRow>).where((r) => r.id == widget.sessionId).firstOrNull;
    if (task != null) _notes.text = task.notes ?? '';
    return _EntryData(setup: results[0] as SerdSetup, students: results[1] as List<StudentSummary>, task: task);
  }

  Future<void> _pickStudent(List<StudentSummary> students) async {
    final picked = await showModalBottomSheet<StudentSummary>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _StudentPicker(students: students),
    );
    if (picked != null) setState(() => _student = picked);
  }

  /// Live preview only - the stored score is computed by the server.
  num _previewScore(SerdSetup setup) {
    var deducted = 0.0;
    for (final t in setup.errorTypes) {
      final c = _counts[t.id] ?? 0;
      if (c > 0) deducted += c * t.percentPerUnit / t.errorsPerUnit;
    }
    return (100 - deducted).clamp(0, 100);
  }

  Future<void> _submit(_EntryData data) async {
    final task = data.task;
    if (task == null && _student == null && _name.text.trim().isEmpty) {
      setState(() => _error = 'اختر الطالب أو اكتب اسمه');
      return;
    }
    if (task == null && _parts.isEmpty) {
      setState(() => _error = 'اختر جزءًا واحدًا على الأقل');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final outcome = await _repository.submit(
        orgId: _orgId,
        studentId: task?.studentId ?? _student?.id,
        studentName: _student == null ? _name.text.trim() : null,
        parts: _parts.isEmpty ? task!.parts : _parts,
        date: _date,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        errors: _counts,
        sessionId: task?.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(outcome.queued ? kQueuedMessage : 'أُرسل للاعتماد ✓  الدرجة ${outcome.score ?? ''}%')));
      context.pop();
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'تعذّر الحفظ، تأكد من الإنترنت وحاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sessionId == null ? 'رصد سرد جديد' : 'رصد سرد مجدول')),
      body: FutureBuilder<_EntryData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(onRetry: () => setState(() => _future = _load()));
          }
          final data = snapshot.data;
          if (data == null) return const Center(child: CircularProgressIndicator());
          final task = data.task;
          final setup = data.setup;
          final score = _previewScore(setup);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null) MessageBanner(message: _error!),
              if (task != null)
                Card(
                  child: ListTile(
                    title: Text(task.studentName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(serdPartsLabel(task.parts)),
                  ),
                )
              else ...[
                OutlinedButton.icon(
                  onPressed: () => _pickStudent(data.students),
                  icon: const Icon(Icons.person_search_rounded),
                  label: Text(_student == null ? 'اختر الطالب' : '${_student!.fullName}  ·  ${_student!.studentCode}'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                ),
                if (_student == null) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'أو اكتب اسم الطالب (من خارج حلقاتك)',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                  ),
                ] else
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(onPressed: () => setState(() => _student = null), child: const Text('إلغاء الاختيار')),
                  ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text('تاريخ السرد: ${_date.year}/${_date.month}/${_date.day}'),
              ),
              const SectionTitle('الأجزاء المسرودة'),
              SerdPartsEditor(
                denominators: setup.pickerDenominators,
                initial: task?.parts ?? const [],
                onChanged: (p) => _parts = p,
              ),
              const SectionTitle('عدد الأخطاء'),
              for (final t in setup.errorTypes.where((t) => t.isActive))
                Card(
                  child: ListTile(
                    title: Text(t.name),
                    subtitle: Text('كل ${t.errorsPerUnit} = ${t.percentPerUnit}%'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: (_counts[t.id] ?? 0) > 0 ? () => setState(() => _counts[t.id] = (_counts[t.id] ?? 0) - 1) : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        SizedBox(
                          width: 28,
                          child: Text('${_counts[t.id] ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _counts[t.id] = (_counts[t.id] ?? 0) + 1),
                          icon: const Icon(Icons.add_circle_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (score >= setup.passPercent ? Colors.green : Colors.orange).shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'الدرجة المتوقعة: ${score.toStringAsFixed(score % 1 == 0 ? 0 : 2)}%  ·  حد النجاح ${setup.passPercent}%',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)', prefixIcon: Icon(Icons.edit_note_rounded)),
              ),
              const SizedBox(height: 20),
              LoadingButton(label: 'إرسال للاعتماد', icon: Icons.send_rounded, loading: _saving, onPressed: () => _submit(data)),
            ],
          );
        },
      ),
    );
  }
}

class _StudentPicker extends StatefulWidget {
  const _StudentPicker({required this.students});
  final List<StudentSummary> students;

  @override
  State<_StudentPicker> createState() => _StudentPickerState();
}

class _StudentPickerState extends State<_StudentPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final items = widget.students
        .where((s) => _query.isEmpty || s.fullName.contains(_query) || s.studentCode.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: const InputDecoration(hintText: 'ابحث باسم الطالب أو رقمه', prefixIcon: Icon(Icons.search_rounded)),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const EmptyState(icon: Icons.search_off_rounded, title: 'لا نتائج')
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: InitialAvatar(items[i].fullName),
                        title: Text(items[i].fullName),
                        subtitle: Text('${items[i].studentCode}  ·  ${items[i].circleName ?? 'بدون حلقة'}'),
                        onTap: () => Navigator.pop(context, items[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
