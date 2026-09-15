import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import 'announcements_repository.dart';

class AnnouncementsListScreen extends StatefulWidget {
  const AnnouncementsListScreen({super.key});

  @override
  State<AnnouncementsListScreen> createState() => _AnnouncementsListScreenState();
}

class _AnnouncementsListScreenState extends State<AnnouncementsListScreen> {
  final _repository = AnnouncementsRepository(AppSupabase.client);
  late Future<List<AnnouncementSummary>> _announcementsFuture;
  String? _loadedForOrgId;

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _announcementsFuture = _repository.fetchAnnouncements(orgId);
  }

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الإعلانات')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/announcements/new');
          if (orgId != null && mounted) setState(() => _reload(orgId));
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<AnnouncementSummary>>(
        future: _announcementsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final announcements = snapshot.data!;
          if (announcements.isEmpty) {
            return const Center(child: Text('لا يوجد إعلانات بعد'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final a = announcements[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(a.title),
                  subtitle: Text('${a.body}\n${kAnnouncementAudienceLabels[a.audience] ?? a.audience}'),
                  isThreeLine: true,
                  onTap: () async {
                    await context.push('/announcements/${a.id}');
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
