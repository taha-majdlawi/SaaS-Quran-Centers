import 'package:flutter/material.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/entity_list.dart';
import '../../core/widgets/ui.dart';
import 'circles_repository.dart';

class CirclesListScreen extends StatelessWidget {
  const CirclesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = CirclesRepository(AppSupabase.client);
    return EntityListScreen<CircleSummary>(
      title: 'الحلقات',
      loader: repository.fetchCircles,
      searchable: true,
      addPath: '/circles/new',
      addLabel: 'إضافة حلقة',
      emptyIcon: Icons.groups_outlined,
      emptyTitle: 'لا يوجد حلقات بعد',
      emptySubtitle: 'أنشئ أول حلقة ثم أضف إليها الطلاب',
      tileBuilder: (context, c) => EntityTile(
        title: c.name,
        subtitle: [
          c.stageName ?? 'بدون مرحلة',
          c.teacherName ?? 'بدون معلم',
          if (c.capacity != null) 'السعة ${c.capacity}',
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
