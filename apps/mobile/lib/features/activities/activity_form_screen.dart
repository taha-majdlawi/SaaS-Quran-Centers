import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'activities_repository.dart';

class ActivityFormScreen extends StatefulWidget {
  const ActivityFormScreen({super.key, this.activityId});

  final String? activityId;

  bool get isEditing => activityId != null;

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _repository = ActivitiesRepository(AppSupabase.client);
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _scheduledAt;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.isEditing) {
      final activity = await _repository.fetchActivity(widget.activityId!);
      if (activity != null) {
        _titleController.text = activity.title;
        _descriptionController.text = activity.description ?? '';
        _scheduledAt = activity.scheduledAt != null ? DateTime.tryParse(activity.scheduledAt!) : null;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()));
    if (time == null) return;
    setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final description = _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();

    try {
      if (widget.isEditing) {
        await _repository.updateActivity(
          id: widget.activityId!,
          title: _titleController.text.trim(),
          description: description,
          scheduledAt: _scheduledAt?.toIso8601String(),
        );
      } else {
        final orgId = context.read<TenantController>().active!.organization.id;
        final userId = context.read<AuthController>().currentUser?.id;
        await _repository.createActivity(
          organizationId: orgId,
          title: _titleController.text.trim(),
          description: description,
          scheduledAt: _scheduledAt?.toIso8601String(),
          createdBy: userId,
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
        title: const Text('حذف النشاط'),
        content: const Text('متأكد إنك بدك تحذف هذا النشاط؟'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => context.pop(true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.deleteActivity(widget.activityId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'تعديل النشاط' : 'نشاط جديد'),
        actions: [if (widget.isEditing) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete)],
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
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickScheduledAt,
                      icon: const Icon(Icons.event),
                      label: Text(_scheduledAt == null ? 'الموعد (اختياري)' : _scheduledAt.toString()),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.isEditing ? 'حفظ التعديلات' : 'إضافة النشاط'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
