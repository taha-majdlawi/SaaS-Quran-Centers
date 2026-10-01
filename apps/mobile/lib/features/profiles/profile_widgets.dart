import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/quran_data.dart';
import '../../core/i18n/i18n.dart';
import '../../core/offline/sync_service.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/garden.dart';
import 'profiles_repository.dart';

num? _n(dynamic v) => v is num ? v : num.tryParse('${v ?? ''}');

String numText(dynamic v) {
  final n = _n(v);
  if (n == null) return '—';
  final r = (n * 10).round() / 10;
  return r == r.roundToDouble() ? '${r.round()}' : '$r';
}

/// "↑ 12%" in green, "↓ 5%" in red, or "→ no change"; percentage points for rates.
class DeltaText extends StatelessWidget {
  const DeltaText({super.key, required this.now, required this.prev, this.points = false});

  final dynamic now;
  final dynamic prev;
  final bool points;

  @override
  Widget build(BuildContext context) {
    final t = tr(context).prof;
    final a = _n(now), b = _n(prev);
    if (a == null || b == null) return const SizedBox.shrink();
    final diff = ((a - b) * 10).round() / 10;
    if (diff == 0) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.trending_flat_rounded, size: 15, color: kInkMuted),
        const SizedBox(width: 2),
        Text(t.same, style: const TextStyle(fontSize: 11, color: kInkMuted, fontWeight: FontWeight.w700)),
      ]);
    }
    final up = diff > 0;
    final color = up ? TeacherStyle.success : TeacherStyle.danger;
    final text = points ? '${up ? '+' : ''}${numText(diff)}' : (b == 0 ? t.newV : '${up ? '+' : ''}${(diff / b * 100).round()}%');
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14, color: color),
      const SizedBox(width: 1),
      Text(text, textDirection: TextDirection.ltr, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
    ]);
  }
}

/// One number of the period, with its change from the period before.
class ProfileStat extends StatelessWidget {
  const ProfileStat({super.key, required this.icon, required this.label, required this.value, this.color, this.now, this.prev, this.points = false});

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final dynamic now;
  final dynamic prev;
  final bool points;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return GardenCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 17, color: c),
          const SizedBox(width: 6),
          Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: kInkMuted, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c)),
          const SizedBox(width: 6),
          if (prev != null) Padding(padding: const EdgeInsets.only(bottom: 4), child: DeltaText(now: now, prev: prev, points: points)),
        ]),
      ]),
    );
  }
}

/// Two columns of [ProfileStat]s.
class ProfileStatGrid extends StatelessWidget {
  const ProfileStatGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.15,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: children,
      );
}

/// This month / last month / last 3 months.
class PeriodPicker extends StatelessWidget {
  const PeriodPicker({super.key, required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = tr(context).prof;
    final brand = Theme.of(context).colorScheme.primary;
    return Row(children: [
      for (final (k, label) in [('month', t.thisMonth), ('last_month', t.lastMonth), ('90', t.last90)]) ...[
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: ChoiceChip(
            label: Text(label),
            selected: value == k,
            showCheckmark: false,
            selectedColor: brand,
            labelStyle: TextStyle(color: value == k ? Colors.white : kInk, fontWeight: FontWeight.w700, fontSize: 12.5),
            onSelected: (_) => onChanged(k),
          ),
        ),
      ],
    ]);
  }
}

String relDay(BuildContext context, String? iso) {
  final t = tr(context).prof;
  if (iso == null) return t.never;
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return t.never;
  final days = DateTime.now().difference(d).inDays;
  if (days <= 0) return t.today;
  if (days < 30) return fmt(t.daysAgo, {'n': days});
  return formatDate(iso);
}

String passage(Map<String, dynamic> r) {
  final s = r['surah_from'] as int?;
  if (s == null) return '—';
  final s2 = r['surah_to'] as int?;
  if (s2 == null || s2 == s) return '${surahName(s)} (${r['ayah_from']}–${r['ayah_to']})';
  return '${surahName(s)} ${r['ayah_from']} ← ${surahName(s2)} ${r['ayah_to']}';
}

