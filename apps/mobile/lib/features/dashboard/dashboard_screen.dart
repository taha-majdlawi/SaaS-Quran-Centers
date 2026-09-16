import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/offline/offline_cache.dart';
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

  // The reference usage of core/offline/offline_cache.dart's read-through
  // fallback: try live first (and cache it for next time), fall back to the
  // last cached value only if the live fetch itself fails - never cache-
  // first, which would flash stale numbers before the real ones load.
  Future<_DashboardStats> _loadStats(String orgId) async {
    final cacheKey = 'dashboard_stats:$orgId';
    try {
      final client = AppSupabase.client;
      final results = await Future.wait([
        client.from('students_profile').count().eq('organization_id', orgId),
        client.from('organization_members').count().eq('organization_id', orgId).eq('role', 'teacher'),
        client.from('circles').count().eq('organization_id', orgId),
      ]);
      final stats = _DashboardStats(students: results[0], teachers: results[1], circles: results[2]);
      await OfflineCache.put(cacheKey, stats.toJson());
      return stats;
    } catch (e) {
      final cached = await OfflineCache.get(cacheKey);
      if (cached != null) return _DashboardStats.fromJson(cached as Map<String, dynamic>);
      rethrow;
    }
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
          return Column(
            children: [
              if (stats.fromCache)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.amber.shade100,
                  child: const Text(
                    'غير متصل - هاي آخر بيانات محفوظة',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              Expanded(
                child: GridView.count(
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardStats {
  const _DashboardStats({required this.students, required this.teachers, required this.circles, this.fromCache = false});
  final int students;
  final int teachers;
  final int circles;
  final bool fromCache;

  Map<String, dynamic> toJson() => {'students': students, 'teachers': teachers, 'circles': circles};

  factory _DashboardStats.fromJson(Map<String, dynamic> json) => _DashboardStats(
        students: json['students'] as int,
        teachers: json['teachers'] as int,
        circles: json['circles'] as int,
        fromCache: true,
      );
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
