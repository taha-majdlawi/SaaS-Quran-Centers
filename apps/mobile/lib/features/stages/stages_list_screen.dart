import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/tenant/organization.dart';
import '../../core/widgets/app_drawer.dart';
import 'stages_repository.dart';

class StagesListScreen extends StatefulWidget {
  const StagesListScreen({super.key});

  @override
  State<StagesListScreen> createState() => _StagesListScreenState();
}

class _StagesListScreenState extends State<StagesListScreen> {
  final _repository = StagesRepository(AppSupabase.client);
  late Future<List<StageSummary>> _stagesFuture;
  String? _loadedForOrgId;

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _stagesFuture = _repository.fetchStages(orgId);
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final orgId = tenant.active?.organization.id;
    final isAdmin = tenant.active?.role == OrgRole.admin;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('المراحل')),
      drawer: const AppDrawer(),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                await context.push('/stages/new');
                if (orgId != null && mounted) setState(() => _reload(orgId));
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: FutureBuilder<List<StageSummary>>(
        future: _stagesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final stages = snapshot.data!;
          if (stages.isEmpty) {
            return const Center(child: Text('لا يوجد مراحل بعد'));
          }
          return ListView.separated(
            itemCount: stages.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = stages[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${s.sortOrder}')),
                title: Text(s.name),
                subtitle: Text(s.code ?? '—'),
                onTap: !isAdmin
                    ? null
                    : () async {
                        await context.push('/stages/${s.id}');
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
