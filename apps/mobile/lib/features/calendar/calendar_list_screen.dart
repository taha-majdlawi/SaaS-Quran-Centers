import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/calendar/calendar_realtime.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import 'calendar_repository.dart';

class CalendarListScreen extends StatefulWidget {
  const CalendarListScreen({super.key});

  @override
  State<CalendarListScreen> createState() => _CalendarListScreenState();
}

class _CalendarListScreenState extends State<CalendarListScreen> {
  final _repository = CalendarRepository(AppSupabase.client);
  late Future<List<CalendarEventSummary>> _eventsFuture;
  String? _loadedForOrgId;
  CalendarRealtime? _realtime;
  String? _realtimeOrgId;

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _eventsFuture = _repository.fetchEvents(orgId);
  }

  // Separate from _reload (which also runs on every realtime callback) so a
  // change event doesn't tear down and recreate its own channel - the
  // subscription is only (re)created when the active org itself changes.
  void _ensureRealtimeFor(String orgId) {
    if (_realtimeOrgId == orgId) return;
    _realtime?.dispose();
    _realtimeOrgId = orgId;
    _realtime = CalendarRealtime(
      organizationId: orgId,
      onChange: () {
        if (mounted) setState(() => _reload(orgId));
      },
    );
  }

  @override
  void dispose() {
    _realtime?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }
    if (orgId != null) _ensureRealtimeFor(orgId);

    return Scaffold(
      appBar: AppBar(title: const Text('التقويم')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/calendar/new');
          if (orgId != null && mounted) setState(() => _reload(orgId));
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<CalendarEventSummary>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(child: Text('لا يوجد فعاليات بعد'));
          }
          return ListView.separated(
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final e = events[index];
              return ListTile(
                title: Text(e.title),
                subtitle: Text('${e.startsAt} · ${e.location ?? "—"}'),
                trailing: e.requiresGuardianConsent ? const Icon(Icons.family_restroom, size: 18) : null,
                onTap: () async {
                  await context.push('/calendar/${e.id}');
                  if (orgId != null && mounted) setState(() => _reload(orgId));
                },
              );
            },
          );
        },
      ),
    );
  }
}
