import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import '../engagement/engagement_models.dart';
import '../engagement/engagement_repository.dart';

/// Admin: create / edit a challenge.
class ChallengeFormScreen extends StatefulWidget {
  const ChallengeFormScreen({super.key, this.challenge});

  final Challenge? challenge;

  @override
  State<ChallengeFormScreen> createState() => _ChallengeFormScreenState();
}

class _ChallengeFormScreenState extends State<ChallengeFormScreen> {
  final _repository = EngagementRepository(AppSupabase.client);
  late final _title = TextEditingController(text: widget.challenge?.title ?? '');
  late final _description = TextEditingController(text: widget.challenge?.description ?? '');
  late String _metric = widget.challenge?.metric ?? 'points';
  late DateTime _start = widget.challenge == null ? DateTime.now() : DateTime.parse(widget.challenge!.startsOn);
  late DateTime _end = widget.challenge == null ? DateTime.now().add(const Duration(days: 7)) : DateTime.parse(widget.challenge!.endsOn);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final p = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (p != null) setState(() => start ? _start = p : _end = p);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'عنوان المنافسة مطلوب');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.saveChallenge(
        context.read<TenantController>().active!.organization.id,
        id: widget.challenge?.id,
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        metric: _metric,
        starts: _start,
        ends: _end,
      );
      if (mounted) context.pop(true);
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String d(DateTime v) => '${v.year}/${v.month}/${v.day}';
    return Scaffold(
      appBar: AppBar(title: Text(widget.challenge == null ? 'منافسة جديدة' : 'تعديل المنافسة')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) MessageBanner(message: _error!),
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'العنوان')),
          const SizedBox(height: 12),
          TextField(controller: _description, maxLines: 2, decoration: const InputDecoration(labelText: 'الوصف')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _metric,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'المقياس'),
            items: [for (final e in kMetricLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => _metric = v ?? 'points'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => _pick(true), child: Text('من: ${d(_start)}'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => _pick(false), child: Text('إلى: ${d(_end)}'))),
          ]),
          const SizedBox(height: 20),
          LoadingButton(label: 'حفظ', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
