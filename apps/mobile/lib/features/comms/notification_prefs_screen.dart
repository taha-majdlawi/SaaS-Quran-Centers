import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/i18n.dart';

import '../../core/push/instant_delivery.dart';
import '../../core/push/push_service.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import '../teacher/teacher_widgets.dart';
import 'comms_repository.dart';

/// "What reaches me": one switch per notification type that can reach this person's role (the center's
/// own switched-off types are hidden), the center's quiet hours, and the phone's push status.
class NotificationPrefsScreen extends StatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  State<NotificationPrefsScreen> createState() => _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  final _repository = CommsRepository(AppSupabase.client);
  Future<NotificationPrefs>? _future;
  Future<bool>? _pushOk;
  String? _orgId;
  List<NotificationType>? _types;
  final Set<String> _saving = {};

  Future<NotificationPrefs> _load() async {
    final p = await _repository.prefs(_orgId!);
    _types = p.types;
    return p;
  }

  Future<void> _toggle(NotificationType t, bool value) async {
    setState(() {
      _saving.add(t.key);
      _types = [for (final x in _types!) x.key == t.key ? x.copyWith(enabled: value) : x];
    });
    try {
      await _repository.setPref(_orgId!, t.key, value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _types = [for (final x in _types!) x.key == t.key ? x.copyWith(enabled: !value) : x]);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(currentStrings.notif.notSaved)));
    } finally {
      if (mounted) setState(() => _saving.remove(t.key));
    }
  }

  Widget _banner(IconData icon, String text, {Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.onSurfaceVariant;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, size: 20, color: c),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: scheme.onSurface))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _orgId) {
      _orgId = orgId;
      _future = _load();
      _pushOk = PushService.instance.notificationsAllowed();
    }
    return Scaffold(
      appBar: AppBar(title: Text(tr(context).notif.prefs)),
      body: _future == null
          ? const SizedBox.shrink()
          : AsyncBody<NotificationPrefs>(
              future: _future!,
              onRetry: () => setState(() => _future = _load()),
              builder: (context, prefs) => RefreshIndicator(
                onRefresh: () async => setState(() => _future = _load()),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    FutureBuilder<bool>(
                      future: _pushOk,
                      builder: (context, snap) {
                        if (!PushService.instance.isReady) {
                          return _banner(Icons.cloud_off_rounded, tr(context).notif.noPush);
                        }
                        if (snap.data == false) {
                          return _banner(Icons.notifications_off_rounded, tr(context).notif.noPermission,
                              color: Colors.orange);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    if (PushService.instance.isReady) const InstantDeliveryCard(showWhenOk: true),
                    if (prefs.paused)
                      _banner(Icons.pause_circle_rounded, tr(context).notif.paused, color: Colors.orange),
                    if (prefs.quietFrom.isNotEmpty && prefs.quietTo.isNotEmpty)
                      _banner(Icons.bedtime_rounded, fmt(tr(context).notif.quiet, {'from': prefs.quietFrom, 'to': prefs.quietTo})),
                    SectionLabel(tr(context).notif.types),
                    Card(
                      child: Column(children: [
                        for (final t in _types ?? prefs.types)
                          SwitchListTile(
                            title: Text(t.name),
                            value: t.enabled,
                            onChanged: _saving.contains(t.key) ? null : (v) => _toggle(t, v),
                          ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
