import 'package:flutter/material.dart';
import '../../core/widgets/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'stages_repository.dart';
import '../../core/i18n/i18n.dart';

class StageFormScreen extends StatefulWidget {
  const StageFormScreen({super.key, this.stageId});

  final String? stageId;

  bool get isEditing => stageId != null;

  @override
  State<StageFormScreen> createState() => _StageFormScreenState();
}

class _StageFormScreenState extends State<StageFormScreen> {
  final _repository = StagesRepository(AppSupabase.client);
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _sortOrderController = TextEditingController(text: '0');
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
      final stage = await _repository.fetchStage(widget.stageId!);
      if (stage != null) {
        _nameController.text = stage.name;
        _codeController.text = stage.code ?? '';
        _sortOrderController.text = stage.sortOrder.toString();
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final code = _codeController.text.trim().isEmpty ? null : _codeController.text.trim();
    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;

    try {
      if (widget.isEditing) {
        await _repository.updateStage(id: widget.stageId!, name: _nameController.text.trim(), code: code, sortOrder: sortOrder);
      } else {
        final orgId = context.read<TenantController>().active!.organization.id;
        await _repository.createStage(organizationId: orgId, name: _nameController.text.trim(), code: code, sortOrder: sortOrder);
      }
      if (mounted) context.pop();
    } catch (e) {
      final isDuplicate = e.toString().contains('23505');
      setState(() => _error = isDuplicate ? tr(context).org.stageTaken : friendlyError(e, tr(context).stu.saveError));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).org.deleteStage),
        content: Text(tr(context).org.deleteStageBody),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: Text(tr(context).common.cancel)),
          TextButton(onPressed: () => context.pop(true), child: Text(tr(context).common.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.deleteStage(widget.stageId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? tr(context).org.editStage : tr(context).org.addStage),
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
                    if (_error != null) MessageBanner(message: _error!),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: tr(context).org.stageName,
                        hintText: tr(context).org.stageNamePh,
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? tr(context).mem.required : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: tr(context).org.stageCode,
                        hintText: 'TM',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sortOrderController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: tr(context).org.stageOrder),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.isEditing ? tr(context).stu.saveChanges : tr(context).org.addStageBtn),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
