import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/i18n/i18n.dart';
import '../../core/offline/sync_service.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/garden.dart';
import '../../core/widgets/ui.dart';
import '../profiles/profile_widgets.dart' show numText;
import '../recitation/recitation_repository.dart' show kAchievementTypes;

// The points system (0096) in the app: the teacher's add / deduct sheet (works offline - the
// outbox replays it with the same client_ref), and "how did I earn my points".

class PointReason {
  const PointReason({required this.id, required this.name, required this.points, required this.kind});
  final String id;
  final String name;
  final int points;
  final String kind; // bonus | penalty
  int get signed => kind == 'bonus' ? points : -points;
}

class PointsLedgerRepository {
  PointsLedgerRepository(this._client);
  final SupabaseClient _client;
  static const _uuid = Uuid();

  Future<List<PointReason>> reasons(String orgId) => SyncService.instance.cached<List<PointReason>>(
        'pt-reasons:$orgId',
        () => _client.from('point_reasons').select('id, name, points, kind').eq('organization_id', orgId).eq('is_active', true).order('sort_order'),
        (json) => [
          for (final r in json as List)
            PointReason(id: r['id'] as String, name: r['name'] as String, points: (r['points'] as num).toInt(), kind: r['kind'] as String),
        ],
      );

  Future<Map<String, dynamic>> breakdown(String orgId, String studentId) async =>
      (await SyncService.instance.raw('pt-breakdown:$orgId:$studentId',
          () => _client.rpc('get_student_points_breakdown', params: {'p_org': orgId, 'p_student': studentId}))) as Map<String, dynamic>;

  /// 'per_page' or 'per_recitation' - for the page estimate in the recitation sheet.
  Future<String> mode(String orgId) async {
    final v = await SyncService.instance.raw('pt-mode:$orgId', () => _client.rpc('points_mode', params: {'p_org': orgId}));
    return v == 'per_page' ? 'per_page' : 'per_recitation';
  }

  /// True when it was kept on the phone (no network) instead of reaching the server.
  Future<bool> award({required String orgId, required String studentId, required String studentName, required PointReason reason, String? note}) async {
    final outcome = await SyncService.instance.submit(
      'point_award',
      {
        'p_org': orgId,
        'p_student': studentId,
        'p_reason': reason.id,
        'p_note': (note ?? '').trim().isEmpty ? null : note!.trim(),
        'p_date': DateTime.now().toIso8601String().substring(0, 10),
        // fixed before the first try: a retry or the outbox replay is the same entry
        'p_client_ref': _uuid.v4(),
      },
      label: fmt(currentStrings.pts.outbox, {'name': studentName, 'points': reason.signed > 0 ? '+${reason.signed}' : '${reason.signed}'}),
    );
    return outcome.queued;
  }

  Future<void> undo(String orgId, String id) => _client.rpc('delete_point_adjustment', params: {'p_org': orgId, 'p_id': id});
}

/// The star sheet: two sections (add / deduct), the teacher picks a reason (never a number) and an
/// optional note. Returns the signed points saved, or null when closed.
Future<int?> showAwardPointsSheet(BuildContext context, {required String studentId, required String studentName}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _AwardSheet(studentId: studentId, studentName: studentName),
  );
}

class _AwardSheet extends StatefulWidget {
  const _AwardSheet({required this.studentId, required this.studentName});
  final String studentId;
  final String studentName;

  @override
  State<_AwardSheet> createState() => _AwardSheetState();
}

class _AwardSheetState extends State<_AwardSheet> {
  final _repo = PointsLedgerRepository(Supabase.instance.client);
  final _note = TextEditingController();
  late Future<List<PointReason>> _future;
  PointReason? _picked;
  bool _saving = false;
  String? _error;

  String get _orgId => context.read<TenantController>().active!.organization.id;

  @override
  void initState() {
    super.initState();
    _future = _repo.reasons(context.read<TenantController>().active!.organization.id);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final r = _picked;
    if (r == null) {
      setState(() => _error = tr(context).pts.pickReason);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final queued = await _repo.award(orgId: _orgId, studentId: widget.studentId, studentName: widget.studentName, reason: r, note: _note.text);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final p = r.signed > 0 ? '+${r.signed}' : '${r.signed}';
      Navigator.pop(context, r.signed);
      messenger.showSnackBar(SnackBar(content: Text(queued ? kQueuedMessage : fmt(tr(context).pts.saved, {'points': p, 'name': widget.studentName}))));
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e, tr(context).stu.saveError));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context).pts;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: FutureBuilder<List<PointReason>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
          final reasons = snap.data ?? const <PointReason>[];
          Widget section(String kind, String title, Color color) {
            final list = reasons.where((r) => r.kind == kind).toList();
            if (list.isEmpty) return const SizedBox.shrink();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final r in list)
                  ChoiceChip(
                    label: Text('${r.name}  ${r.signed > 0 ? '+${r.signed}' : r.signed}'),
                    selected: _picked?.id == r.id,
                    onSelected: (_) => setState(() => _picked = r),
                    showCheckmark: false,
                    selectedColor: color,
                    labelStyle: TextStyle(color: _picked?.id == r.id ? Colors.white : color, fontWeight: FontWeight.w700),
                    side: BorderSide(color: color.withValues(alpha: 0.4)),
                    backgroundColor: color.withValues(alpha: 0.06),
                  ),
              ]),
            ]);
          }

          return SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(t.award, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(widget.studentName, style: const TextStyle(color: kInkMuted)),
              if (reasons.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text(t.noReasons, style: const TextStyle(color: kInkMuted)))
              else ...[
                section('bonus', t.bonus, TeacherStyle.success),
                section('penalty', t.penalty, Colors.red.shade700),
                const SizedBox(height: 14),
                TextField(controller: _note, maxLength: 500, decoration: InputDecoration(labelText: t.note, counterText: '')),
                if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: TextStyle(color: Colors.red.shade700))],
                const SizedBox(height: 14),
                LoadingButton(label: t.save, loading: _saving, onPressed: _save),
              ],
            ]),
          );
        },
      ),
    );
  }
}

