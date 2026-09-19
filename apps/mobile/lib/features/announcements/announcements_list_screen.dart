import 'package:flutter/material.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/entity_list.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import 'announcements_repository.dart';

class AnnouncementsListScreen extends StatelessWidget {
  const AnnouncementsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AnnouncementsRepository(AppSupabase.client);
    return EntityListScreen<AnnouncementSummary>(
      title: 'الإعلانات',
      loader: repository.fetchAnnouncements,
      searchable: true,
      addPath: '/announcements/new',
      addLabel: 'إعلان جديد',
      emptyIcon: Icons.campaign_outlined,
      emptyTitle: 'لا يوجد إعلانات بعد',
      emptySubtitle: 'انشر إعلانًا موجّهًا للكل أو لفئة محددة',
      tileBuilder: (context, a) => EntityTile(
        title: a.title,
        subtitle: '${a.body.length > 110 ? '${a.body.substring(0, 110)}…' : a.body}\n${formatDate(a.publishedAt)}',
        leading: const TileIcon(Icons.campaign_rounded, color: Colors.deepOrange),
        trailing: StatusChip(label: kAnnouncementAudienceLabels[a.audience] ?? a.audience, color: Colors.blue),
        path: '/announcements/${a.id}',
        searchText: a.body,
      ),
    );
  }
}
