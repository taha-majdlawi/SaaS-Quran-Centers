import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import 'serd_models.dart';
import 'serd_repository.dart';
import '../../core/i18n/i18n.dart';

class _SettingsData {
  const _SettingsData(this.setup, this.stages);
  final SerdSetup setup;
  final List<({String id, String name})> stages;
}

/// Admin: pass mark, points per juz, allowed amounts, error weights and the
/// per-stage overrides. Changes apply to FUTURE sessions only (freeze rule) and
/// are written to the audit log by the server.
class SerdSettingsScreen extends StatefulWidget {
  const SerdSettingsScreen({super.key});

  @override
  State<SerdSettingsScreen> createState() => _SerdSettingsScreenState();
}

class _SerdSettingsScreenState extends State<SerdSettingsScreen> {
  final _repository = SerdRepository(AppSupabase.client);
  late Future<_SettingsData> _future = _load();
  final _pass = TextEditingController();
  final _points = TextEditingController();
  Set<int> _dens = {};
  String? _message;
  bool _isError = false;
  bool _initialized = false;

  String get _orgId => context.read<TenantController>().active!.organization.id;

  Future<_SettingsData> _load() async {
    final results = await Future.wait<dynamic>([_repository.fetchSetup(_orgId), _repository.fetchStages(_orgId)]);
    final setup = results[0] as SerdSetup;
    if (!_initialized) {
      _pass.text = '${setup.passPercent}';
      _points.text = '${setup.pointsPerJuz}';
      _dens = setup.defaultDenominators.where((d) => d != 1).toSet();
      _initialized = true;
    }
    return _SettingsData(setup, results[1] as List<({String id, String name})>);
  }

