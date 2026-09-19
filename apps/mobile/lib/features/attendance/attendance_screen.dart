import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import 'attendance_repository.dart';

final _dateFormat = DateFormat('yyyy-MM-dd');

/// One day-sheet per circle - mirrors apps/web's /attendance page: pick a
/// circle + date, mark every student, save as one upsert batch.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _repository = AttendanceRepository(AppSupabase.client);

  List<CirclePickerOption> _circles = [];
  String? _circleId;
  DateTime _date = DateTime.now();
  List<AttendanceStudentRow> _students = [];
  Map<String, String> _statusByStudent = {};

  String? _loadedForOrgId;
  bool _loadingCircles = true;
  bool _loadingStudents = false;
  bool _saving = false;
  String? _message;
  bool _isError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orgId = context.read<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _loadedForOrgId = orgId;
      _loadCircles(orgId);
    }
  }

  Future<void> _loadCircles(String orgId) async {
    setState(() => _loadingCircles = true);
    final circles = await _repository.fetchCircles(orgId);
    if (mounted) setState(() { _circles = circles; _loadingCircles = false; });
  }

  Future<void> _loadSheet() async {
    if (_circleId == null) return;
    setState(() {
      _loadingStudents = true;
      _message = null;
    });

    final orgId = context.read<TenantController>().active!.organization.id;
    final sessionDate = _dateFormat.format(_date);
    final results = await Future.wait([
      _repository.fetchStudentsInCircle(orgId, _circleId!),
      _repository.fetchExisting(_circleId!, sessionDate),
    ]);
    final students = results[0] as List<AttendanceStudentRow>;
    final existing = results[1] as Map<String, String>;

    if (mounted) {
      setState(() {
        _students = students;
        _statusByStudent = {for (final s in students) s.id: existing[s.id] ?? 'present'};
        _loadingStudents = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
      if (_circleId != null) await _loadSheet();
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final orgId = context.read<TenantController>().active!.organization.id;
      await _repository.saveAttendance(
        organizationId: orgId,
        circleId: _circleId!,
        sessionDate: _dateFormat.format(_date),
        statusByStudentId: _statusByStudent,
      );
      if (mounted) setState(() { _message = 'تم حفظ الحضور بنجاح'; _isError = false; });
    } catch (e) {
      if (mounted) setState(() { _message = 'حدث خطأ أثناء الحفظ - حاول مرة أخرى'; _isError = true; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحضور')),
      drawer: const AppDrawer(),
      body: _loadingCircles
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _circleId,
                        decoration: const InputDecoration(labelText: 'الحلقة'),
                        items: _circles.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (value) {
                          setState(() => _circleId = value);
                          _loadSheet();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(_dateFormat.format(_date)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_message != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _message!,
                      style: TextStyle(color: _isError ? Colors.red.shade700 : Colors.green.shade700),
                    ),
                  ),
                if (_loadingStudents)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else if (_circleId != null && _students.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('لا يوجد طلاب بهذي الحلقة')),
                  )
                else
                  ..._students.map((s) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${s.fullName} (${s.studentCode})',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: kAttendanceStatusOptions.entries.map((e) {
                                  final selected = _statusByStudent[s.id] == e.key;
                                  return ChoiceChip(
                                    label: Text(e.value),
                                    selected: selected,
                                    onSelected: (_) => setState(() => _statusByStudent[s.id] = e.key),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      )),
                if (_students.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('حفظ الحضور'),
                  ),
                ],
              ],
            ),
    );
  }
}
