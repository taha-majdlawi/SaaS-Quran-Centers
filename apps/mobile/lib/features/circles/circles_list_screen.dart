import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import 'circles_repository.dart';

class CirclesListScreen extends StatefulWidget {
  const CirclesListScreen({super.key});

  @override
  State<CirclesListScreen> createState() => _CirclesListScreenState();
}

class _CirclesListScreenState extends State<CirclesListScreen> {
  final _repository = CirclesRepository(AppSupabase.client);
  late Future<List<CircleSummary>> _circlesFuture;
  String? _loadedForOrgId;

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _circlesFuture = _repository.fetchCircles(orgId);
  }

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الحلقات')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/circles/new');
          if (orgId != null && mounted) setState(() => _reload(orgId));
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<CircleSummary>>(
        future: _circlesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final circles = snapshot.data!;
          if (circles.isEmpty) {
            return const Center(child: Text('لا يوجد حلقات بعد'));
          }
          return ListView.separated(
            itemCount: circles.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = circles[index];
              final subtitleParts = [
                c.stageName ?? 'بدون مرحلة',
                c.teacherName ?? 'بدون معلم',
                if (c.capacity != null) 'السعة ${c.capacity}',
              ];
              return ListTile(
                title: Text(c.name),
                subtitle: Text(subtitleParts.join(' · ')),
                trailing: Text(kCircleStatusLabels[c.status] ?? c.status),
                onTap: () async {
                  await context.push('/circles/${c.id}');
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
