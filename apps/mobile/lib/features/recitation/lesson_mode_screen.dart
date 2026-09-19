import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import 'recitation_repository.dart';
import 'recitation_sheet.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الحفظ ✓  +$points نقطة')));
    setState(() {
      _recited++;
      _index++;
    });
  }

  Future<void> _markAbsent() async {
    final s = _current!;
    final orgId = context.read<TenantController>().active!.organization.id;
    try {
      await _repository.setAttendance(orgId: orgId, circleId: widget.circleId, studentId: s.id, status: 'absent');
      setState(() {
        _absent++;
        _index++;
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر حفظ الغياب')));
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
      appBar: AppBar(title: const Text('وضع الحصة')),
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('الطالب ${_index + 1} من ${_queue.length}',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _queue.isEmpty ? 0 : _index / _queue.length, minHeight: 8),
          const Spacer(),
          Center(child: InitialAvatar(s.fullName, radius: 48)),
          const SizedBox(height: 16),
          Text(s.fullName,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('${s.totalPoints} نقطة', textAlign: TextAlign.center, style: TextStyle(color: Colors.amber.shade800)),
          if (s.nextPlan != null && s.nextPlan!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(14)),
              child: Text('الخطة المطلوبة منه: ${s.nextPlan}', textAlign: TextAlign.center),
            ),
          ],
          const Spacer(),
          LoadingButton(label: 'رصد التسميع', icon: Icons.mic_rounded, loading: false, onPressed: _record),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _markAbsent,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                  child: const Text('غائب'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton(onPressed: _later, child: const Text('لاحقًا'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summary(BuildContext context) {
    final noOneWaiting = _total == 0 && _recited == 0 && _absent == 0;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle_rounded, size: 84, color: Colors.green.shade600),
          const SizedBox(height: 16),
          Text(noOneWaiting ? 'لا أحد بانتظار التسميع في هذه الحلقة الآن' : 'انتهت الحصة',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (!noOneWaiting)
            Text('سمّع $_recited  •  غائب $_absent  •  مؤجَّل ${_postponed.length}',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 28),
          if (_postponed.isNotEmpty)
            FilledButton(onPressed: _anotherRound, child: const Text('جولة أخرى على من تبقّى')),
          if (_postponed.isNotEmpty) const SizedBox(height: 10),
          OutlinedButton(onPressed: () => context.pop(), child: const Text('إنهاء والعودة')),
        ],
      ),
    );
  }
}
