import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/offline/sync_service.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../recitation/recitation_repository.dart';
import '../recitation/recitation_sheet.dart';
import 'teacher_widgets.dart';

enum _Filter { all, notYet, done }

enum _Sort { name, longestWait, points }

/// The students of one circle as the teacher works with them: search + filter +
/// sort once the circle is big enough, then a tile per student with one-tap
/// attendance and recitation. Used inside the home card and on the circle page.
class CircleRoster extends StatefulWidget {
  const CircleRoster({super.key, required this.circleId, required this.students, required this.grades, required this.onChanged});

  final String circleId;
  final List<CircleStudent> students;
  final List<GradeOption> grades;
  final VoidCallback onChanged;

  @override
  State<CircleRoster> createState() => _CircleRosterState();
}

class _CircleRosterState extends State<CircleRoster> {
  static const _toolbarThreshold = 6;
  final _repository = RecitationRepository(AppSupabase.client);
  final _search = TextEditingController();
  String _query = '';
  _Filter _filter = _Filter.all;
  _Sort _sort = _Sort.name;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _record(CircleStudent s) async {
    final points = await showRecitationSheet(context, studentId: s.id, studentName: s.fullName, grades: widget.grades);
    if (points != null && mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(points == kQueuedPoints ? kQueuedMessage : 'تم الحفظ ✓  +$points نقطة')));
      widget.onChanged();
    }
  }

  Future<void> _mark(CircleStudent s, String status) async {
    final orgId = context.read<TenantController>().active!.organization.id;
    try {
      final queued = await _repository.setAttendance(orgId: orgId, circleId: widget.circleId, studentId: s.id, studentName: s.fullName, status: status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(queued ? kQueuedMessage : '${s.fullName}: ${attendanceLabels[status]}')));
        widget.onChanged();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is StateError ? e.message : 'تعذّر حفظ الحضور')));
    }
  }

  List<CircleStudent> _visible() {
    final q = _query.toLowerCase();
    final list = widget.students.where((s) {
      if (_filter == _Filter.notYet && s.recitedToday > 0) return false;
      if (_filter == _Filter.done && s.recitedToday == 0) return false;
      return q.isEmpty || s.fullName.contains(_query) || s.studentCode.toLowerCase().contains(q);
    }).toList();
    list.sort((a, b) => switch (_sort) {
          _Sort.name => a.fullName.compareTo(b.fullName),
          _Sort.longestWait => a.recitedToday == b.recitedToday ? a.fullName.compareTo(b.fullName) : a.recitedToday.compareTo(b.recitedToday),
          _Sort.points => b.totalPoints.compareTo(a.totalPoints),
        });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final brand = TeacherStyle.brand(context);
    final visible = _visible();
    final students = widget.students;

    if (students.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Text('لا يوجد طلاب في هذه الحلقة بعد.\nاطلب من المشرف إضافة الطلاب إليها.', textAlign: TextAlign.center, style: TextStyle(color: TeacherStyle.textMuted, fontSize: 13)),
      );
    }

    return Column(children: [
      if (students.length >= _toolbarThreshold)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'ابحث باسم الطالب أو رقمه',
                hintStyle: const TextStyle(fontSize: 13, color: TeacherStyle.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: TeacherStyle.textMuted),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        })),
                filled: true,
                fillColor: TeacherStyle.chip,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Wrap(spacing: 6, children: [
                  for (final f in _Filter.values)
                    ChoiceChip(
                      label: Text(switch (f) { _Filter.all => 'الكل', _Filter.notYet => 'لم يسمّع اليوم', _Filter.done => 'سمّع اليوم' }, style: const TextStyle(fontSize: 11.5)),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: TeacherStyle.chip,
                      selectedColor: TeacherStyle.tint(brand, 0.14),
                      labelStyle: TextStyle(color: _filter == f ? brand : TeacherStyle.textMuted, fontWeight: _filter == f ? FontWeight.bold : FontWeight.normal),
                      side: BorderSide(color: _filter == f ? brand.withValues(alpha: 0.4) : TeacherStyle.border),
                    ),
                ]),
              ),
              PopupMenuButton<_Sort>(
                tooltip: 'ترتيب القائمة',
                initialValue: _sort,
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _Sort.name, child: Text('أبجديًا')),
                  PopupMenuItem(value: _Sort.longestWait, child: Text('من لم يسمّع أولًا')),
                  PopupMenuItem(value: _Sort.points, child: Text('الأعلى نقاطًا')),
                ],
                child: const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.sort_rounded, size: 18, color: TeacherStyle.textMuted)),
              ),
              if (visible.length != students.length) Text('${visible.length} من ${students.length}', style: const TextStyle(fontSize: 11.5, color: TeacherStyle.textMuted)),
            ]),
            const SizedBox(height: 4),
          ]),
        ),
      if (visible.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(children: [
            const Text('لا يطابق أحد ما اخترته.', style: TextStyle(fontSize: 13, color: TeacherStyle.textMuted)),
            TextButton.icon(
              onPressed: () => setState(() {
                _search.clear();
                _query = '';
                _filter = _Filter.all;
              }),
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: const Text('إظهار كل الطلاب'),
            ),
          ]),
        )
      else
        for (final s in visible)
          TeacherStudentTile(
            student: s,
            onOpen: () async {
              await context.push('/students/${s.id}/file');
              if (mounted) widget.onChanged();
            },
            onRecord: () => _record(s),
            onAttendance: (status) => _mark(s, status),
          ),
    ]);
  }
}
