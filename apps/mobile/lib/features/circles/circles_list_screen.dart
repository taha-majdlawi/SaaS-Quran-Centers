import 'package:flutter/material.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/entity_list.dart';
import '../../core/widgets/ui.dart';
import 'circles_repository.dart';
import '../../core/i18n/i18n.dart';

class CirclesListScreen extends StatelessWidget {
  const CirclesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = CirclesRepository(AppSupabase.client);
    return EntityListScreen<CircleSummary>(
      title: tr(context).nav.items['/circles']!,
      loader: repository.fetchCircles,
      searchable: true,
      addPath: '/circles/new',
      addLabel: tr(context).org.addCircle,
      emptyIcon: Icons.groups_outlined,
      emptyTitle: tr(context).org.noCircles,
      emptySubtitle: tr(context).org.noCirclesHint,
      tileBuilder: (context, c) => EntityTile(
        title: c.name,
        subtitle: [
          c.stageName ?? tr(context).org.noStage,
          c.teacherName ?? tr(context).org.noTeacher,
          if (c.capacity != null) fmt(tr(context).org.capacityN, {'capacity': c.capacity}),
        ].join('  ·  '),
        leading: const TileIcon(Icons.groups_rounded),
        trailing: StatusChip(
          label: kCircleStatusLabels[c.status] ?? c.status,
          color: c.status == 'active' ? Colors.green : Colors.grey,
        ),
        path: '/circles/${c.id}',
        searchText: '${c.stageName ?? ''} ${c.teacherName ?? ''}',
      ),
    );
  }
}
