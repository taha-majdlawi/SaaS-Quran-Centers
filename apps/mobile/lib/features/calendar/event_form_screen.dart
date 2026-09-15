import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'calendar_repository.dart';

/// Create-only screen - mirrors apps/web's calendar/new page (editing lives
/// in event_detail_screen.dart alongside registrations, like calendar/[id]).
class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _repository = CalendarRepository(AppSupabase.client);
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _startsAt;
  bool _requiresConsent = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickStartsAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_startsAt ?? DateTime.now()));
    if (time == null) return;
    setState(() => _startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startsAt == null) {
      setState(() => _error = 'يجب تحديد التاريخ والوقت');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final orgId = context.read<TenantController>().active!.organization.id;
      final userId = context.read<AuthController>().currentUser?.id;
      await _repository.createEvent(
        organizationId: orgId,
        title: _titleController.text.trim(),
        startsAt: _startsAt!.toIso8601String(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        requiresConsent: _requiresConsent,
        createdBy: userId,
      );
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = 'حدث خطأ أثناء الإضافة - حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فعالية جديدة')),
      body: SingleChildScrollView(
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
                onPressed: _pickStartsAt,
                icon: const Icon(Icons.event),
                label: Text(_startsAt == null ? 'التاريخ والوقت' : _startsAt.toString()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'المكان', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تحتاج موافقة ولي الأمر (رحلة مثلًا)'),
                value: _requiresConsent,
                onChanged: (v) => setState(() => _requiresConsent = v ?? false),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('إضافة الفعالية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