/// "How did I earn my points": every source, adding up to the total. On a staff screen it also
/// has the star button and the latest entries (with undo where the server allows it).
class StudentPointsCard extends StatefulWidget {
  const StudentPointsCard({super.key, required this.studentId, required this.studentName, this.mine = false});
  final String studentId;
  final String studentName;
  final bool mine;

  @override
  State<StudentPointsCard> createState() => _StudentPointsCardState();
}

class _StudentPointsCardState extends State<StudentPointsCard> {
  final _repo = PointsLedgerRepository(Supabase.instance.client);
  Future<Map<String, dynamic>>? _future;
  String? _orgId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final org = context.read<TenantController>().active?.organization.id;
    if (org != null && org != _orgId) {
      _orgId = org;
      _future = _repo.breakdown(org, widget.studentId);
    }
  }

  void _reload() => setState(() => _future = _repo.breakdown(_orgId!, widget.studentId));

  Future<void> _award() async {
    final saved = await showAwardPointsSheet(context, studentId: widget.studentId, studentName: widget.studentName);
    if (saved != null && mounted) _reload();
  }

  Future<void> _undo(String id) async {
    try {
      await _repo.undo(_orgId!, id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context).pts.undone)));
      _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e, tr(context).stu.saveError))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = tr(context);
    final t = s.pts;
    final active = context.watch<TenantController>().active;
    final canAward = !widget.mine && active != null && (active.role == OrgRole.admin || (active.role == OrgRole.teacher && active.permissions.contains('students')));
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        final d = snap.data;
        if (d == null) return const SizedBox.shrink();
        final rows = (d['rows'] as List? ?? const []).cast<Map<String, dynamic>>();
        final recent = (d['recent'] as List? ?? const []).cast<Map<String, dynamic>>().where((e) => e['source'] != 'opening').take(5).toList();
        final sm = (d['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
        final total = (d['total_points'] as num?)?.toInt() ?? 0;
        final sum = (d['rows_sum'] as num?)?.toInt() ?? 0;
        String signed(num n) => n > 0 ? '+$n' : '$n';
        String label(Map<String, dynamic> r) => switch (r['kind']) {
              'recitation' => '${kAchievementTypes[r['type']] ?? r['type']} — ${r['label'] ?? r['grade'] ?? ''}',
              'bonus' || 'penalty' => '${t.kinds[r['kind']]}: ${r['label'] ?? '—'}',
              _ => t.kinds[r['kind']] ?? '${r['kind']}',
            };
        return GardenCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.mine ? t.mineTitle : t.staffTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
              GardenChip(signed(total).replaceFirst('+', ''), color: TeacherStyle.brand(context)),
            ]),
            const SizedBox(height: 6),
            Text(
              fmt(t.sumLine, {'r': sm['recitations'] ?? 0, 'm': numText(sm['memorized_pages']), 'v': numText(sm['revision_pages']), 'a': sm['attended_days'] ?? 0, 'b': sm['absent_days'] ?? 0}),
              style: const TextStyle(fontSize: 12, color: kInkMuted),
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(t.noPoints, style: const TextStyle(color: kInkMuted))),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(label(r), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      Text(
                        (r['pages'] as num? ?? 0) > 0 ? fmt(t.countPages, {'count': r['count'], 'pages': numText(r['pages'])}) : fmt(t.count, {'count': r['count']}),
                        style: const TextStyle(fontSize: 11.5, color: kInkMuted),
                      ),
                    ]),
                  ),
                  Text(signed(r['points'] as num? ?? 0),
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontWeight: FontWeight.w800, color: (r['points'] as num? ?? 0) < 0 ? Colors.red.shade700 : kInk)),
                ]),
              ),
            if (rows.isNotEmpty) ...[
              const Divider(height: 16),
              Row(children: [
                Expanded(child: Text(t.total, style: const TextStyle(fontWeight: FontWeight.w800))),
                Text('$sum', textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
            ],
            if (sum != total && !widget.mine) ...[
              const SizedBox(height: 8),
              Text(fmt(t.mismatch, {'sum': sum, 'total': total}), style: const TextStyle(fontSize: 12, color: TeacherStyle.warning)),
            ],
            if (!widget.mine && recent.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(t.recent, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              for (final e in recent)
                Row(children: [
                  SizedBox(
                    width: 40,
                    child: Text(signed(e['points'] as num? ?? 0),
                        textDirection: TextDirection.ltr,
                        style: TextStyle(fontWeight: FontWeight.w800, color: (e['points'] as num? ?? 0) < 0 ? Colors.red.shade700 : TeacherStyle.success)),
                  ),
                  Expanded(child: Text('${e['label'] ?? '—'} · ${formatDate(e['occurred_on'] as String?)}', style: const TextStyle(fontSize: 12.5))),
                  if (e['can_delete'] == true) TextButton(onPressed: () => _undo(e['id'] as String), child: Text(t.undo)),
                ]),
            ],
            if (canAward) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: _award, icon: const Icon(Icons.star_outline_rounded, size: 18), label: Text(t.award)),
            ],
          ]),
        );
      },
    );
  }
}
