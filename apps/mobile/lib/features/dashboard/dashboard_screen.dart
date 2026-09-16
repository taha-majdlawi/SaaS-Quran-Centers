import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardStats> _statsFuture;
  String? _loadedForOrgId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _loadedForOrgId = orgId;
      _statsFuture = _loadStats(orgId);
    }
  }

  Future<_DashboardStats> _loadStats(String orgId) async {
    final client = AppSupabase.client;
    final results = await Future.wait([
      client.from('students_profile').count().eq('organization_id', orgId),
      client.from('organization_members').count().eq('organization_id', orgId).eq('role', 'teacher'),
      client.from('circles').count().eq('organization_id', orgId),
    ]);
    return _DashboardStats(students: results[0], teachers: results[1], circles: results[2]);
  }

  @override
  Widget build(BuildContext context) {
    final org = context.watch<TenantController>().active?.organization;

    return Scaffold(
      appBar: AppBar(title: Text(org?.name ?? 'لوحة التحكم')),
      drawer: const AppDrawer(),
      body: FutureBuilder<_DashboardStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final stats = snapshot.data!;
          return GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _StatCard(label: 'الطلاب', value: stats.students),
              _StatCard(label: 'المعلمون', value: stats.teachers),
              _StatCard(label: 'الحلقات', value: stats.circles),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardStats {
  const _DashboardStats({required this.students, required this.teachers, required this.circles});
  final int students;
  final int teachers;
  final int circles;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
