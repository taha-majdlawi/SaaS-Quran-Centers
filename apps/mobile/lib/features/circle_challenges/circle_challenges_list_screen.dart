import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import '../engagement/engagement_models.dart';
import '../engagement/engagement_repository.dart';
import '../../core/i18n/i18n.dart';

/// Circle-vs-circle challenges. Circles are ranked by the AVERAGE PER STUDENT
/// (never a raw sum), so a small circle is not beaten by its size alone.
class CircleChallengesListScreen extends StatefulWidget {
  const CircleChallengesListScreen({super.key});

  @override
  State<CircleChallengesListScreen> createState() => _CircleChallengesListScreenState();
}

class _CircleChallengesListScreenState extends State<CircleChallengesListScreen> {
  final _repository = EngagementRepository(AppSupabase.client);
  Future<List<Challenge>>? _future;
  String? _orgId;

  @override
  Widget build(BuildContext context) {
    final membership = context.watch<TenantController>().active;
    final orgId = membership?.organization.id;
    if (orgId != null && orgId != _orgId) {
      _orgId = orgId;
      _future = _repository.challenges(orgId);
    }
    final isAdmin = membership?.role == OrgRole.admin;

    return Scaffold(
      appBar: AppBar(
        leading: DrawerLeading(),title: Text(tr(context).nav.items['/circle-challenges']!)),
      drawer: const AppDrawer(),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/circle-challenges/new');
                if (mounted) setState(() => _future = _repository.challenges(_orgId!));
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(tr(context).ins.newChallenge),
            )
          : null,
      body: _future == null
          ? const SizedBox.shrink()
          : AsyncBody<List<Challenge>>(
              future: _future!,
              onRetry: () => setState(() => _future = _repository.challenges(_orgId!)),
              builder: (context, list) => list.isEmpty
                  ? EmptyState(icon: Icons.leaderboard_outlined, title: tr(context).ins.noChallenges)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      children: [
                        for (final c in list)
                          Card(
                            child: ListTile(
                              onTap: () async {
                                await context.push('/circle-challenges/${c.id}');
                                if (mounted) setState(() => _future = _repository.challenges(_orgId!));
                              },
                              title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: Text('${kMetricLabels[c.metric]}\n${formatDate(c.startsOn)} — ${formatDate(c.endsOn)}'),
                              isThreeLine: true,
                              trailing: StatusChip(label: kChallengeStatus[c.status] ?? c.status, color: c.status == 'active' ? Colors.green : (c.status == 'ended' ? Colors.grey : Colors.blue)),
                            ),
                          ),
                      ],
                    ),
            ),
    );
  }
}
