import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/garden.dart';
import '../insights/insights_repository.dart';
import '../../core/i18n/i18n.dart';

Map<String, String> get _riskTags => currentStrings.dash.riskTags;

/// Admin dashboard: students at risk of dropping out (with the reason) and a week of teacher activity.
class AdminInsightsSection extends StatefulWidget {
  const AdminInsightsSection({super.key, required this.orgId});

  final String orgId;

  @override
  State<AdminInsightsSection> createState() => _AdminInsightsSectionState();
}

class _AdminInsightsSectionState extends State<AdminInsightsSection> {
  final _repository = InsightsRepository(AppSupabase.client);
  late Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)> _future = _load();

  Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>)> _load() async {
    final r = await Future.wait([_repository.dropoutRisk(widget.orgId), _repository.teacherPerformance(widget.orgId)]);
    return (r[0], r[1]);
  }

  @override
  void didUpdateWidget(covariant AdminInsightsSection old) {
    super.didUpdateWidget(old);
    if (old.orgId != widget.orgId) _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        final d = snap.data;
        if (d == null) return const SizedBox.shrink();
        final risk = d.$1;
        final perf = d.$2;
        final t = tr(context);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GardenSection(
            title: t.dash.dropoutRisk,
            icon: Icons.warning_amber_rounded,
            child: GardenCard(
              padding: EdgeInsets.symmetric(vertical: risk.isEmpty ? 16 : 4, horizontal: risk.isEmpty ? 16 : 0),
              child: risk.isEmpty
                  ? Text(t.dash.noRisk)
                  : Column(children: [
                      for (final r in risk)
                        ListTile(
                          dense: true,
                          title: Text('${r['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${r['circle'] ?? '—'} · ${fmt(t.dash.idleDays, {'n': r['idle_days']})}'),
                          trailing: GardenChip(_riskTags[r['tag']] ?? '${r['tag']}', color: const Color(0xFFB26A00)),
                          onTap: () => context.push('/students/${r['id']}/report'),
                        ),
                    ]),
            ),
          ),
          if (perf.isNotEmpty)
            GardenSection(
              title: t.dash.teacherPerf,
              icon: Icons.school_rounded,
              child: GardenCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(children: [
                  for (final p in perf)
                    ListTile(
                      dense: true,
                      title: Text('${p['name'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(fmt(t.dash.perfLine, {'circles': p['circles'], 'students': p['students'], 'days': p['check_ins']}), style: TextStyle(color: scheme.outline, fontSize: 12)),
                      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${p['recitations']}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: scheme.primary)),
                        Text(t.dash.recitationsWord, style: TextStyle(fontSize: 10.5, color: scheme.outline)),
                      ]),
                    ),
                ]),
              ),
            ),
        ]);
      },
    );
  }
}
