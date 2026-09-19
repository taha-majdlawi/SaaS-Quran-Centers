import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'circle_challenges_repository.dart';

final _dateFormat = DateFormat('yyyy-MM-dd');

class ChallengeFormScreen extends StatefulWidget {
  const ChallengeFormScreen({super.key});

  @override
  State<ChallengeFormScreen> createState() => _ChallengeFormScreenState();
}

class _ChallengeFormScreenState extends State<ChallengeFormScreen> {
  final _repository = CircleChallengesRepository(AppSupabase.client);
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _metricController = TextEditingController();
  DateTime? _startsOn;
  DateTime? _endsOn;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _metricController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startsOn : _endsOn) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => isStart ? _startsOn = picked : _endsOn = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startsOn == null || _endsOn == null) {
      setState(() => _error = 'يجب تحديد تاريخ البداية والنهاية');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final orgId = context.read<TenantController>().active!.organization.id;
      await _repository.createChallenge(
        organizationId: orgId,
        title: _titleController.text.trim(),
        metric: _metricController.text.trim(),
        startsOn: _dateFormat.format(_startsOn!),
        endsOn: _dateFormat.format(_endsOn!),
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
      appBar: AppBar(title: const Text('منافسة جديدة')),
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
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  hintText: 'منافسة الحفظ الشهرية',
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _metricController,
                decoration: const InputDecoration(
                  labelText: 'المعيار',
                  hintText: 'عدد الأجزاء المحفوظة',
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _pickDate(true),
                icon: const Icon(Icons.event),
                label: Text(_startsOn == null ? 'تاريخ البداية' : _dateFormat.format(_startsOn!)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _pickDate(false),
                icon: const Icon(Icons.event),
                label: Text(_endsOn == null ? 'تاريخ النهاية' : _dateFormat.format(_endsOn!)),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('إضافة المنافسة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
