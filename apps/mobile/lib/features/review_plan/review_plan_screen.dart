import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/quran_data.dart';
import '../../core/i18n/i18n.dart';
import '../../core/offline/sync_service.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/widgets/garden.dart';
import '../../core/widgets/ui.dart';
import '../recitation/recitation_repository.dart';
import '../recitation/recitation_sheet.dart';

/// Today's review portion of every student (suggested from what they
/// memorised, continuing where the last one stopped); the teacher approves
/// one or all with a tap. Works offline: approvals queue like other saves.
class ReviewPlanScreen extends StatefulWidget {
  const ReviewPlanScreen({super.key});

  static Future<List<dynamic>> load(SupabaseClient client, String orgId) async =>
      (await SyncService.instance.raw('review-plans:$orgId', () => client.rpc('review_plans_today', params: {'p_org': orgId}))) as List<dynamic>;

  /// "النبأ 1" style reference.
  static String ref(int surah, int ayah) => fmt(currentStrings.rplan.ayahRef, {'surah': surahName(surah), 'ayah': ayah});

  @override
  State<ReviewPlanScreen> createState() => _ReviewPlanScreenState();
}

class _ReviewPlanScreenState extends State<ReviewPlanScreen> {
  late Future<List<dynamic>> _future;

  String get _orgId => context.read<TenantController>().active!.organization.id;

  @override
  void initState() {
    super.initState();
    _future = ReviewPlanScreen.load(Supabase.instance.client, _orgId);
  }

  void _reload() => setState(() => _future = ReviewPlanScreen.load(Supabase.instance.client, _orgId));

  bool _pending(String studentId) =>
      SyncService.instance.pendingOf('review_approve').any((i) => i.payload['p_student'] == studentId);

  Future<void> _approve(Map<String, dynamic> row) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final out = await SyncService.instance.submit(
        'review_approve',
        {'p_org': _orgId, 'p_student': row['student_id']},
        label: fmt(tr(context).rplan.outbox, {'name': row['name']}),
        orderKey: 'review:${row['student_id']}',
      );
      if (out.queued) messenger.showSnackBar(SnackBar(content: Text(kQueuedMessage)));
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e is PostgrestException ? e.message : '$e')));
    }
  }

  Future<void> _approveAll(List<Map<String, dynamic>> rows) async {
    final messenger = ScaffoldMessenger.of(context);
    var n = 0;
    for (final r in rows) {
      final plan = r['plan'] as Map<String, dynamic>;
      if (plan['approved'] == true || _pending(r['student_id'] as String)) continue;
      try {
        await SyncService.instance.submit('review_approve', {'p_org': _orgId, 'p_student': r['student_id']},
            label: fmt(currentStrings.rplan.outbox, {'name': r['name']}), orderKey: 'review:${r['student_id']}');
        n++;
      } catch (_) {}
    }
    messenger.showSnackBar(SnackBar(content: Text(fmt(currentStrings.rplan.approvedN, {'n': n}))));
    _reload();
  }

  Future<void> _recite(Map<String, dynamic> row) async {
    final grades = await RecitationRepository(Supabase.instance.client).fetchGrades(_orgId);
    if (!mounted) return;
    final plan = row['plan'] as Map<String, dynamic>;
    final points = await showRecitationSheet(context,
        studentId: row['student_id'] as String, studentName: row['name'] as String, grades: grades, initialType: 'distant_review', initialSurah: plan['surah_from'] as int);
    if (points != null && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final R = tr(context).rplan;
    context.watch<SyncService>();
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snap) {
        final rows = (snap.data ?? const []).cast<Map<String, dynamic>>();
        final waiting = rows.where((r) => (r['plan'] as Map)['approved'] != true && !_pending(r['student_id'] as String)).length;
        return Scaffold(
          appBar: AppBar(title: Text(R.title), actions: [
            if (waiting > 0) TextButton.icon(onPressed: () => _approveAll(rows), icon: const Icon(Icons.done_all_rounded), label: Text('${R.approveAll} ($waiting)')),
          ]),
          body: snap.hasError
              ? ErrorState(onRetry: _reload)
              : !snap.hasData
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async {
                        _reload();
                        await _future;
                      },
                      child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
                        Text(R.hint, style: const TextStyle(color: kInkMuted, fontSize: 12.5)),
                        const SizedBox(height: 12),
                        if (rows.isEmpty) Padding(padding: const EdgeInsets.only(top: 60), child: Center(child: Text(R.none, style: const TextStyle(color: kInkMuted)))),
                        for (var i = 0; i < rows.length; i++) ...[
                          if (i == 0 || rows[i]['circle_id'] != rows[i - 1]['circle_id'])
                            Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 8),
                              child: Text('${rows[i]['circle']}', style: const TextStyle(fontWeight: FontWeight.w800, color: kInkMuted)),
                            ),
                          _card(context, rows[i]),
                        ],
                      ]),
                    ),
        );
      },
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> row) {
    final R = tr(context).rplan;
    final p = row['plan'] as Map<String, dynamic>;
    final pending = _pending(row['student_id'] as String);
    final status = pending ? 'pending' : p['status'] as String;
    final color = switch (status) {
      'done' => TeacherStyle.success,
      'approved' => Theme.of(context).colorScheme.primary,
      'pending' => TeacherStyle.warning,
      _ => kInkMuted,
    };
    return GardenCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('${row['name']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
          GardenChip(R.status[status] ?? status, color: color),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.replay_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              fmt(R.range, {'from': ReviewPlanScreen.ref(p['surah_from'] as int, p['ayah_from'] as int), 'to': ReviewPlanScreen.ref(p['surah_to'] as int, p['ayah_to'] as int)}),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 24, top: 2),
          child: Text(
            [fmt(R.pagesN, {'n': p['pages'], 'a': p['page_from'], 'b': p['page_to']}), if (p['cycle_start'] == true && status == 'suggested') R.cycleStart].join('  ·  '),
            style: const TextStyle(fontSize: 12, color: kInkMuted),
          ),
        ),
        const SizedBox(height: 6),
        Row(children: [
          if (status == 'suggested')
            FilledButton.icon(onPressed: () => _approve(row), icon: const Icon(Icons.check_rounded, size: 18), label: Text(R.approve)),
          if (status != 'done') ...[
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () => _recite(row), icon: const Icon(Icons.mic_rounded, size: 18), label: Text(R.recite)),
          ],
        ]),
      ]),
    );
  }
}

