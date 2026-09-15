import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'calendar_repository.dart';

/// Mirrors apps/web's calendar/[id] page: edit the event, delete it, and
/// manage its student registrations - all in one place.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _repository = CalendarRepository(AppSupabase.client);
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _startsAt;
  bool _requiresConsent = false;

  List<CalendarRegistration> _registrations = [];
  List<CalendarStudentOption> _students = [];
  String? _registerStudentId;

  bool _loading = true;
  bool _submitting = false;
  bool _registering = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orgId = context.read<TenantController>().active!.organization.id;
    final results = await Future.wait([
      _repository.fetchEvent(widget.eventId),
      _repository.fetchRegistrations(widget.eventId),
      _repository.fetchActiveStudents(orgId),
    ]);
    final event = results[0] as CalendarEventDetail?;
    _registrations = results[1] as List<CalendarRegistration>;
    _students = results[2] as List<CalendarStudentOption>;
    if (event != null) {
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _locationController.text = event.location ?? '';
      _startsAt = DateTime.tryParse(event.startsAt);
      _requiresConsent = event.requiresGuardianConsent;
    }
    if (mounted) setState(() => _loading = false);
  }

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
    if (!(_formKey.currentState?.validate() ?? false) || _startsAt == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repository.updateEvent(
        id: widget.eventId,
        title: _titleController.text.trim(),
        startsAt: _startsAt!.toIso8601String(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        requiresConsent: _requiresConsent,
      );
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
        title: const Text('حذف الفعالية'),
        content: Text('متأكد إنك بدك تحذف فعالية "${_titleController.text}"؟'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => context.pop(true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.deleteEvent(widget.eventId);
    if (mounted) context.pop();
  }

  Future<void> _register() async {
    if (_registerStudentId == null) return;
    setState(() {
      _registering = true;
      _error = null;
    });
    try {
      await _repository.registerStudent(eventId: widget.eventId, studentId: _registerStudentId!);
      _registrations = await _repository.fetchRegistrations(widget.eventId);
      if (mounted) setState(() => _registerStudentId = null);
    } catch (e) {
      final isDuplicate = e is PostgrestException && e.code == '23505';
      if (mounted) setState(() => _error = isDuplicate ? 'الطالب مسجّل بالفعالية من قبل' : 'حدث خطأ أثناء التسجيل');
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  Future<void> _cancelRegistration(String id) async {
    await _repository.cancelRegistration(id);
    _registrations = await _repository.fetchRegistrations(widget.eventId);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل فعالية'),
        actions: [IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                  ),
                  const SizedBox(height: 16),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                            : const Text('حفظ التعديلات'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 32),
                Text('المسجّلون (${_registrations.length})', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_registrations.isEmpty)
                  const Text('ما في تسجيلات بعد', style: TextStyle(color: Colors.grey))
                else
                  ..._registrations.map((r) => Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          title: Text(r.studentName),
                          trailing: TextButton(
                            onPressed: () => _cancelRegistration(r.id),
                            child: const Text('إلغاء', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      )),
                if (_students.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _registerStudentId,
                    decoration: const InputDecoration(labelText: 'تسجيل طالب', border: OutlineInputBorder()),
                    items: _students.map((s) => DropdownMenuItem(value: s.id, child: Text(s.fullName))).toList(),
                    onChanged: (v) => setState(() => _registerStudentId = v),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _registering ? null : _register,
                    child: _registering
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('تسجيل'),
                  ),
                ],
              ],
            ),
    );
  }
}
