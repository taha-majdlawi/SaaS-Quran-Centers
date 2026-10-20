import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/offline/sync_service.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../insights/insights_repository.dart';
import '../recitation/recitation_repository.dart';
import '../recitation/recitation_sheet.dart';
import 'teacher_widgets.dart';
import '../../core/i18n/i18n.dart';
import '../points/points_ledger.dart';

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
  final _insights = InsightsRepository(AppSupabase.client);
  final _search = TextEditingController();
  String _query = '';
  _Filter _filter = _Filter.all;
  _Sort _sort = _Sort.name;
  Map<String, List<int>> _due = const {};

  @override
  void initState() {
    super.initState();
    _loadDue();
  }

  @override
  void didUpdateWidget(covariant CircleRoster old) {
    super.didUpdateWidget(old);
    if (old.circleId != widget.circleId) _loadDue();
  }

  Future<void> _loadDue() async {
    try {
      final orgId = context.read<TenantController>().active!.organization.id;
      final rows = await _insights.dueReviews(orgId, circleId: widget.circleId);
      final map = <String, List<int>>{};
      for (final r in rows) {
        map.putIfAbsent(r.studentId, () => []).add(r.surah);
      }
      if (mounted) setState(() => _due = map);
    } catch (_) {} // not critical: the roster stands on its own without it
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _record(CircleStudent s, {int? prefillSurah}) async {
    final points = await showRecitationSheet(
      context,
      studentId: s.id,
      studentName: s.fullName,
      grades: widget.grades,
      initialType: prefillSurah == null ? null : 'recent_review',
      initialSurah: prefillSurah,
    );
    if (points != null && mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(points == kQueuedPoints ? kQueuedMessage : fmt(tr(context).teach.savedPoints, {'points': points}))));
      widget.onChanged();
      _loadDue();
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is StateError ? e.message : tr(context).teach.attendanceFailed)));
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
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Text(tr(context).teach.noStudents, textAlign: TextAlign.center, style: TextStyle(color: TeacherStyle.textMuted, fontSize: 13)),
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
                hintText: tr(context).teach.searchPh,
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
                      label: Text(switch (f) { _Filter.all => tr(context).teach.all, _Filter.notYet => tr(context).teach.notToday, _Filter.done => tr(context).teach.recitedToday }, style: const TextStyle(fontSize: 11.5)),
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
                tooltip: tr(context).teach.sort,
                initialValue: _sort,
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => [
                  PopupMenuItem(value: _Sort.name, child: Text(tr(context).teach.alpha)),
                  PopupMenuItem(value: _Sort.longestWait, child: Text(tr(context).teach.notFirst)),
                  PopupMenuItem(value: _Sort.points, child: Text(tr(context).teach.topPoints)),
                ],
                child: const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.sort_rounded, size: 18, color: TeacherStyle.textMuted)),
              ),
              if (visible.length != students.length) Text(fmt(tr(context).teach.xOfY, {'n': visible.length, 'n2': students.length}), style: const TextStyle(fontSize: 11.5, color: TeacherStyle.textMuted)),
            ]),
            const SizedBox(height: 4),
          ]),
        ),
      if (visible.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(children: [
            Text(tr(context).teach.noMatch, style: TextStyle(fontSize: 13, color: TeacherStyle.textMuted)),
            TextButton.icon(
              onPressed: () => setState(() {
                _search.clear();
                _query = '';
                _filter = _Filter.all;
              }),
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: Text(tr(context).teach.showAll),
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
            dueReviews: _due[s.id] ?? const [],
            onRecordDue: (_due[s.id] ?? const []).isEmpty ? null : () => _record(s, prefillSurah: _due[s.id]!.first),
            onAward: context.watch<TenantController>().isDisabled('points')
                ? null
                : () async {
                    if (await showAwardPointsSheet(context, studentId: s.id, studentName: s.fullName) != null) widget.onChanged();
                  },
          ),
    ]);
  }
}
