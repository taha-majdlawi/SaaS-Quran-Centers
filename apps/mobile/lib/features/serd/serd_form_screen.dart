import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'serd_repository.dart';

/// One screen for both scheduling (create) and grading (edit) - mirrors
/// apps/web's serd/new and serd/[id] pages, which deliberately expose
/// different fields at each stage (create: student + type + when;
/// edit: status/examiner/grade/notes, no student/type - those don't change).
class SerdFormScreen extends StatefulWidget {
  const SerdFormScreen({super.key, this.sessionId});

  final String? sessionId;

  bool get isEditing => sessionId != null;

  @override
  State<SerdFormScreen> createState() => _SerdFormScreenState();
}

class _SerdFormScreenState extends State<SerdFormScreen> {
  final _repository = SerdRepository(AppSupabase.client);
  final _formKey = GlobalKey<FormState>();
  final _gradeController = TextEditingController();
  final _notesController = TextEditingController();

  List<SerdStudentOption> _students = [];
  List<SerdStaffOption> _staff = [];
  String? _studentId;
  String _sessionType = 'partial';
  String _status = 'pending';
  String? _examinerId;
  DateTime? _scheduledAt;
  String _studentName = '';
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orgId = context.read<TenantController>().active!.organization.id;

    if (widget.isEditing) {
      final results = await Future.wait([
        _repository.fetchSession(widget.sessionId!),
        _repository.fetchStaff(orgId),
      ]);
      final session = results[0] as SerdSessionDetail?;
      _staff = results[1] as List<SerdStaffOption>;
      if (session != null) {
        _sessionType = session.sessionType;
        _status = session.status;
        _examinerId = session.examinerId;
        _scheduledAt = session.scheduledAt != null ? DateTime.tryParse(session.scheduledAt!) : null;
        _gradeController.text = session.overallGrade?.toString() ?? '';
        _notesController.text = session.notes ?? '';
        _studentName = session.studentName;
      }
    } else {
      _students = await _repository.fetchStudents(orgId);
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickScheduledAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!widget.isEditing && _studentId == null) {
      setState(() => _error = 'يجب اختيار الطالب');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final orgId = context.read<TenantController>().active!.organization.id;
      if (widget.isEditing) {
        final grade = _gradeController.text.trim().isEmpty ? null : num.tryParse(_gradeController.text.trim());
        await _repository.updateSession(
          id: widget.sessionId!,
          status: _status,
          examinerId: _examinerId,
          scheduledAt: _scheduledAt?.toIso8601String(),
          overallGrade: grade,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      } else {
        await _repository.createSession(
          organizationId: orgId,
          studentId: _studentId!,
          sessionType: _sessionType,
          scheduledAt: _scheduledAt?.toIso8601String(),
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = 'حدث خطأ أثناء الحفظ - حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف جلسة السرد'),
        content: const Text('متأكد إنك بدك تحذف جلسة السرد هذي؟ لا يمكن التراجع.'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => context.pop(true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;

    await _repository.deleteSession(widget.sessionId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'جلسة سرد - $_studentName' : 'جدولة جلسة سرد'),
        actions: [
          if (widget.isEditing)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!widget.isEditing) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _studentId,
                        decoration: const InputDecoration(labelText: 'الطالب', border: OutlineInputBorder()),
                        items: _students.map((s) => DropdownMenuItem(value: s.id, child: Text(s.fullName))).toList(),
                        onChanged: (value) => setState(() => _studentId = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _sessionType,
                        decoration: const InputDecoration(labelText: 'نوع السرد', border: OutlineInputBorder()),
                        items: kSerdTypeLabels.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (value) => setState(() => _sessionType = value ?? _sessionType),
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder()),
                        items: kSerdStatusLabels.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (value) => setState(() => _status = value ?? _status),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _examinerId,
                        decoration: const InputDecoration(labelText: 'الممتحن', border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('بدون تحديد')),
                          ..._staff.map((m) => DropdownMenuItem(value: m.userId, child: Text(m.label))),
                        ],
                        onChanged: (value) => setState(() => _examinerId = value),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickScheduledAt,
                      icon: const Icon(Icons.event),
                      label: Text(_scheduledAt == null ? 'حدد الموعد (اختياري)' : _scheduledAt.toString()),
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _gradeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'التقدير (من 10)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'ملاحظات', border: OutlineInputBorder()),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(widget.isEditing ? 'حفظ' : 'جدولة الجلسة'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
