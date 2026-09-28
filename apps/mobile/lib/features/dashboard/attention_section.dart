import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/offline/sync_service.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/garden.dart';
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

        final t = tr(context);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GardenSection(
            title: t.dash.needsYou,
            icon: Icons.notifications_active_rounded,
            child: waiting.isEmpty
                ? GardenCard(
                    child: Row(children: [
                      const IconBubble(Icons.task_alt_rounded, color: Color(0xFF16835A), size: 36),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t.dash.nothingWaiting, style: const TextStyle(fontWeight: FontWeight.w600))),
                    ]),
                  )
                : Column(children: [
                    for (final w in waiting)
                      GardenCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        onTap: () => context.push(w.$3),
                        child: Row(children: [
                          const IconBubble(Icons.pending_actions_rounded, color: Color(0xFFB26A00), size: 36),
                          const SizedBox(width: 10),
                          Expanded(child: Text(w.$1, style: const TextStyle(fontWeight: FontWeight.w700))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFB26A00), borderRadius: BorderRadius.circular(20)),
                            child: Text('${w.$2}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          ),
                        ]),
                      ),
                  ]),
          ),
          GardenSection(
            title: t.dash.thisWeek,
            icon: Icons.insights_rounded,
            child: GardenCard(
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                GardenChip(fmt(t.dash.weekRecitations, {'recitations': week['recitations']}), color: const Color(0xFF16835A), icon: Icons.menu_book_rounded),
                GardenChip(fmt(t.dash.weekReciting, {'reciting_students': week['reciting_students']}), color: const Color(0xFF1877C9), icon: Icons.people_alt_rounded),
                GardenChip(fmt(t.dash.weekPoints, {'points': week['points']}), color: const Color(0xFFB26A00), icon: Icons.stars_rounded),
                GardenChip(fmt(t.dash.weekAttendance, {'v': reportPct(week['attendance_rate'])}), color: const Color(0xFF0E7C86), icon: Icons.how_to_reg_rounded),
              ]),
            ),
          ),
          if (inactive.isNotEmpty)
            GardenSection(
              title: fmt(t.dash.inactiveN, {'inactive_total': a['inactive_total']}),
              icon: Icons.hourglass_bottom_rounded,
              child: GardenCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: [
                  for (final s in inactive)
                    ListTile(
                      dense: true,
                      title: Text('${s['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${s['circle'] ?? '—'} · ${s['last_at'] == null ? t.dash.notYet : reportDay(s['last_at'])}'),
                      trailing: Icon(forwardChevron(context), color: Colors.grey.shade400),
                      onTap: () => context.push('/students/${s['id']}/report'),
                    ),
                ]),
              ),
            ),
          if (upcoming.isNotEmpty)
            GardenSection(
              title: t.dash.upcomingEvents,
              icon: Icons.event_rounded,
              child: GardenCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: [
                  for (final e in upcoming)
                    ListTile(
                      dense: true,
                      leading: const IconBubble(Icons.event_rounded, size: 34, color: Color(0xFF6D4AA8)),
                      title: Text('${e['title']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${reportDay(e['start_date'])} · ${t.dash.registered} ${e['registered']}${e['capacity'] != null ? '/${e['capacity']}' : ''}'),
                      onTap: () => context.push('/calendar/${e['id']}'),
                    ),
                ]),
              ),
            ),
        ]);
      },
    );
  }
}
