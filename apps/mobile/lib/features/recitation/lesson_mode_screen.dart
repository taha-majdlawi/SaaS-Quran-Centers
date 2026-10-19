import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/offline/sync_service.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/data/quran_data.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import 'recitation_repository.dart';
import 'recitation_sheet.dart';
import '../../core/i18n/i18n.dart';

/// Eqraa's "lesson mode": walk the circle one student at a time - record,
/// mark absent, or postpone. Nothing is written for "later", and closing the
/// recitation sheet without saving does not advance the queue.
class LessonModeScreen extends StatefulWidget {
  const LessonModeScreen({super.key, required this.circleId});

  final String circleId;

  @override
  State<LessonModeScreen> createState() => _LessonModeScreenState();
}

class _LessonModeScreenState extends State<LessonModeScreen> {
  final _repository = RecitationRepository(AppSupabase.client);
  List<GradeOption> _grades = [];
  List<CircleStudent> _queue = [];
  final List<CircleStudent> _postponed = [];
  int _total = 0;
  int _index = 0;
  int _recited = 0;
  int _absent = 0;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final orgId = context.read<TenantController>().active!.organization.id;
      final results = await Future.wait<dynamic>([
        _repository.fetchCircleStudents(widget.circleId),
        _repository.fetchGrades(orgId),
      ]);
      final students = results[0] as List<CircleStudent>;
      _grades = results[1] as List<GradeOption>;
      // Who is still waiting: not recited today and not already marked absent.
      _queue = students.where((s) => s.recitedToday == 0 && s.attendanceToday != 'absent').toList();
      _total = _queue.length;
      _index = 0;
    } catch (_) {
      _error = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  CircleStudent? get _current => _index < _queue.length ? _queue[_index] : null;

  Future<void> _record() async {
    final s = _current!;
    final points = await showRecitationSheet(context, studentId: s.id, studentName: s.fullName, grades: _grades);
    if (points == null || !mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(points == kQueuedPoints ? kQueuedMessage : fmt(tr(context).teach.savedPoints, {'points': points}))));
    setState(() {
      _recited++;
      _index++;
    });
  }

  Future<void> _markAbsent() async {
    final s = _current!;
    final orgId = context.read<TenantController>().active!.organization.id;
    try {
      await _repository.setAttendance(orgId: orgId, circleId: widget.circleId, studentId: s.id, studentName: s.fullName, status: 'absent');
      setState(() {
        _absent++;
        _index++;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is StateError ? e.message : tr(context).rec.absenceFailed)));
    }
  }

  void _later() {
    setState(() {
      _postponed.add(_current!);
      _index++;
    });
  }

  void _anotherRound() {
    setState(() {
      _queue = List.of(_postponed);
      _postponed.clear();
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return Scaffold(
      backgroundColor: TeacherStyle.scaffold,
      appBar: AppBar(
        title: Text(tr(context).rec.lessonTitle),
        backgroundColor: TeacherStyle.brand(context),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? ErrorState(onRetry: _load)
              : current == null
                  ? _summary(context)
                  : _student(context, current),
    );
  }

  Widget _student(BuildContext context, CircleStudent s) {
    final brand = TeacherStyle.brand(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: _queue.isEmpty ? 0 : _index / _queue.length, minHeight: 8, backgroundColor: TeacherStyle.chip, valueColor: AlwaysStoppedAnimation(brand)),
          ),
          const SizedBox(height: 8),
          Text(fmt(tr(context).rec.studentXofY, {'v': _index + 1, 'n': _queue.length}), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: TeacherStyle.textMuted)),
          const Spacer(),
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: TeacherStyle.tint(brand),
              child: Text(initialsOf(s.fullName), style: TextStyle(color: brand, fontWeight: FontWeight.bold, fontSize: 34)),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.fullName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: TeacherStyle.textPrimary)),
          const SizedBox(height: 6),
          Text(fmt(tr(context).teach.pointsN, {'totalPoints': s.totalPoints}), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: TeacherStyle.textMuted)),
          const SizedBox(height: 14),
          _lastRecitation(context, s.lastRecitation),
          if (s.nextPlan != null && s.nextPlan!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: TeacherStyle.tint(Colors.teal), borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr(context).rec.plan, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
                const SizedBox(height: 4),
                Text(s.nextPlan!, style: const TextStyle(fontSize: 13.5, height: 1.5, color: TeacherStyle.textPrimary)),
              ]),
            ),
          ],
          const Spacer(),
          FilledButton.icon(
            onPressed: _record,
            icon: const Icon(Icons.menu_book_rounded),
            label: Text(tr(context).rec.recordBtn, style: TextStyle(fontSize: 16)),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _markAbsent,
                icon: const Icon(Icons.person_off_rounded, size: 18),
                label: Text(tr(context).rec.absent),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.withValues(alpha: 0.4)), minimumSize: const Size.fromHeight(48)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _later,
                icon: const Icon(Icons.skip_next_rounded, size: 18),
                label: Text(tr(context).rec.later),
                style: OutlinedButton.styleFrom(foregroundColor: TeacherStyle.textMuted, side: const BorderSide(color: TeacherStyle.border), minimumSize: const Size.fromHeight(48)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Where the student stopped last time, so the teacher picks up from there.
  Widget _lastRecitation(BuildContext context, LastRecitation? last) {
    final t = tr(context);
    if (last == null) {
      return Text('${t.stu.lastRecitation}: ${t.stu.noRecitations}',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: TeacherStyle.textMuted));
    }
    final grade = _grades.where((g) => g.key == last.grade).map((g) => g.label).firstOrNull;
    final color = TeacherStyle.gradeColor(_grades, last.grade);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.history_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Text(t.stu.lastRecitation, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
          const Spacer(),
          Text(formatDate(last.createdAt), style: const TextStyle(fontSize: 11.5, color: TeacherStyle.textMuted)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: Text(fmt(t.stu.surahV, {'v': surahName(last.surah)}),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: TeacherStyle.textPrimary)),
          ),
          if (grade != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
              child: Text(grade, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ]),
        const SizedBox(height: 2),
        Text(fmt(t.stu.recLine, {'type': kAchievementTypes[last.type] ?? last.type, 'ayahFrom': last.ayahFrom, 'ayahTo': last.ayahTo}),
            style: const TextStyle(fontSize: 12.5, color: TeacherStyle.textMuted)),
      ]),
    );
  }

  Widget _summary(BuildContext context) {
    final noOneWaiting = _total == 0 && _recited == 0 && _absent == 0;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(noOneWaiting ? Icons.verified_rounded : Icons.task_alt_rounded, size: 64, color: TeacherStyle.success),
          const SizedBox(height: 16),
          Text(noOneWaiting ? tr(context).rec.nobody : tr(context).rec.done,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TeacherStyle.textPrimary)),
          const SizedBox(height: 12),
          if (!noOneWaiting)
            Text(fmt(tr(context).rec.summary, {'_recited': _recited, '_absent': _absent, 'n': _postponed.length}), textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: TeacherStyle.textMuted)),
          const SizedBox(height: 24),
          if (_postponed.isNotEmpty) ...[
            FilledButton.icon(onPressed: _anotherRound, icon: Icon(Icons.replay_rounded), label: Text(tr(context).rec.anotherRound)),
            const SizedBox(height: 8),
          ],
          TextButton(onPressed: () => context.pop(), child: Text(tr(context).rec.finish)),
        ],
      ),
    );
  }
}
