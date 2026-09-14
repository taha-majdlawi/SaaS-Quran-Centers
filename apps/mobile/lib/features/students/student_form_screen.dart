import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'students_repository.dart';

const _statusOptions = {
  'active': 'نشط',
  'paused': 'متوقف',
  'graduated': 'تخرّج',
  'withdrawn': 'منسحب',
};

/// One screen for both add and edit - mirrors apps/web's students/new and
/// students/[id] pages, just merged since Flutter doesn't need two routes
/// to get two URLs the way Next.js does.
class StudentFormScreen extends StatefulWidget {
  const StudentFormScreen({super.key, this.studentId});

  final String? studentId;

  bool get isEditing => studentId != null;

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _repository = StudentsRepository(AppSupabase.client);
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _studentCodeController = TextEditingController();

  List<CircleOption> _circles = [];
  String? _circleId;
  String _status = 'active';
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
    _circles = await _repository.fetchCircles(orgId);

    if (widget.isEditing) {
      final student = await _repository.fetchStudent(widget.studentId!);
      if (student != null) {
        _fullNameController.text = student.fullName;
        _studentCodeController.text = student.studentCode;
        _circleId = student.circleId;
        _status = student.status;
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_circleId == null) {
      setState(() => _error = 'يجب اختيار حلقة للطالب');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final orgId = context.read<TenantController>().active!.organization.id;
      if (widget.isEditing) {
        await _repository.updateStudent(
          id: widget.studentId!,
          fullName: _fullNameController.text.trim(),
          studentCode: _studentCodeController.text.trim(),
          circleId: _circleId!,
          status: _status,
        );
      } else {
        await _repository.createStudent(
          organizationId: orgId,
          fullName: _fullNameController.text.trim(),
          studentCode: _studentCodeController.text.trim(),
          circleId: _circleId!,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = 'رقم الطالب مستخدم من قبل، أو حدث خطأ آخر');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الطالب'),
        content: const Text('متأكد إنك بدك تحذف هذا الطالب؟ لا يمكن التراجع.'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => context.pop(true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;

    await _repository.deleteStudent(widget.studentId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'تعديل بيانات طالب' : 'إضافة طالب'),
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
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _studentCodeController,
                      decoration: const InputDecoration(labelText: 'رقم الطالب', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _circleId,
                      decoration: const InputDecoration(labelText: 'الحلقة', border: OutlineInputBorder()),
                      items: _circles
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (value) => setState(() => _circleId = value),
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder()),
                        items: _statusOptions.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (value) => setState(() => _status = value ?? _status),
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
                          : Text(widget.isEditing ? 'حفظ التعديلات' : 'إضافة الطالب'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