/// Today's approved portion, for the student file and the family home.
class TodayReviewCard extends StatefulWidget {
  const TodayReviewCard({super.key, required this.studentId});
  final String studentId;

  static Future<Map<String, dynamic>?> load(SupabaseClient client, String orgId, String studentId) async =>
      (await SyncService.instance.raw('my-review:$orgId:$studentId', () => client.rpc('my_review_plan', params: {'p_org': orgId, 'p_student': studentId}))) as Map<String, dynamic>?;

  @override
  State<TodayReviewCard> createState() => _TodayReviewCardState();
}

class _TodayReviewCardState extends State<TodayReviewCard> {
  Future<Map<String, dynamic>?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orgId = context.read<TenantController>().active?.organization.id;
    if (_future == null && orgId != null) _future = TodayReviewCard.load(Supabase.instance.client, orgId, widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) return const SizedBox.shrink();
    final R = tr(context).rplan;
    return FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (context, snap) {
        final p = snap.data;
        if (p == null) return const SizedBox.shrink();
        final done = p['status'] == 'done';
        return GardenCard(
          margin: const EdgeInsets.only(top: 12),
          child: Row(children: [
            IconBubble(done ? Icons.task_alt_rounded : Icons.replay_rounded, color: done ? TeacherStyle.success : Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(R.today, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(fmt(R.range, {'from': ReviewPlanScreen.ref(p['surah_from'] as int, p['ayah_from'] as int), 'to': ReviewPlanScreen.ref(p['surah_to'] as int, p['ayah_to'] as int)})),
                Text(fmt(R.pagesN, {'n': p['pages'], 'a': p['page_from'], 'b': p['page_to']}), style: const TextStyle(fontSize: 12, color: kInkMuted)),
              ]),
            ),
            if (done) GardenChip(R.status['done'] ?? '', color: TeacherStyle.success),
          ]),
        );
      },
    );
  }
}