/// The latest recitations (with the student's name when [showStudent]).
class RecentRecitations extends StatelessWidget {
  const RecentRecitations({super.key, required this.rows, required this.grades, this.showStudent = true, this.onStudent, this.limit = 15});
  final List<dynamic> rows;
  final Map<String, String> grades;
  final bool showStudent;
  final void Function(String studentId)? onStudent;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    if (rows.isEmpty) return GardenCard(child: Text(t.prof.nothing, style: const TextStyle(color: kInkMuted)));
    return GardenCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: [
        for (final r in rows.take(limit).cast<Map<String, dynamic>>())
          ListTile(
            dense: true,
            onTap: showStudent && onStudent != null && r['student_id'] != null ? () => onStudent!(r['student_id'] as String) : null,
            title: Text(showStudent ? '${r['student'] ?? '—'}' : passage(r), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              [if (showStudent) passage(r), t.labels.recitationType[r['type']] ?? '${r['type']}', formatDate(r['at'] as String?)].join('  ·  '),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(grades['${r['grade']}'] ?? '${r['grade'] ?? '—'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              Text('+${r['points']}', style: const TextStyle(fontSize: 11.5, color: TeacherStyle.success, fontWeight: FontWeight.w800)),
            ]),
          ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// memorization goal
// ---------------------------------------------------------------------------

/// Pages memorized, real pace vs the goal, ahead / behind, and the expected
/// khatm. Offers "set goal" when the viewer may edit it.
class GoalCard extends StatefulWidget {
  const GoalCard({super.key, required this.studentId, required this.studentName});
  final String studentId;
  final String studentName;

  @override
  State<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<GoalCard> {
  final _repo = ProfilesRepository(Supabase.instance.client);
  Future<Map<String, dynamic>>? _future;
  String? _orgId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final org = context.read<TenantController>().active?.organization.id;
    if (org != null && org != _orgId) {
      _orgId = org;
      _future = _repo.goal(org, widget.studentId);
    }
  }

  void _reload() => setState(() => _future = _repo.goal(_orgId!, widget.studentId));

  Future<void> _edit(Map<String, dynamic>? goal) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _GoalSheet(repo: _repo, orgId: _orgId!, studentId: widget.studentId, studentName: widget.studentName, goal: goal),
    );
    if (saved == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context).prof;
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        final g = snap.data;
        if (g == null) return const SizedBox.shrink();
        final goal = g['goal'] as Map<String, dynamic>?;
        final pending = SyncService.instance.pendingOf('student_goal').where((i) => i.payload['p_student'] == widget.studentId).lastOrNull;
        final target = _n(goal?['target_pages']) ?? 604;
        final memorized = _n(g['memorized_pages']) ?? 0;
        final status = g['status'] as String?;
        final brand = Theme.of(context).colorScheme.primary;
        final statusColor = switch (status) {
          'ahead' || 'done' => TeacherStyle.success,
          'behind' => TeacherStyle.warning,
          _ => brand,
        };
        Widget fact(String label, String value, {Color? color}) => Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: kInkMuted)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color ?? kInk)),
              ]),
            );
        return GardenCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.flag_rounded, color: brand, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(t.goalTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
              if (status != null) GardenChip(t.goalStatus[status] ?? status, color: statusColor),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text(fmt(t.memorized, {'n': numText(memorized), 'total': numText(target)}), style: const TextStyle(fontWeight: FontWeight.w700))),
              Text(fmt(t.percentQuran, {'p': numText(g['memorized_percent'])}), style: const TextStyle(fontSize: 12, color: kInkMuted)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: (memorized / target).clamp(0, 1).toDouble(), minHeight: 10, backgroundColor: kHairline, color: brand),
            ),
            const SizedBox(height: 14),
            Row(children: [
              fact(t.pace, (_n(g['pace']) ?? 0) > 0 ? fmt(t.paceV, {'n': numText(g['pace'])}) : '—'),
              fact(t.goalPace, goal == null ? '—' : fmt(t.goalPaceV, {'n': numText(goal['pages_per_day'])})),
            ]),
            if (goal != null && g['expected_since_start'] != null) ...[
              const SizedBox(height: 10),
              Text(fmt(t.sinceStart, {'actual': numText(g['actual_since_start']), 'expected': numText(g['expected_since_start'])}),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 10),
            Row(children: [
              fact(t.forecast, status == 'done' ? (t.goalStatus['done'] ?? '') : g['forecast_date'] == null ? t.noPace : formatDate(g['forecast_date'] as String?), color: brand),
              if (goal != null && status != 'done') fact(t.forecastGoal, g['goal_date'] == null ? '—' : formatDate(g['goal_date'] as String?)),
            ]),
            if (goal?['note'] != null) ...[
              const SizedBox(height: 10),
              Text('${goal!['note']}', style: const TextStyle(fontSize: 12.5, color: kInkMuted)),
            ],
            if (goal == null && pending == null) ...[
              const SizedBox(height: 8),
              Text(t.noGoal, style: const TextStyle(fontSize: 12.5, color: kInkMuted)),
            ],
            if (pending != null) ...[
              const SizedBox(height: 8),
              GardenChip('${fmt(t.goalPaceV, {'n': numText(pending.payload['p_pages_per_day'])})} · ${tr(context).ui.savedOffline}', color: TeacherStyle.warning, icon: Icons.cloud_upload_rounded),
            ],
            if (g['can_edit'] == true) ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(onPressed: () => _edit(goal), icon: const Icon(Icons.edit_rounded, size: 18), label: Text(goal == null ? t.setGoal : t.editGoal)),
              ),
            ],
          ]),
        );
      },
    );
  }
}

