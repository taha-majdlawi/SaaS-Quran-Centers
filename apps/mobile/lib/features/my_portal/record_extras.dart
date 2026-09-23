// Record-tab sections (parity round with eqraa's سجلّي tab): monthly
// summary, points-by-grade breakdown, attendance history, and a searchable/
// filterable/session-grouped recitation list. Pure presentation - all data
// comes from my_portal_repository.dart (get_student_dashboard + the newer
// student_record_detail RPC, 0056).
import 'package:flutter/material.dart';

import '../../core/data/quran_data.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import '../recitation/recitation_repository.dart' show kAchievementTypes;
import 'my_portal_repository.dart';
import 'my_portal_screen.dart' show RecitationTile;

const kAttendanceLabels = {'present': 'حاضر', 'absent': 'غائب', 'late': 'متأخر', 'excused': 'مُعذَر'};
const kAttendanceColors = {
  'present': Colors.green,
  'absent': Colors.red,
  'late': Colors.orange,
  'excused': Colors.blueGrey,
};

class MonthlySummaryCard extends StatelessWidget {
  const MonthlySummaryCard({super.key, required this.recitations, required this.ayahs, required this.attendanceRate, required this.points});
  final int recitations;
  final int ayahs;
  final double? attendanceRate;
  final int points;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String value) => Expanded(
          child: Column(children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5), textAlign: TextAlign.center),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Align(alignment: Alignment.centerRight, child: Text('هذا الشهر', style: TextStyle(fontWeight: FontWeight.w800))),
          const SizedBox(height: 10),
          Row(children: [
            cell('تسميعات', '$recitations'),
            cell('آيات', '$ayahs'),
            cell('حضور', attendanceRate == null ? '—' : '${(attendanceRate! * 100).round()}%'),
            cell('نقاط', '$points'),
          ]),
        ]),
      ),
    );
  }
}

class PointsBreakdownCard extends StatelessWidget {
  const PointsBreakdownCard({super.key, required this.rows, required this.gradeLabels});
  final List<PointsBreakdownRow> rows;
  final Map<String, String> gradeLabels;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تفصيل النقاط', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Expanded(child: Text(gradeLabels[r.grade] ?? r.grade)),
                  Text('${r.count} × ${r.pointsEach} = ${r.total}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class AttendanceListSection extends StatelessWidget {
  const AttendanceListSection({super.key, required this.rows});
  final List<AttendanceRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(12), child: Text('لا يوجد سجل حضور بعد'));
    return Column(
      children: [
        for (final r in rows)
          Card(
            child: ListTile(
              leading: Icon(Icons.event_available_rounded, color: kAttendanceColors[r.status] ?? Colors.grey),
              title: Text(formatDate(r.date)),
              trailing: StatusChip(label: kAttendanceLabels[r.status] ?? r.status, color: kAttendanceColors[r.status] ?? Colors.grey),
            ),
          ),
      ],
    );
  }
}

/// Consecutive recitations recorded together (same non-null session_group_id)
/// collapse into one expandable group, matching eqraa's RecitationSessionGroup.
List<List<PortalRecitation>> groupSessions(List<PortalRecitation> list) {
  final groups = <List<PortalRecitation>>[];
  for (final r in list) {
    final lastId = groups.isNotEmpty ? groups.last.first.sessionGroupId : null;
    if (r.sessionGroupId != null && lastId == r.sessionGroupId) {
      groups.last.add(r);
    } else {
      groups.add([r]);
    }
  }
  return groups;
}

/// Search box + type/grade filter chips over an already-fetched recitation
/// list (no extra round trip per keystroke - matches eqraa, see 0056's
/// comment on why the full list is fetched once).
class RecitationsSearchList extends StatefulWidget {
  const RecitationsSearchList({super.key, required this.recitations});
  final List<PortalRecitation> recitations;

  @override
  State<RecitationsSearchList> createState() => _RecitationsSearchListState();
}

class _RecitationsSearchListState extends State<RecitationsSearchList> {
  String _query = '';
  String? _type;
  String? _grade;

  @override
  Widget build(BuildContext context) {
    final grades = widget.recitations.map((r) => r.gradeLabel).where((g) => g.isNotEmpty).toSet().toList()..sort();
    final filtered = widget.recitations.where((r) {
      if (_type != null && r.type != _type) return false;
      if (_grade != null && r.gradeLabel != _grade) return false;
      if (_query.trim().isNotEmpty) {
        final q = _query.trim();
        final hay = '${surahName(r.surah)} ${r.notes ?? ''}';
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
    final groups = groupSessions(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(hintText: 'بحث بالسورة أو الملاحظة', prefixIcon: Icon(Icons.search_rounded), isDense: true),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          FilterChip(label: const Text('الكل'), selected: _type == null, onSelected: (_) => setState(() => _type = null)),
          for (final t in kAchievementTypes.entries)
            FilterChip(label: Text(t.value), selected: _type == t.key, onSelected: (_) => setState(() => _type = _type == t.key ? null : t.key)),
          if (grades.isNotEmpty) const SizedBox(width: 4),
          for (final g in grades)
            FilterChip(label: Text(g), selected: _grade == g, onSelected: (_) => setState(() => _grade = _grade == g ? null : g)),
        ]),
        const SizedBox(height: 12),
        if (groups.isEmpty)
          const Padding(padding: EdgeInsets.all(12), child: Text('لا يوجد نتائج'))
        else
          for (final g in groups) g.length == 1 ? RecitationTile(r: g.first) : _SessionGroupTile(items: g),
      ],
    );
  }
}

class _SessionGroupTile extends StatelessWidget {
  const _SessionGroupTile({required this.items});
  final List<PortalRecitation> items;

  @override
  Widget build(BuildContext context) {
    final totalPoints = items.fold<int>(0, (sum, r) => sum + r.points);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text('${items.length} تسميعات في جلسة واحدة', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${formatDate(items.first.createdAt)}  ·  ${kAchievementTypes[items.first.type] ?? items.first.type}'),
        trailing: StatusChip(label: '+$totalPoints', color: Colors.green),
        children: [for (final r in items) Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: RecitationTile(r: r))],
      ),
    );
  }
}