  @override
  void dispose() {
    _pass.dispose();
    _points.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _message = null);
    try {
      await action();
      if (mounted) {
        setState(() {
          _message = tr(context).serd.saved;
          _isError = false;
          _future = _load();
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) setState(() { _message = e.message; _isError = true; });
    }
  }

  Widget _denChips(Set<int> selected, void Function(int, bool) onChanged) {
    return Wrap(
      spacing: 8,
      children: [
        Chip(label: Text(tr(context).serd.wholeAlways)),
        for (final d in const [2, 4, 8])
          FilterChip(label: Text(serdDenName(d)), selected: selected.contains(d), onSelected: (v) => onChanged(d, v)),
      ],
    );
  }

  Future<void> _editErrorType(SerdErrorType? existing, int nextOrder) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final per = TextEditingController(text: '${existing?.errorsPerUnit ?? 3}');
    final pct = TextEditingController(text: '${existing?.percentPerUnit ?? 1}');
    var active = existing?.isActive ?? true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(existing == null ? tr(context).serd.newErrorType : tr(context).serd.editErrorType),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: InputDecoration(labelText: tr(context).serd.name)),
              const SizedBox(height: 10),
              TextField(controller: per, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr(context).serd.perErrors)),
              const SizedBox(height: 10),
              TextField(controller: pct, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: tr(context).serd.deductPct)),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(tr(context).serd.active), value: active, onChanged: (v) => setLocal(() => active = v)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).common.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(minimumSize: Size(90, 44)), child: Text(tr(context).common.save)),
          ],
        ),
      ),
    );
    final values = (name.text.trim(), int.tryParse(per.text.trim()), num.tryParse(pct.text.trim()));
    name.dispose();
    per.dispose();
    pct.dispose();
    if (ok != true) return;
    if (values.$1.isEmpty || values.$2 == null || values.$3 == null) {
      setState(() { _message = tr(context).serd.fillAll; _isError = true; });
      return;
    }
    await _run(() => _repository.saveErrorType(
          _orgId,
          id: existing?.id,
          name: values.$1,
          errorsPerUnit: values.$2!,
          percentPerUnit: values.$3!,
          isActive: active,
          sortOrder: nextOrder,
        ));
  }

  Future<void> _editStage(({String id, String name}) stage, SerdStagePolicy? policy) async {
    var dens = (policy?.denominators ?? const <int>[]).where((d) => d != 1).toSet();
    final pass = TextEditingController(text: policy?.passPercent == null ? '' : '${policy!.passPercent}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(stage.name),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr(context).serd.stagePortions),
              const SizedBox(height: 8),
              _denChips(dens, (d, v) => setLocal(() => v ? dens.add(d) : dens.remove(d))),
              const SizedBox(height: 12),
              TextField(controller: pass, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: tr(context).serd.stagePass)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).common.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(minimumSize: Size(90, 44)), child: Text(tr(context).common.save)),
          ],
        ),
      ),
    );
    final passText = pass.text.trim();
    pass.dispose();
    if (ok != true) return;
    await _run(() => _repository.saveStagePolicy(_orgId, stage.id, denominators: dens.toList(), passPercent: passText.isEmpty ? null : num.tryParse(passText)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context).serd.settingsTitle)),
      body: AsyncBody<_SettingsData>(
        future: _future,
        onRetry: () => setState(() => _future = _load()),
        builder: (context, data) {
          final policies = {for (final p in data.setup.stages) p.stageId: p};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(tr(context).serd.settingsHint, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 12),
              if (_message != null) MessageBanner(message: _message!, isError: _isError),
              SectionTitle(tr(context).serd.general),
              Row(children: [
                Expanded(child: TextField(controller: _pass, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: tr(context).serd.passPct))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _points, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr(context).serd.wholePoints))),
              ]),
              const SizedBox(height: 12),
              Text(tr(context).serd.defaultPortions),
              const SizedBox(height: 8),
              _denChips(_dens, (d, v) => setState(() => v ? _dens.add(d) : _dens.remove(d))),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final pass = num.tryParse(_pass.text.trim());
                  final pts = int.tryParse(_points.text.trim());
                  if (pass == null || pts == null) {
                    setState(() { _message = tr(context).serd.wholeNumbers; _isError = true; });
                    return;
                  }
                  _run(() => _repository.saveSettings(_orgId, passPercent: pass, pointsPerJuz: pts, denominators: _dens.toList()));
                },
                child: Text(tr(context).serd.saveGeneral),
              ),
              SectionTitle(tr(context).serd.errorTypes),
              for (var i = 0; i < data.setup.errorTypes.length; i++)
                Card(
                  child: ListTile(
                    title: Text(data.setup.errorTypes[i].name),
                    subtitle: Text(fmt(tr(context).serd.perRule, {'errorsPerUnit': data.setup.errorTypes[i].errorsPerUnit, 'percentPerUnit': data.setup.errorTypes[i].percentPerUnit, 'v': data.setup.errorTypes[i].isActive ? '' : tr(context).serd.inactiveSuffix})),
                    onTap: () => _editErrorType(data.setup.errorTypes[i], i + 1),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _run(() => _repository.deleteErrorType(_orgId, data.setup.errorTypes[i].id)),
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => _editErrorType(null, data.setup.errorTypes.length + 1),
                icon: const Icon(Icons.add_rounded),
                label: Text(tr(context).serd.newErrorType),
              ),
              SectionTitle(tr(context).serd.byStage),
              Text(tr(context).serd.byStageHint, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 8),
              for (final st in data.stages)
                Card(
                  child: ListTile(
                    title: Text(st.name),
                    subtitle: Text(policies[st.id] == null
                        ? tr(context).serd.usesGeneral
                        : '${policies[st.id]!.denominators.map(serdDenName).join(tr(context).common.listSep)}${policies[st.id]!.passPercent == null ? '' : fmt(tr(context).serd.passSuffix, {'n': policies[st.id]!.passPercent})}'),
                    trailing: const Icon(Icons.chevron_left_rounded),
                    onTap: () => _editStage(st, policies[st.id]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
