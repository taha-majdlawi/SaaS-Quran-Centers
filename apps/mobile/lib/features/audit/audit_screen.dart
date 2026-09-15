import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import 'audit_repository.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  final _repository = AuditRepository(AppSupabase.client);
  late Future<List<AuditEntry>> _logFuture;
  String? _loadedForOrgId;

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _logFuture = _repository.fetchLog(orgId);
  }

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('سجل العمليات')),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<AuditEntry>>(
        future: _logFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final entries = snapshot.data!;
          if (entries.isEmpty) {
            return const Center(child: Text('لا يوجد عمليات مسجّلة بعد'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final e = entries[index];
              return ListTile(
                title: Text(
                  '${e.actorName} — ${kAuditActionLabels[e.action] ?? e.action} ${kAuditTableLabels[e.entityTable] ?? e.entityTable}',
                ),
                subtitle: Text(e.createdAt),
              );
            },
          );
        },
      ),
    );
  }
}
