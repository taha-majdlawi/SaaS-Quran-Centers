import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import 'activities_repository.dart';

class ActivitiesListScreen extends StatefulWidget {
  const ActivitiesListScreen({super.key});

  @override
  State<ActivitiesListScreen> createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends State<ActivitiesListScreen> {
  final _repository = ActivitiesRepository(AppSupabase.client);
  late Future<List<ActivitySummary>> _activitiesFuture;
  String? _loadedForOrgId;

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _activitiesFuture = _repository.fetchActivities(orgId);
  }

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الأنشطة')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/activities/new');
          if (orgId != null && mounted) setState(() => _reload(orgId));
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ActivitySummary>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final activities = snapshot.data!;
          if (activities.isEmpty) {
            return const Center(child: Text('لا يوجد أنشطة بعد'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final a = activities[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(a.title),
                  subtitle: Text(
                    [
                      if (a.description != null && a.description!.isNotEmpty) a.description!,
                      a.scheduledAt ?? 'بدون موعد محدد',
                    ].join('\n'),
                  ),
                  isThreeLine: a.description != null && a.description!.isNotEmpty,
                  onTap: () async {
                    await context.push('/activities/${a.id}');
                    if (orgId != null && mounted) setState(() => _reload(orgId));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
