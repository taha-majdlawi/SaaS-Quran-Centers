import 'package:flutter/material.dart';

import '../../core/theme/teacher_style.dart';
import '../recitation/recitation_repository.dart';

/// The gradient, collapsing page header of the teacher screens.
SliverAppBar teacherHeader(
  BuildContext context, {
  required String title,
  Widget? background,
  double expandedHeight = 150,
  List<Widget> actions = const [],
  bool centerTitle = false,
}) {
  final scale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6);
  return SliverAppBar(
    pinned: true,
    expandedHeight: expandedHeight * scale,
    backgroundColor: TeacherStyle.brand(context),
    foregroundColor: Colors.white,
    elevation: 0,
    actions: actions,
    flexibleSpace: FlexibleSpaceBar(
      centerTitle: centerTitle,
      titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16, end: 20),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
      background: Container(decoration: BoxDecoration(gradient: TeacherStyle.headerGradient(context)), child: background),
    ),
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.icon = Icons.view_agenda_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 4, top: 4),
        child: Row(children: [
          Icon(icon, size: 18, color: TeacherStyle.textMuted),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TeacherStyle.textMuted)),
        ]),
      );
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: TeacherStyle.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: TeacherStyle.tint(color), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 17),
        ),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: TeacherStyle.textMuted)),
      ]),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.color, required this.icon, required this.label});

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold)),
        ]),
      );
}

const attendanceLabels = {'present': 'حاضر', 'absent': 'غائب', 'late': 'متأخر', 'excused': 'بعذر'};
const attendanceColors = <String, Color>{
  'present': TeacherStyle.success,
  'absent': TeacherStyle.danger,
  'late': TeacherStyle.warning,
  'excused': TeacherStyle.blue,
};

/// One student of a circle: avatar, name, points, today's state, and the two
/// actions a teacher uses all day (attendance, record a recitation).
class TeacherStudentTile extends StatelessWidget {
  const TeacherStudentTile({super.key, required this.student, required this.onOpen, required this.onRecord, required this.onAttendance, this.dueReviews = const [], this.onRecordDue});

  final CircleStudent student;
  final VoidCallback onOpen;
  final VoidCallback onRecord;
  final ValueChanged<String> onAttendance;
  /// Surah numbers the spaced-review schedule says are due today for this student.
  final List<int> dueReviews;
  final VoidCallback? onRecordDue;

  @override
  Widget build(BuildContext context) {
    final brand = TeacherStyle.brand(context);
    final att = student.attendanceToday;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      elevation: 2,
      color: TeacherStyle.surfaceAlt,
      shadowColor: brand.withValues(alpha: 0.2),
      shape: TeacherStyle.cardShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: TeacherStyle.tint(brand),
                child: Text(initialsOf(student.fullName), style: TextStyle(color: brand, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(student.fullName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.25)),
                  const SizedBox(height: 6),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text('${student.totalPoints} نقطة', style: const TextStyle(color: TeacherStyle.textMuted, fontSize: 12.5)),
                    const SizedBox(width: 10),
                    Text(student.studentCode, textDirection: TextDirection.ltr, style: const TextStyle(color: TeacherStyle.textMuted, fontSize: 11.5)),
                  ]),
                ]),
              ),
            ]),
            if (student.recitedToday > 0 || att != null || dueReviews.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 58, top: 8),
                child: Wrap(spacing: 8, runSpacing: 4, children: [
                  if (student.recitedToday > 0)
                    Pill(color: brand, icon: Icons.check_circle_rounded, label: student.recitedToday > 1 ? 'سمّع اليوم ×${student.recitedToday}' : 'سمّع اليوم'),
                  if (att != null) Pill(color: attendanceColors[att] ?? TeacherStyle.textMuted, icon: Icons.how_to_reg_rounded, label: attendanceLabels[att] ?? att),
                  if (dueReviews.isNotEmpty)
                    GestureDetector(
                      onTap: onRecordDue,
                      child: Pill(color: TeacherStyle.gold, icon: Icons.replay_circle_filled_rounded, label: 'مراجعة مستحقة (${dueReviews.length})'),
                    ),
                ]),
              ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              PopupMenuButton<String>(
                tooltip: 'تسجيل حضور',
                onSelected: onAttendance,
                itemBuilder: (context) => [for (final e in attendanceLabels.entries) PopupMenuItem(value: e.key, child: Text('حضور: ${e.value}'))],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: TeacherStyle.tint(TeacherStyle.success), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.how_to_reg_rounded, size: 20, color: TeacherStyle.success),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onRecord,
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: const Text('رصد تسميع', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  backgroundColor: brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
