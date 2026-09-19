import 'package:flutter/material.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/entity_list.dart';
import '../../core/widgets/format.dart';
import 'circle_challenges_repository.dart';

class CircleChallengesListScreen extends StatelessWidget {
  const CircleChallengesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = CircleChallengesRepository(AppSupabase.client);
    return EntityListScreen<ChallengeSummary>(
      title: 'منافسات الحلقات',
      loader: repository.fetchChallenges,
      addPath: '/circle-challenges/new',
      addLabel: 'منافسة جديدة',
      emptyIcon: Icons.leaderboard_outlined,
      emptyTitle: 'لا يوجد منافسات بعد',
      emptySubtitle: 'أنشئ منافسة لتحفيز الحلقات',
      tileBuilder: (context, c) => EntityTile(
        title: c.title,
        subtitle: '${c.metric}  ·  ${formatDate(c.startsOn)} — ${formatDate(c.endsOn)}',
        leading: const TileIcon(Icons.leaderboard_rounded, color: Colors.orange),
        path: '/circle-challenges/${c.id}',
      ),
    );
  }
}
