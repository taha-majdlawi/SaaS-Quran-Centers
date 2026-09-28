import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import 'serd_models.dart';
import 'serd_repository.dart';
import '../../core/i18n/i18n.dart';

/// Admin report over a date range; every figure measures APPROVED sessions.
class SerdReportScreen extends StatefulWidget {
  const SerdReportScreen({super.key});

  @override
  State<SerdReportScreen> createState() => _SerdReportScreenState();
}

class _SerdReportScreenState extends State<SerdReportScreen> {
  final _repository = SerdRepository(AppSupabase.client);
  late Future<SerdReport> _future = _load();
  DateTime? _from;
  DateTime? _to;

  Future<SerdReport> _load() =>
      _repository.report(context.read<TenantController>().active!.organization.id, from: _from, to: _to);

  Future<void> _pick(bool from) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (from) {
          _from = picked;
        } else {
          _to = picked;
        }
        _future = _load();
      });
    }
  }

  String _d(DateTime? d, String fallback) => d == null ? fallback : '${d.year}/${d.month}/${d.day}';

  Widget _kpi(String label, String value) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ]),
        ),
      );

  Widget _list(String title, List<Map<String, dynamic>> items, String Function(Map<String, dynamic>) label, String valueKey) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (items.isEmpty) Text('—', style: TextStyle(color: Colors.grey.shade500)),
            for (final e in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [Expanded(child: Text(label(e))), Text('${e[valueKey]}', style: const TextStyle(fontWeight: FontWeight.w800))]),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context).serd.reportTitle)),
      body: AsyncBody<SerdReport>(
        future: _future,
        onRetry: () => setState(() => _future = _load()),
        builder: (context, r) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => _pick(true), child: Text(fmt(tr(context).cal.fromV, {'v': _d(_from, r.raw['from'] as String)})))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton(onPressed: () => _pick(false), child: Text(fmt(tr(context).cal.toV, {'v': _d(_to, r.raw['to'] as String)})))),
            ]),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _kpi(tr(context).serd.totalSessions, '${r.total}'),
                _kpi(tr(context).serd.approvedChip, '${r.approved}'),
                _kpi(tr(context).serd.waiting, '${r.pending}'),
                _kpi(tr(context).serd.rejectedChip, '${r.rejected}'),
                _kpi(tr(context).serd.avgScore, r.averageScore == null ? '—' : '${r.averageScore}%'),
                _kpi(tr(context).serd.pointsGiven, '${r.points}'),
              ],
            ),
            const SizedBox(height: 12),
            _list(tr(context).serd.approvedParts, r.list('by_juz'), (e) => fmt(tr(context).serd.juzLine, {'juz': e['juz'], 'v': kJuzNames[(e['juz'] as num).toInt() - 1]}), 'count'),
            const SizedBox(height: 10),
            _list(tr(context).serd.topErrors, r.list('by_error_type'), (e) => e['name'] as String, 'total'),
            const SizedBox(height: 10),
            _list(tr(context).serd.examiners, r.list('by_examiner'), (e) => e['name'] as String, 'count'),
          ],
        ),
      ),
    );
  }
}
