import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/ui.dart';
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
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle(tr(context).dash.dropoutRisk),
          if (risk.isEmpty)
            Text(tr(context).dash.noRisk)
          else
            for (final r in risk)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${r['name']}'),
                subtitle: Text('${r['circle'] ?? '—'} · ${fmt(tr(context).dash.idleDays, {'n': r['idle_days']})}'),
                trailing: Chip(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                  backgroundColor: Colors.amber.withValues(alpha: 0.2),
                  label: Text(_riskTags[r['tag']] ?? '${r['tag']}', style: const TextStyle(fontSize: 11)),
                ),
                onTap: () => context.push('/students/${r['id']}/report'),
              ),
          if (perf.isNotEmpty) ...[
            SectionTitle(tr(context).dash.teacherPerf),
            for (final p in perf)
              Card(
                child: ListTile(
                  dense: true,
                  title: Text('${p['name'] ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(fmt(tr(context).dash.perfLine, {'circles': p['circles'], 'students': p['students'], 'days': p['check_ins']}), style: TextStyle(color: scheme.outline, fontSize: 12)),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${p['recitations']}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: scheme.primary)),
                    Text(tr(context).dash.recitationsWord, style: TextStyle(fontSize: 10.5, color: scheme.outline)),
                  ]),
                ),
              ),
          ],
        ]);
      },
    );
  }
}
