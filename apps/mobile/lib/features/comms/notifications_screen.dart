import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import 'comms_repository.dart';

/// The person's own inbox. Each row leads to what it is about; each event type
/// can be switched off from the tune icon.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repository = CommsRepository(AppSupabase.client);
  Future<List<NotificationItem>>? _future;
  String? _orgId;

  String? _routeFor(NotificationItem n, bool portal) {
    if (n.refId == null) return null;
    switch (n.eventKey) {
      case 'calendar_entry':
      case 'weekly_digest':
        return '/my/report';
      case 'event_reminder':
      case 'waitlist_promoted':
        return '/calendar/${n.refId}';
      case 'announcement':
        return '/announcements';
      case 'serd_assigned':
        return '/serd/new?session=${n.refId}';
      case 'serd_reviewed':
        return portal ? '/my' : '/serd';
      case 'market_order':
        return portal ? '/my/market' : '/market';
      case 'badge_awarded':
        return portal ? '/my/badges' : '/badges/${n.refId}';
    }
    return null;
  }

  Future<void> _prefs() async {
    final prefs = await _repository.prefs(_orgId!);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              const Text('ما أريد أن يصلني', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              for (final e in kEventLabels.entries)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.value),
                  value: prefs[e.key] != false,
                  onChanged: (v) async {
                    setLocal(() => prefs[e.key] = v);
                    await _repository.setPref(_orgId!, e.key, v);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final orgId = tenant.active?.organization.id;
    if (orgId != null && orgId != _orgId) {
      _orgId = orgId;
      _future = _repository.notifications(orgId);
    }
    final role = tenant.active?.role;
    final isStaff = role == OrgRole.admin || role == OrgRole.teacher;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(icon: const Icon(Icons.tune_rounded), tooltip: 'التفضيلات', onPressed: _prefs),
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'تعليم الكل كمقروء',
            onPressed: () async {
              await _repository.markAllRead(_orgId!);
              if (mounted) setState(() => _future = _repository.notifications(_orgId!));
            },
          ),
        ],
      ),
      drawer: isStaff ? const AppDrawer() : null,
      body: _future == null
          ? const SizedBox.shrink()
          : AsyncBody<List<NotificationItem>>(
              future: _future!,
              onRetry: () => setState(() => _future = _repository.notifications(_orgId!)),
              builder: (context, list) => RefreshIndicator(
                onRefresh: () async => setState(() => _future = _repository.notifications(_orgId!)),
                child: list.isEmpty
                    ? ListView(children: const [SizedBox(height: 80), EmptyState(icon: Icons.notifications_none_rounded, title: 'لا توجد إشعارات')])
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final n in list)
                            Card(
                              color: n.read ? null : Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
                              child: ListTile(
                                title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w600 : FontWeight.w800)),
                                subtitle: Text('${n.body ?? ''}${n.body == null ? '' : '\n'}${formatDateTime(n.createdAt)}'),
                                isThreeLine: n.body != null,
                                onTap: () async {
                                  await _repository.markAllRead(_orgId!);
                                  final route = _routeFor(n, !isStaff);
                                  if (route != null && context.mounted) await context.push(route);
                                  if (mounted) setState(() => _future = _repository.notifications(_orgId!));
                                },
                              ),
                            ),
                        ],
                      ),
              ),
            ),
    );
  }
}
