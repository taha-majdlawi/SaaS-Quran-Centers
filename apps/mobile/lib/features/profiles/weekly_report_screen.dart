import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/garden.dart';
import '../../core/widgets/ui.dart';
import 'profile_widgets.dart';
import 'profiles_repository.dart';

/// One week of a student against the week before, where they stand on the
/// memorization goal, and the teacher's note - what the weekly notification opens.
class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key, required this.studentId});
  final String studentId;

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final _repo = ProfilesRepository(Supabase.instance.client);
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.weekly(context.read<TenantController>().active!.organization.id, widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    final W = tr(context).weekly;
    return Scaffold(
      appBar: AppBar(title: Text(W.title)),
      body: AsyncBody<Map<String, dynamic>>(
        future: _future,
        onRetry: () => setState(() => _future = _repo.weekly(context.read<TenantController>().active!.organization.id, widget.studentId)),
        builder: (context, r) {
          final s = r['student'] as Map<String, dynamic>;
          final w = r['week'] as Map<String, dynamic>;
          final p = r['previous'] as Map<String, dynamic>;
          final note = r['note'] as Map<String, dynamic>?;
          int pct(Map<String, dynamic> m) => (m['days'] as num) == 0 ? 0 : ((m['present'] as num) * 100 / (m['days'] as num)).round();
          final rows = <(String, String, String, Widget)>[
            (W.recitations, '${w['recitations']}', '${p['recitations']}', DeltaText(now: w['recitations'], prev: p['recitations'])),
            (W.newPages, numText(w['pages']), numText(p['pages']), DeltaText(now: w['pages'], prev: p['pages'])),
            (W.reviews, '${w['reviews']}', '${p['reviews']}', DeltaText(now: w['reviews'], prev: p['reviews'])),
            (W.points, '${w['points']}', '${p['points']}', DeltaText(now: w['points'], prev: p['points'])),
            (
              W.attendance,
              (w['days'] as num) == 0 ? '—' : fmt(W.attV, {'present': w['present'], 'days': w['days']}),
              (p['days'] as num) == 0 ? '—' : fmt(W.attV, {'present': p['present'], 'days': p['days']}),
              (w['days'] as num) == 0 || (p['days'] as num) == 0 ? const SizedBox.shrink() : DeltaText(now: pct(w), prev: pct(p), points: true),
            ),
          ];
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text('${s['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(
              [fmt(W.period, {'from': formatDate(r['from'] as String?), 'to': formatDate(r['to'] as String?)}), if (s['circle'] != null) '${s['circle']}', if (s['teacher'] != null) '${s['teacher']}'].join('  ·  '),
              style: const TextStyle(color: kInkMuted, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            GardenCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    const Expanded(flex: 4, child: SizedBox()),
                    Expanded(flex: 3, child: Text(W.thisWeek, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5))),
                    Expanded(flex: 3, child: Text(W.lastWeek, style: const TextStyle(color: kInkMuted, fontSize: 12.5))),
                    const Expanded(flex: 3, child: SizedBox()),
                  ]),
                ),
                for (final (label, a, b, d) in rows) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Expanded(flex: 4, child: Text(label, style: const TextStyle(color: kInkMuted, fontSize: 13))),
                      Expanded(flex: 3, child: Text(a, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Theme.of(context).colorScheme.primary))),
                      Expanded(flex: 3, child: Text(b, style: const TextStyle(color: kInkMuted))),
                      Expanded(flex: 3, child: Align(alignment: AlignmentDirectional.centerStart, child: d)),
                    ]),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 14),
            GoalCard(studentId: widget.studentId, studentName: '${s['name']}'),
            const SizedBox(height: 14),
            GardenCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(W.teacherNote, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (note == null)
                  Text(W.noNote, style: const TextStyle(color: kInkMuted))
                else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(12)),
                    child: Text('${note['body']}'),
                  ),
                  const SizedBox(height: 4),
                  Text('${note['by'] ?? ''}  ·  ${formatDate(note['at'] as String?)}', style: const TextStyle(fontSize: 11.5, color: kInkMuted)),
                ],
                if (s['next_plan'] != null && '${s['next_plan']}'.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(W.nextPlan, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${s['next_plan']}'),
                ],
              ]),
            ),
          ]);
        },
      ),
    );
  }
}
