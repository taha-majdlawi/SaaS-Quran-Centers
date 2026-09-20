import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../../core/offline/sync_service.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/ui.dart';
import 'attendance_repository.dart';

final _dateFormat = DateFormat('yyyy-MM-dd');

const _statusColors = <String, MaterialColor>{
  'present': Colors.green,
  'absent': Colors.red,
  'excused': Colors.blue,
  'late': Colors.orange,
};

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
    try {
      final circles = await _repository.fetchCircles(orgId);
      if (mounted) setState(() => _circles = circles);
    } catch (_) {
      if (mounted) setState(() { _message = 'تعذّر تحميل الحلقات'; _isError = true; });
    } finally {
      if (mounted) setState(() => _loadingCircles = false);
    }
  }

  Future<void> _loadSheet() async {
    if (_circleId == null) return;
    setState(() {
      _loadingStudents = true;
      _message = null;
    });

    try {
      final orgId = context.read<TenantController>().active!.organization.id;
      final sessionDate = _dateFormat.format(_date);
      final results = await Future.wait<dynamic>([
        _repository.fetchStudentsInCircle(orgId, _circleId!),
        _repository.fetchExisting(_circleId!, sessionDate),
      ]);
      final students = results[0] as List<AttendanceStudentRow>;
      final existing = results[1] as Map<String, String>;
      if (mounted) {
        setState(() {
          _students = students;
          _statusByStudent = {for (final s in students) s.id: existing[s.id] ?? 'present'};
        });
      }
    } catch (_) {
      if (mounted) setState(() { _message = 'تعذّر تحميل طلاب الحلقة'; _isError = true; });
    } finally {
      if (mounted) setState(() => _loadingStudents = false);
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
      final queued = await _repository.saveAttendance(
        organizationId: orgId,
        circleId: _circleId!,
        sessionDate: _dateFormat.format(_date),
        statusByStudentId: _statusByStudent,
      );
      if (mounted) setState(() { _message = queued ? kQueuedMessage : 'تم حفظ الحضور بنجاح'; _isError = false; });
    } catch (e) {
      if (mounted) setState(() { _message = e is StateError ? e.message : 'حدث خطأ أثناء الحفظ - حاول مرة أخرى'; _isError = true; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int _count(String status) => _statusByStudent.values.where((s) => s == status).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const DrawerLeading(),title: const Text('الحضور')),
      drawer: const AppDrawer(),
      bottomNavigationBar: _students.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LoadingButton(label: 'حفظ الحضور', icon: Icons.save_rounded, loading: _saving, onPressed: _save),
              ),
            ),
      body: _loadingCircles
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _circleId,
                          decoration: const InputDecoration(labelText: 'الحلقة', prefixIcon: Icon(Icons.groups_outlined)),
                          items: _circles.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (value) {
                            setState(() => _circleId = value);
                            _loadSheet();
                          },
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_rounded, size: 18),
                          label: Text('التاريخ:  ${_dateFormat.format(_date)}'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_message != null) MessageBanner(message: _message!, isError: _isError),
                if (_circleId == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyState(
                      icon: Icons.fact_check_outlined,
                      title: 'اختر الحلقة لتسجيل الحضور',
                      subtitle: 'ثم حدّد حالة كل طالب واحفظ',
                    ),
                  )
                else if (_loadingStudents)
                  const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                else if (_students.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyState(icon: Icons.people_outline, title: 'لا يوجد طلاب بهذي الحلقة'),
                  )
                else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in kAttendanceStatusOptions.entries)
                        StatusChip(label: '${e.value} ${_count(e.key)}', color: _statusColors[e.key] ?? Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        for (final s in _students) {
                          _statusByStudent[s.id] = 'present';
                        }
                      }),
                      icon: const Icon(Icons.done_all_rounded),
                      label: const Text('تحديد الكل حاضر'),
                    ),
                  ),
                  for (final s in _students)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  InitialAvatar(s.fullName, radius: 18),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        Text(s.studentCode,
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  for (final e in kAttendanceStatusOptions.entries)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 3),
                                        child: _StatusButton(
                                          label: e.value,
                                          color: _statusColors[e.key] ?? Colors.grey,
                                          selected: _statusByStudent[s.id] == e.key,
                                          onTap: () => setState(() => _statusByStudent[s.id] = e.key),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({required this.label, required this.color, required this.selected, required this.onTap});

  final String label;
  final MaterialColor color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.shade600 : color.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color.shade600 : color.shade100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : color.shade800,
          ),
        ),
      ),
    );
  }
}
