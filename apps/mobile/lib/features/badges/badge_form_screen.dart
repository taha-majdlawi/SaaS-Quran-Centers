import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'badges_repository.dart';

class BadgeFormScreen extends StatefulWidget {
  const BadgeFormScreen({super.key, this.badgeId});

  final String? badgeId;

  bool get isEditing => badgeId != null;

  @override
  State<BadgeFormScreen> createState() => _BadgeFormScreenState();
}

class _BadgeFormScreenState extends State<BadgeFormScreen> {
  final _repository = BadgesRepository(AppSupabase.client);
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

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
      final badge = await _repository.fetchBadge(widget.badgeId!);
      if (badge != null) {
        _nameController.text = badge.name;
        _descriptionController.text = badge.description ?? '';
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
        await _repository.updateBadge(id: widget.badgeId!, name: _nameController.text.trim(), description: description);
      } else {
        final orgId = context.read<TenantController>().active!.organization.id;
        await _repository.createBadge(organizationId: orgId, name: _nameController.text.trim(), description: description);
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
        title: const Text('حذف الشارة'),
        content: const Text('متأكد إنك بدك تحذف هذي الشارة؟ لا يمكن التراجع.'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => context.pop(true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.deleteBadge(widget.badgeId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'تعديل الشارة' : 'إضافة شارة'),
        actions: [
          if (widget.isEditing) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
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
                      decoration: const InputDecoration(
                        labelText: 'اسم الشارة',
                        hintText: 'حافظ جزء',
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'الوصف'),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(widget.isEditing ? 'حفظ التعديلات' : 'إضافة الشارة'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
