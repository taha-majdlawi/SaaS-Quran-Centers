import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'announcements_repository.dart';

class AnnouncementFormScreen extends StatefulWidget {
  const AnnouncementFormScreen({super.key, this.announcementId});

  final String? announcementId;

  bool get isEditing => announcementId != null;

  @override
  State<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends State<AnnouncementFormScreen> {
  final _repository = AnnouncementsRepository(AppSupabase.client);
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _audience = 'all';
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
      final announcement = await _repository.fetchAnnouncement(widget.announcementId!);
      if (announcement != null) {
        _titleController.text = announcement.title;
        _bodyController.text = announcement.body;
        _audience = announcement.audience;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      if (widget.isEditing) {
        await _repository.updateAnnouncement(
          id: widget.announcementId!,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          audience: _audience,
        );
      } else {
        final orgId = context.read<TenantController>().active!.organization.id;
        final userId = context.read<AuthController>().currentUser?.id;
        await _repository.createAnnouncement(
          organizationId: orgId,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          audience: _audience,
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
        title: const Text('حذف الإعلان'),
        content: const Text('متأكد إنك بدك تحذف هذا الإعلان؟'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => context.pop(true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.deleteAnnouncement(widget.announcementId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'تعديل الإعلان' : 'إعلان جديد'),
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
                      controller: _bodyController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'النص', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _audience,
                      decoration: const InputDecoration(labelText: 'الجمهور', border: OutlineInputBorder()),
                      items: kAnnouncementAudienceLabels.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _audience = v ?? _audience),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.isEditing ? 'حفظ التعديلات' : 'إضافة الإعلان'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
