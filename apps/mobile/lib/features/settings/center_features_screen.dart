import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/i18n.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';

/// The center admin switches the center's features (center_features / set_center_features, 0088):
/// what the plan includes is on by default; anything can be switched off and back on, never beyond the plan.
class CenterFeaturesScreen extends StatefulWidget {
  const CenterFeaturesScreen({super.key});

  @override
  State<CenterFeaturesScreen> createState() => _CenterFeaturesScreenState();
}

class _CenterFeaturesScreenState extends State<CenterFeaturesScreen> {
  late final String _orgId = context.read<TenantController>().active!.organization.id;
  List<({String key, bool available, bool enabled})>? _items;
  final _on = <String, bool>{};
  bool _saving = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final rows = (await AppSupabase.client.rpc('center_features', params: {'p_org': _orgId})) as List;
      final items = [
        for (final r in rows.cast<Map<String, dynamic>>()) (key: r['key'] as String, available: r['available'] == true, enabled: r['enabled'] == true),
      ];
      if (!mounted) return;
      setState(() {
        _items = items;
        for (final i in items) {
          _on[i.key] = i.enabled;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _save() async {
    final t = currentStrings.cfeat;
    setState(() => _saving = true);
    try {
      final off = [for (final i in _items!) if (i.available && _on[i.key] != true) i.key];
      await AppSupabase.client.rpc('set_center_features', params: {'p_org': _orgId, 'p_off': off});
      if (!mounted) return;
      await context.read<TenantController>().refreshDisabled();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.saved)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e, currentStrings.live.error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context).cfeat;
    final items = _items;
    return Scaffold(
      appBar: AppBar(title: Text(t.tab)),
      body: _error != null
          ? ErrorState(onRetry: _load)
          : items == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
                  Text(t.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(t.hint, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  const SizedBox(height: 8),
                  for (final i in items)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.names[i.key] ?? i.key),
                      subtitle: i.available ? null : Text(t.notInPlan, style: const TextStyle(fontSize: 12)),
                      value: i.available && (_on[i.key] ?? false),
                      onChanged: i.available ? (v) => setState(() => _on[i.key] = v) : null,
                    ),
                  const SizedBox(height: 12),
                  LoadingButton(label: t.save, icon: Icons.check_rounded, loading: _saving, onPressed: _save),
                ]),
    );
  }
}
