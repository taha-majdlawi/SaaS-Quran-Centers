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
  // how long reviewed recordings (0090) and chat pictures (0091) are kept: days, or 0 = never deleted; null = not loaded
  int? _audioDays;
  int? _chatDays;
  static const _audioChoices = [7, 14, 30, 60, 90, 180, 365];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final rows = (await AppSupabase.client.rpc('center_features', params: {'p_org': _orgId})) as List;
      final media = await AppSupabase.client.rpc('media_retention', params: {'p_org': _orgId}).catchError((_) => null);
      final items = [
        for (final r in rows.cast<Map<String, dynamic>>()) (key: r['key'] as String, available: r['available'] == true, enabled: r['enabled'] == true),
      ];
      if (!mounted) return;
      setState(() {
        _items = items;
        int? days(Object? v) => v == null ? 0 : (v is num && v > 0 ? v.toInt() : null);
        if (media is Map) {
          _audioDays = days(media['audio_days']);
          _chatDays = days(media['chat_days']);
        }
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
      final days = _audioDays, chat = _chatDays;
      if (days != null) {
        await AppSupabase.client.rpc('set_recitation_audio_days', params: {'p_org': _orgId, 'p_days': days == 0 ? null : days});
      }
      if (chat != null) {
        await AppSupabase.client.rpc('set_chat_image_days', params: {'p_org': _orgId, 'p_days': chat == 0 ? null : chat});
      }
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
                  if (_audioDays != null) ...[
                    const Divider(height: 28),
                    Text(t.audioTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(t.audioHint, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    const SizedBox(height: 10),
                    _daysPicker(_audioDays!, (v) => setState(() => _audioDays = v)),
                  ],
                  if (_chatDays != null) ...[
                    const SizedBox(height: 18),
                    Text(t.chatTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(t.chatHint, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    const SizedBox(height: 10),
                    _daysPicker(_chatDays!, (v) => setState(() => _chatDays = v)),
                  ],
                  const SizedBox(height: 12),
                  LoadingButton(label: t.save, icon: Icons.check_rounded, loading: _saving, onPressed: _save),
                ]),
    );
  }

  /// days to keep: the usual choices (and the current one), or 0 = never deleted
  Widget _daysPicker(int value, ValueChanged<int?> onChanged) {
    final t = tr(context).cfeat;
    return DropdownButtonFormField<int>(
      initialValue: value,
      items: [
        for (final n in {..._audioChoices, if (value > 0) value}.toList()..sort()) DropdownMenuItem(value: n, child: Text(fmt(t.audioDays, {'n': n}))),
        DropdownMenuItem(value: 0, child: Text(t.audioNever)),
      ],
      onChanged: onChanged,
    );
  }
}
