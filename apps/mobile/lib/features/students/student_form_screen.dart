import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import 'students_list_screen.dart' show kStudentStatusLabels;
import 'students_repository.dart';

final _dateFormat = DateFormat('yyyy-MM-dd');

/// One screen for both add and edit - mirrors apps/web's students/new and
/// students/[id]: pick a stage, then one of ITS circles (required), and the
/// student code is suggested from the stage code + running number.
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

  List<StageChoice> _stages = [];
  List<CircleOption> _circles = [];
  String? _stageId;
  String? _circleId;
  DateTime? _birthDate;
  String _status = 'active';
  bool _loading = true;
  bool _submitting = false;
  bool _suggestingCode = false;
  String? _error;

  List<CircleOption> get _visibleCircles =>
      _stageId == null ? _circles : _circles.where((c) => c.stageId == _stageId).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orgId = context.read<TenantController>().active!.organization.id;
    final results = await Future.wait<dynamic>([
      _repository.fetchCircles(orgId),
      _repository.fetchStages(orgId),
    ]);
    _circles = results[0] as List<CircleOption>;
    _stages = results[1] as List<StageChoice>;

    if (widget.isEditing) {
      final student = await _repository.fetchStudent(widget.studentId!);
      if (student != null) {
        _fullNameController.text = student.fullName;
        _studentCodeController.text = student.studentCode;
        _circleId = student.circleId;
        _status = student.status;
        _birthDate = student.birthDate != null ? DateTime.tryParse(student.birthDate!) : null;
        _stageId = _circles.where((c) => c.id == student.circleId).map((c) => c.stageId).firstOrNull;
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

  Future<void> _onStageChanged(String? stageId) async {
    setState(() {
      _stageId = stageId;
      if (!_visibleCircles.any((c) => c.id == _circleId)) _circleId = null;
    });
    if (widget.isEditing || stageId == null) return;

    setState(() => _suggestingCode = true);
    try {
      final orgId = context.read<TenantController>().active!.organization.id;
      final code = await _repository.nextStudentCode(orgId, stageId);
      if (code != null && mounted) _studentCodeController.text = code;
    } catch (_) {
      // Suggestion is a convenience only - the code can still be typed by hand.
    } finally {
      if (mounted) setState(() => _suggestingCode = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(DateTime.now().year - 10),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
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
      final birth = _birthDate != null ? _dateFormat.format(_birthDate!) : null;
      if (widget.isEditing) {
        await _repository.updateStudent(
          id: widget.studentId!,
          fullName: _fullNameController.text.trim(),
          studentCode: _studentCodeController.text.trim(),
          circleId: _circleId!,
          status: _status,
          birthDate: birth,
        );
      } else {
        await _repository.createStudent(
          organizationId: orgId,
          fullName: _fullNameController.text.trim(),
          studentCode: _studentCodeController.text.trim(),
          circleId: _circleId!,
          birthDate: birth,
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
        content: const Text('سيتم حذف الطالب وكل ملفه (الحضور، السرد، النقاط...). لا يمكن التراجع.'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text('حذف', style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _repository.deleteStudent(widget.studentId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final circles = _visibleCircles;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'تعديل بيانات طالب' : 'إضافة طالب'),
        actions: [
          if (widget.isEditing) IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete),
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
                    const SectionTitle('بيانات الطالب'),
                    TextFormField(
                      controller: _fullNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل اسم الطالب' : null,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickBirthDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'تاريخ الميلاد (اختياري)',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                        child: Text(_birthDate == null ? 'اضغط للاختيار' : _dateFormat.format(_birthDate!)),
                      ),
                    ),
                    const SectionTitle('المرحلة والحلقة'),
                    if (_stages.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _stageId,
                        decoration: const InputDecoration(labelText: 'المرحلة', prefixIcon: Icon(Icons.stairs_outlined)),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('كل المراحل')),
                          ..._stages.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                        ],
                        onChanged: _onStageChanged,
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<String>(
                      key: ValueKey('circle-${_stageId ?? 'all'}'),
                      initialValue: circles.any((c) => c.id == _circleId) ? _circleId : null,
                      decoration: const InputDecoration(labelText: 'الحلقة (مطلوب)', prefixIcon: Icon(Icons.groups_outlined)),
                      items: circles.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (value) => setState(() => _circleId = value),
                    ),
                    if (circles.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, right: 4),
                        child: Text('لا توجد حلقات هنا - أنشئ حلقة أولًا من قسم الحلقات',
                            style: TextStyle(color: Colors.orange.shade800, fontSize: 12.5)),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _studentCodeController,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'رقم الطالب',
                        helperText: widget.isEditing ? null : 'يُقترح تلقائيًا عند اختيار المرحلة، ويمكنك تعديله',
                        prefixIcon: const Icon(Icons.tag_rounded),
                        suffixIcon: _suggestingCode
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : null,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل رقم الطالب' : null,
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'الحالة', prefixIcon: Icon(Icons.flag_outlined)),
                        items: kStudentStatusLabels.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (value) => setState(() => _status = value ?? _status),
                      ),
                    ],
                    const SizedBox(height: 28),
                    LoadingButton(
                      label: widget.isEditing ? 'حفظ التعديلات' : 'إضافة الطالب',
                      loading: _submitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