class _GoalSheet extends StatefulWidget {
  const _GoalSheet({required this.repo, required this.orgId, required this.studentId, required this.studentName, this.goal});
  final ProfilesRepository repo;
  final String orgId;
  final String studentId;
  final String studentName;
  final Map<String, dynamic>? goal;

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late double _pages = (_n(widget.goal?['pages_per_day']) ?? 1).toDouble();
  late final _target = TextEditingController(text: '${widget.goal?['target_pages'] ?? 604}');
  late final _note = TextEditingController(text: '${widget.goal?['note'] ?? ''}');
  late final _review = TextEditingController(text: widget.goal?['review_pages_per_day'] == null ? '' : numText(widget.goal!['review_pages_per_day']));
  bool _saving = false;
  String? _error;

  static const _presets = [0.5, 1.0, 1.5, 2.0, 3.0];

  @override
  void dispose() {
    _target.dispose();
    _note.dispose();
    _review.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = tr(context).prof;
    final target = int.tryParse(_target.text.trim()) ?? 604;
    if (_pages < 0.25 || _pages > 20 || target < 1 || target > 604) {
      setState(() => _error = t.invalidPages);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final out = await widget.repo.setGoal(widget.orgId, widget.studentId,
          pagesPerDay: _pages,
          targetPages: target,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          reviewPages: double.tryParse(_review.text.trim()),
          label: fmt(t.outboxGoal, {'name': widget.studentName}));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(out.queued ? kQueuedMessage : t.goalSaved)));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e'.replaceFirst(RegExp(r'^.*?message: '), '').split(', code:').first);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clear() async {
    setState(() => _saving = true);
    try {
      await widget.repo.clearGoal(widget.orgId, widget.studentId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context).prof;
    final brand = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.goal == null ? t.setGoal : t.editGoal, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        Text(widget.studentName, style: const TextStyle(color: kInkMuted)),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: TeacherStyle.danger))),
        const SizedBox(height: 16),
        Text(t.pagesPerDay, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final p in _presets)
            ChoiceChip(
              label: Text(numText(p)),
              selected: _pages == p,
              showCheckmark: false,
              selectedColor: brand,
              labelStyle: TextStyle(color: _pages == p ? Colors.white : kInk, fontWeight: FontWeight.w800),
              onSelected: (_) => setState(() => _pages = p),
            ),
        ]),
        Row(children: [
          IconButton(onPressed: () => setState(() => _pages = ((_pages - 0.25).clamp(0.25, 20) * 100).round() / 100), icon: const Icon(Icons.remove_circle_outline_rounded)),
          Text(numText(_pages), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: brand)),
          IconButton(onPressed: () => setState(() => _pages = ((_pages + 0.25).clamp(0.25, 20) * 100).round() / 100), icon: const Icon(Icons.add_circle_outline_rounded)),
        ]),
        const SizedBox(height: 8),
        TextField(controller: _target, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t.targetPages)),
        const SizedBox(height: 10),
        TextField(controller: _review, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: tr(context).rplan.reviewPages)),
        const SizedBox(height: 10),
        TextField(controller: _note, maxLength: 300, decoration: InputDecoration(labelText: t.note)),
        const SizedBox(height: 8),
        FilledButton(onPressed: _saving ? null : _save, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)), child: Text(t.save)),
        if (widget.goal != null)
          TextButton(onPressed: _saving ? null : _clear, child: Text(t.clearGoal, style: const TextStyle(color: TeacherStyle.danger))),
      ]),
    );
  }
}
