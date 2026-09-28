import 'package:flutter/material.dart';
import '../../core/widgets/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'circles_repository.dart';
import '../../core/i18n/i18n.dart';

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
  Set<String> _assistants = {};
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
      try {
        _assistants = await _repository.fetchAssistants(orgId, widget.circleId!);
      } catch (_) {}
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
        await _repository.setAssistants(orgId, widget.circleId!, _assistants.where((u) => u != _teacherId).toSet());
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
      setState(() => _error = friendlyError(e, tr(context).org.saveErrorRetry));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).org.deleteCircle),
        content: Text(tr(context).org.deleteCircleBody),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: Text(tr(context).common.cancel)),
          TextButton(onPressed: () => context.pop(true), child: Text(tr(context).common.delete)),
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
        title: Text(widget.isEditing ? tr(context).org.editCircle : tr(context).org.addCircle),
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
                    if (_error != null) MessageBanner(message: _error!),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: tr(context).org.circleName),
                      validator: (v) => (v == null || v.isEmpty) ? tr(context).mem.required : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _stageId,
                      decoration: InputDecoration(labelText: tr(context).org.stage),
                      items: [
                        DropdownMenuItem(value: null, child: Text(tr(context).org.noStage)),
                        ..._stages.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                      ],
                      onChanged: (value) => setState(() => _stageId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _teacherId,
                      decoration: InputDecoration(labelText: tr(context).org.teacher),
                      items: [
                        DropdownMenuItem(value: null, child: Text(tr(context).org.noTeacher)),
                        ..._teachers.map((t) => DropdownMenuItem(value: t.userId, child: Text(t.label))),
                      ],
                      onChanged: (value) => setState(() => _teacherId = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: tr(context).org.capacity),
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: 16),
                      Text(tr(context).org.assistants, style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(tr(context).org.assistantsHint, style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        for (final t in _teachers.where((t) => t.userId != _teacherId))
                          FilterChip(
                            label: Text(t.label),
                            selected: _assistants.contains(t.userId),
                            onSelected: (v) => setState(() => v ? _assistants.add(t.userId) : _assistants.remove(t.userId)),
                          ),
                        if (_teachers.where((t) => t.userId != _teacherId).isEmpty) Text(tr(context).org.noOtherTeachers),
                      ]),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: InputDecoration(labelText: tr(context).org.status),
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
                          : Text(widget.isEditing ? tr(context).stu.saveChanges : tr(context).org.addCircleBtn),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
