import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import 'serd_models.dart';
import 'serd_repository.dart';

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
          _message = 'تم الحفظ';
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
        const Chip(label: Text('الجزء كاملاً (دائمًا)')),
        for (final d in const [2, 4, 8])
          FilterChip(label: Text(kSerdDenNames[d]!), selected: selected.contains(d), onSelected: (v) => onChanged(d, v)),
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
          title: Text(existing == null ? 'نوع خطأ جديد' : 'تعديل نوع الخطأ'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')),
              const SizedBox(height: 10),
              TextField(controller: per, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'كل (عدد أخطاء)')),
              const SizedBox(height: 10),
              TextField(controller: pct, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '= خصم %')),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('فعّال'), value: active, onChanged: (v) => setLocal(() => active = v)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(minimumSize: const Size(90, 44)), child: const Text('حفظ')),
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
      setState(() { _message = 'أكمل الاسم والأرقام'; _isError = true; });
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
              const Text('المقادير المسموحة لهذه المرحلة'),
              const SizedBox(height: 8),
              _denChips(dens, (d, v) => setLocal(() => v ? dens.add(d) : dens.remove(d))),
              const SizedBox(height: 12),
              TextField(controller: pass, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'حد نجاح خاص % (اتركه فارغًا للعام)')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(minimumSize: const Size(90, 44)), child: const Text('حفظ')),
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
      appBar: AppBar(title: const Text('إعدادات السرد')),
      body: AsyncBody<_SettingsData>(
        future: _future,
        onRetry: () => setState(() => _future = _load()),
        builder: (context, data) {
          final policies = {for (final p in data.setup.stages) p.stageId: p};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('التغييرات تسري على السرد القادم فقط؛ السرد السابق يحتفظ بدرجته ونقاطه وحد نجاحه.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 12),
              if (_message != null) MessageBanner(message: _message!, isError: _isError),
              const SectionTitle('عام للمركز'),
              Row(children: [
                Expanded(child: TextField(controller: _pass, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'حد النجاح %'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _points, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'نقاط الجزء الكامل'))),
              ]),
              const SizedBox(height: 12),
              const Text('المقادير المسموحة افتراضيًا'),
              const SizedBox(height: 8),
              _denChips(_dens, (d, v) => setState(() => v ? _dens.add(d) : _dens.remove(d))),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final pass = num.tryParse(_pass.text.trim());
                  final pts = int.tryParse(_points.text.trim());
                  if (pass == null || pts == null) {
                    setState(() { _message = 'أدخل أرقامًا صحيحة'; _isError = true; });
                    return;
                  }
                  _run(() => _repository.saveSettings(_orgId, passPercent: pass, pointsPerJuz: pts, denominators: _dens.toList()));
                },
                child: const Text('حفظ الإعدادات العامة'),
              ),
              const SectionTitle('أنواع الأخطاء وأوزانها'),
              for (var i = 0; i < data.setup.errorTypes.length; i++)
                Card(
                  child: ListTile(
                    title: Text(data.setup.errorTypes[i].name),
                    subtitle: Text('كل ${data.setup.errorTypes[i].errorsPerUnit} = ${data.setup.errorTypes[i].percentPerUnit}%${data.setup.errorTypes[i].isActive ? '' : '  ·  غير فعّال'}'),
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
                label: const Text('نوع خطأ جديد'),
              ),
              const SectionTitle('حسب المرحلة'),
              Text('مرحلة الصغار قد تسرد نصف جزء أو ربعه ولها حد نجاح خاص.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 8),
              for (final st in data.stages)
                Card(
                  child: ListTile(
                    title: Text(st.name),
                    subtitle: Text(policies[st.id] == null
                        ? 'الإعداد العام'
                        : '${policies[st.id]!.denominators.map((d) => kSerdDenNames[d]).join('، ')}${policies[st.id]!.passPercent == null ? '' : '  ·  نجاح ${policies[st.id]!.passPercent}%'}'),
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
