import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import 'circle_challenges_repository.dart';

class CircleChallengesListScreen extends StatefulWidget {
  const CircleChallengesListScreen({super.key});

  @override
  State<CircleChallengesListScreen> createState() => _CircleChallengesListScreenState();
}

class _CircleChallengesListScreenState extends State<CircleChallengesListScreen> {
  final _repository = CircleChallengesRepository(AppSupabase.client);
  late Future<List<ChallengeSummary>> _challengesFuture;
  String? _loadedForOrgId;

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _challengesFuture = _repository.fetchChallenges(orgId);
  }

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('منافسات الحلقات')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/circle-challenges/new');
          if (orgId != null && mounted) setState(() => _reload(orgId));
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ChallengeSummary>>(
        future: _challengesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final challenges = snapshot.data!;
          if (challenges.isEmpty) {
            return const Center(child: Text('لا يوجد منافسات بعد'));
          }
          return ListView.separated(
            itemCount: challenges.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final c = challenges[index];
              return ListTile(
                title: Text(c.title),
                subtitle: Text('${c.metric} · ${c.startsOn} — ${c.endsOn}'),
                trailing: const Text('النتائج'),
                onTap: () async {
                  await context.push('/circle-challenges/${c.id}');
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
