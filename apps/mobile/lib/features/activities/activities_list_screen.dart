import 'package:flutter/material.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/entity_list.dart';
import '../../core/widgets/format.dart';
import 'activities_repository.dart';

class ActivitiesListScreen extends StatelessWidget {
  const ActivitiesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ActivitiesRepository(AppSupabase.client);
    return EntityListScreen<ActivitySummary>(
      title: 'الأنشطة',
      loader: repository.fetchActivities,
      searchable: true,
      addPath: '/activities/new',
      addLabel: 'نشاط جديد',
      emptyIcon: Icons.event_note_outlined,
      emptyTitle: 'لا يوجد أنشطة بعد',
      emptySubtitle: 'أضف أنشطة المركز ليراها الجميع',
      tileBuilder: (context, a) => EntityTile(
        title: a.title,
        subtitle: [
          if (a.description != null && a.description!.isNotEmpty) a.description!,
          formatDateTime(a.scheduledAt, fallback: 'بدون موعد محدد'),
        ].join('\n'),
        leading: const TileIcon(Icons.event_note_rounded, color: Colors.indigo),
        path: '/activities/${a.id}',
        searchText: a.description,
      ),
    );
  }
}
