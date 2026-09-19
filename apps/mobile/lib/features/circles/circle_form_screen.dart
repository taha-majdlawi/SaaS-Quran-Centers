import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'circles_repository.dart';

/// One screen for both add and edit - mirrors apps/web's circles/new and
/// circles/[id] pages.
class CircleFormScreen extends StatefulWidget {
  const CircleFormScreen({super.key, this.circleId});

  final String? circleId;

  bool get isEditing => circleId != null;

  @override
  State<CircleFormScreen> createState() => _CircleFormScreenState();
}

class _CircleFormScreenState extends State<CircleFormScreen> {
  final _repository = CirclesRepository(AppSupabase.client);
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();

  List<StageOption> _stages = [];
  List<TeacherOption> _teachers = [];
  String? _stageId;
  String? _teacherId;
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
    final results = await Future.wait([
      _repository.fetchStages(orgId),
      _repository.fetchTeachers(orgId),
    ]);
    _stages = results[0] as List<StageOption>;
    _teachers = results[1] as List<TeacherOption>;

    if (widget.isEditing) {
      final circle = await _repository.fetchCircle(widget.circleId!);
      if (circle != null) {
        _nameController.text = circle.name;
        _capacityController.text = circle.capacity?.toString() ?? '';
        _stageId = circle.stageId;
        _teacherId = circle.teacherId;
        _status = circle.status;
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final capacity = _capacityController.text.trim().isEmpty ? null : int.tryParse(_capacityController.text.trim());

    try {
      final orgId = context.read<TenantController>().active!.organization.id;
      if (widget.isEditing) {
        await _repository.updateCircle(
          id: widget.circleId!,
          name: _nameController.text.trim(),
          status: _status,
          stageId: _stageId,
          teacherId: _teacherId,
          capacity: capacity,
        );
      } else {
        await _repository.createCircle(
          organizationId: orgId,
          name: _nameController.text.trim(),
          stageId: _stageId,
          teacherId: _teacherId,
          capacity: capacity,
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
        title: const Text('حذف الحلقة'),
        content: const Text('متأكد إنك بدك تحذف هذي الحلقة؟ لا يمكن التراجع.'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => context.pop(true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;

    await _repository.deleteCircle(widget.circleId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'تعديل الحلقة' : 'إضافة حلقة'),
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
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'اسم الحلقة'),
                      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _stageId,
                      decoration: const InputDecoration(labelText: 'المرحلة'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('بدون مرحلة')),
                        ..._stages.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                      ],
                      onChanged: (value) => setState(() => _stageId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _teacherId,
                      decoration: const InputDecoration(labelText: 'المعلم'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('بدون معلم')),
                        ..._teachers.map((t) => DropdownMenuItem(value: t.userId, child: Text(t.label))),
                      ],
                      onChanged: (value) => setState(() => _teacherId = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'السعة (عدد الطلاب)'),
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'الحالة'),
                        items: kCircleStatusLabels.entries
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
                          : Text(widget.isEditing ? 'حفظ التعديلات' : 'إضافة الحلقة'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
