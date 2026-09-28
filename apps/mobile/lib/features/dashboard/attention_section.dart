import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/offline/sync_service.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/ui.dart';
import '../gatherings/gatherings_repository.dart';
import '../reports/reports_repository.dart';
import '../../core/i18n/i18n.dart';

/// Admin dashboard: what needs a decision or a call today, and the week in
/// numbers - one RPC (`admin_attention`), cached so it still shows offline.
class AttentionSection extends StatefulWidget {
  const AttentionSection({super.key, required this.orgId});

  final String orgId;

  @override
  State<AttentionSection> createState() => _AttentionSectionState();
}

class _AttentionSectionState extends State<AttentionSection> {
  late Future<Map<String, dynamic>> _future = _load();
  late Future<Map<String, int>> _pending = _loadPending();

  Future<Map<String, int>> _loadPending() async {
    try {
      return await GatheringsRepository(AppSupabase.client).pendingReviews(widget.orgId);
    } catch (_) {
      return {'gatherings': 0, 'external': 0};
    }
  }

  Future<Map<String, dynamic>> _load() => SyncService.instance.cached<Map<String, dynamic>>(
        'attention:${widget.orgId}',
        () async => await AppSupabase.client.rpc('admin_attention', params: {'p_org': widget.orgId}),
        (j) => j as Map<String, dynamic>,
      );

  @override
  void didUpdateWidget(covariant AttentionSection old) {
    super.didUpdateWidget(old);
    if (old.orgId != widget.orgId) {
      _future = _load();
      _pending = _loadPending();
    }
  }

  Map<String, int> _pendingNow = const {};

  @override
  void initState() {
    super.initState();
    _pending.then((v) {
      if (mounted) setState(() => _pendingNow = v);
    });
  }

  List<Map<String, dynamic>> _list(dynamic v) => [for (final e in (v as List? ?? const [])) e as Map<String, dynamic>];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        final a = snap.data;
        if (a == null) return const SizedBox.shrink(); // not critical: the rest of the dashboard stands alone
        final week = a['week'] as Map<String, dynamic>;
        final pend = _pendingNow;
        final waiting = [
          (tr(context).dash.waitSerd, a['serd_submitted'] as int, '/serd'),
          (tr(context).dash.waitMarket, a['market_pending'] as int, '/market'),
          (tr(context).dash.waitGatherings, pend['gatherings'] ?? 0, '/gatherings'),
          (tr(context).dash.waitExternal, pend['external'] ?? 0, '/external-recitations'),
        ].where((w) => w.$2 > 0).toList();
        final inactive = _list(a['inactive_students']);
        final upcoming = _list(a['upcoming']);

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle(tr(context).dash.needsYou),
          if (waiting.isEmpty)
            Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text(tr(context).dash.nothingWaiting))
          else
            for (final w in waiting)
              Card(
                color: Colors.amber.shade50,
                child: ListTile(
                  dense: true,
                  title: Text(w.$1),
                  trailing: Text('${w.$2}', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.amber.shade900, fontSize: 16)),
                  onTap: () => context.push(w.$3),
                ),
              ),
          if (inactive.isNotEmpty) ...[
            SectionTitle(fmt(tr(context).dash.inactiveN, {'inactive_total': a['inactive_total']})),
            for (final s in inactive)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${s['name']}'),
                subtitle: Text('${s['circle'] ?? '—'} · ${s['last_at'] == null ? tr(context).dash.notYet : reportDay(s['last_at'])}'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => context.push('/students/${s['id']}/report'),
              ),
          ],
          SectionTitle(tr(context).dash.thisWeek),
          Wrap(spacing: 8, runSpacing: 8, children: [
            StatusChip(label: fmt(tr(context).dash.weekRecitations, {'recitations': week['recitations']}), color: Colors.green),
            StatusChip(label: fmt(tr(context).dash.weekReciting, {'reciting_students': week['reciting_students']}), color: Colors.blue),
            StatusChip(label: fmt(tr(context).dash.weekPoints, {'points': week['points']}), color: Colors.orange),
            StatusChip(label: fmt(tr(context).dash.weekAttendance, {'v': reportPct(week['attendance_rate'])}), color: Colors.teal),
          ]),
          if (upcoming.isNotEmpty) ...[
            SectionTitle(tr(context).dash.upcomingEvents),
            for (final e in upcoming)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_rounded),
                title: Text('${e['title']}'),
                subtitle: Text('${reportDay(e['start_date'])} · ${tr(context).dash.registered} ${e['registered']}${e['capacity'] != null ? '/${e['capacity']}' : ''}'),
                onTap: () => context.push('/calendar/${e['id']}'),
              ),
          ],
        ]);
      },
    );
  }
}
