import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import '../members/members_repository.dart';
import '../students/students_repository.dart';
import 'serd_models.dart';
import 'serd_repository.dart';
import 'serd_widgets.dart';

class _ScheduleData {
  const _ScheduleData({required this.setup, required this.students, required this.teachers});
  final SerdSetup setup;
  final List<StudentSummary> students;
  final List<MemberRow> teachers;
}

/// Admin schedules a serd task - open to any teacher, or assigned to one.
class SerdScheduleScreen extends StatefulWidget {
  const SerdScheduleScreen({super.key});

  @override
  State<SerdScheduleScreen> createState() => _SerdScheduleScreenState();
}

class _SerdScheduleScreenState extends State<SerdScheduleScreen> {
  final _repository = SerdRepository(AppSupabase.client);
  late final Future<_ScheduleData> _future = _load();
  final _notes = TextEditingController();
  String? _studentId;
  String? _teacherId;
  List<SerdPart> _parts = [];
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  String get _orgId => context.read<TenantController>().active!.organization.id;

  Future<_ScheduleData> _load() async {
    final orgId = _orgId;
    final results = await Future.wait<dynamic>([
      _repository.fetchSetup(orgId),
      StudentsRepository(AppSupabase.client).fetchStudents(orgId),
      MembersRepository(AppSupabase.client).fetchMembers(orgId),
    ]);
    return _ScheduleData(
      setup: results[0] as SerdSetup,
      students: results[1] as List<StudentSummary>,
      teachers: (results[2] as List<MemberRow>).where((m) => m.role == 'teacher' && m.status == 'active').toList(),
    );
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_studentId == null || _parts.isEmpty) {
      setState(() => _error = 'اختر الطالب وجزءًا واحدًا على الأقل');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.schedule(
        orgId: _orgId,
        studentId: _studentId!,
        parts: _parts,
        date: _date,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        teacherId: _teacherId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت جدولة السرد')));
        context.pop();
      }
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جدولة سرد')),
      body: AsyncBody<_ScheduleData>(
        future: _future,
        builder: (context, data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('مهمة تظهر للمعلمين ليرصدها من يتفرغ لها، أو تُسند لمعلم بعينه.', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 14),
            if (_error != null) MessageBanner(message: _error!),
            DropdownButtonFormField<String>(
              initialValue: _studentId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'الطالب'),
              items: [
                for (final s in data.students) DropdownMenuItem(value: s.id, child: Text('${s.fullName} (${s.studentCode})', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _studentId = v),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _date = picked);
              },
              icon: const Icon(Icons.event_rounded, size: 18),
              label: Text('الموعد: ${_date.year}/${_date.month}/${_date.day}'),
            ),
            const SectionTitle('الأجزاء المطلوبة'),
            SerdPartsEditor(denominators: data.setup.pickerDenominators, onChanged: (p) => _parts = p),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _teacherId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'إسناد إلى معلم'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('مفتوح لأي معلم')),
                for (final t in data.teachers) DropdownMenuItem<String?>(value: t.userId, child: Text(t.fullName ?? t.email ?? '—')),
              ],
              onChanged: (v) => setState(() => _teacherId = v),
            ),
            const SizedBox(height: 12),
            TextField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)')),
            const SizedBox(height: 20),
            LoadingButton(label: 'جدولة السرد', icon: Icons.event_available_rounded, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
