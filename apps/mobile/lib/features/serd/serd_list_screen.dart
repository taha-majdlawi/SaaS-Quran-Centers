import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import 'serd_repository.dart';

class SerdListScreen extends StatefulWidget {
  const SerdListScreen({super.key});

  @override
  State<SerdListScreen> createState() => _SerdListScreenState();
}

class _SerdListScreenState extends State<SerdListScreen> {
  final _repository = SerdRepository(AppSupabase.client);
  late Future<List<SerdSessionSummary>> _sessionsFuture;
  String? _loadedForOrgId;

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _sessionsFuture = _repository.fetchSessions(orgId);
  }

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('السرد القرآني')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/serd/new');
          if (orgId != null && mounted) setState(() => _reload(orgId));
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<SerdSessionSummary>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final sessions = snapshot.data!;
          if (sessions.isEmpty) {
            return const Center(child: Text('لا يوجد جلسات سرد بعد'));
          }
          return ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = sessions[index];
              return ListTile(
                title: Text(s.studentName),
                subtitle: Text(
                  '${kSerdTypeLabels[s.sessionType] ?? s.sessionType} · ${kSerdStatusLabels[s.status] ?? s.status}',
                ),
                trailing: Text(s.overallGrade != null ? '${s.overallGrade}' : '—'),
                onTap: () async {
                  await context.push('/serd/${s.id}');
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
