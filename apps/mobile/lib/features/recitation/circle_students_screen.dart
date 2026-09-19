import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import 'recitation_repository.dart';
import 'recitation_sheet.dart';

const _attendanceLabels = {'present': 'حاضر', 'absent': 'غائب', 'late': 'متأخر', 'excused': 'بعذر'};
const _attendanceColors = <String, MaterialColor>{
  'present': Colors.green,
  'absent': Colors.red,
  'late': Colors.orange,
  'excused': Colors.blue,
};

enum _Filter { all, notYet, done }

class _CircleData {
  const _CircleData({required this.name, required this.students, required this.grades});
  final String name;
  final List<CircleStudent> students;
  final List<GradeOption> grades;
}

/// Eqraa's circle card as a screen: every student of the circle with today's
/// recitation state, one-tap recitation entry and attendance.
class CircleStudentsScreen extends StatefulWidget {
  const CircleStudentsScreen({super.key, required this.circleId});

  final String circleId;

  @override
  State<CircleStudentsScreen> createState() => _CircleStudentsScreenState();
}

class _CircleStudentsScreenState extends State<CircleStudentsScreen> {
  final _repository = RecitationRepository(AppSupabase.client);
  late Future<_CircleData> _future;
  _Filter _filter = _Filter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_CircleData> _load() async {
    final orgId = context.read<TenantController>().active!.organization.id;
    final results = await Future.wait<dynamic>([
      AppSupabase.client.from('circles').select('name').eq('id', widget.circleId).single(),
      _repository.fetchCircleStudents(widget.circleId),
      _repository.fetchGrades(orgId),
    ]);
    return _CircleData(
      name: (results[0] as Map<String, dynamic>)['name'] as String,
      students: results[1] as List<CircleStudent>,
      grades: results[2] as List<GradeOption>,
    );
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _record(CircleStudent student, List<GradeOption> grades) async {
    final points = await showRecitationSheet(
      context,
      studentId: student.id,
      studentName: student.fullName,
      grades: grades,
    );
    if (points != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الحفظ ✓  +$points نقطة')));
      _reload();
    }
  }

  Future<void> _mark(CircleStudent student, String status) async {
    final orgId = context.read<TenantController>().active!.organization.id;
    try {
      await _repository.setAttendance(orgId: orgId, circleId: widget.circleId, studentId: student.id, status: status);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${student.fullName}: ${_attendanceLabels[status]}')));
        _reload();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر حفظ الحضور')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CircleData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(data?.name ?? 'الحلقة'),
            actions: [
              if (data != null)
                IconButton(
                  tooltip: 'ابدأ الحصة',
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  onPressed: () async {
                    await context.push('/circle/${widget.circleId}/lesson');
                    if (mounted) _reload();
                  },
                ),
            ],
          ),
          body: snapshot.hasError
              ? ErrorState(onRetry: _reload)
              : data == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBody(context, data),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, _CircleData data) {
    final done = data.students.where((s) => s.recitedToday > 0).length;
    var students = data.students.where((s) {
      if (_filter == _Filter.notYet && s.recitedToday > 0) return false;
      if (_filter == _Filter.done && s.recitedToday == 0) return false;
      return _query.isEmpty || s.fullName.contains(_query) || s.studentCode.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    if (data.students.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'لا يوجد طلاب في هذه الحلقة بعد',
        subtitle: 'أضف الطلاب من قسم الطلاب',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('سمّع اليوم $done من ${data.students.length}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: data.students.isEmpty ? 0 : done / data.students.length,
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: const InputDecoration(hintText: 'ابحث باسم الطالب أو رقمه', prefixIcon: Icon(Icons.search_rounded)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final f in _Filter.values)
                ChoiceChip(
                  label: Text(switch (f) {
                    _Filter.all => 'الكل',
                    _Filter.notYet => 'لم يسمّع اليوم',
                    _Filter.done => 'سمّع اليوم',
                  }),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (students.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 40), child: EmptyState(icon: Icons.search_off_rounded, title: 'لا يطابق أحد ما اخترته')),
          for (final s in students)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  leading: InitialAvatar(s.fullName),
                  title: Text(s.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        StatusChip(label: '${s.totalPoints} نقطة', color: Colors.amber),
                        StatusChip(
                          label: s.recitedToday > 0 ? 'سمّع اليوم ×${s.recitedToday}' : 'لم يسمّع',
                          color: s.recitedToday > 0 ? Colors.green : Colors.grey,
                        ),
                        if (s.attendanceToday != null)
                          StatusChip(
                            label: _attendanceLabels[s.attendanceToday] ?? s.attendanceToday!,
                            color: _attendanceColors[s.attendanceToday] ?? Colors.grey,
                          ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'رصد تسميع',
                        icon: const Icon(Icons.mic_none_rounded),
                        onPressed: () => _record(s, data.grades),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) => _mark(s, v),
                        itemBuilder: (context) => [
                          for (final e in _attendanceLabels.entries)
                            PopupMenuItem(value: e.key, child: Text('حضور: ${e.value}')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
