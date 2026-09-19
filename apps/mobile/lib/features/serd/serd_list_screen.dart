import 'package:flutter/material.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/entity_list.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import 'serd_repository.dart';

const _statusColors = <String, MaterialColor>{
  'pending': Colors.grey,
  'scheduled': Colors.blue,
  'in_progress': Colors.orange,
  'completed': Colors.green,
  'cancelled': Colors.red,
};

class SerdListScreen extends StatelessWidget {
  const SerdListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = SerdRepository(AppSupabase.client);
    return EntityListScreen<SerdSessionSummary>(
      title: 'السرد القرآني',
      loader: repository.fetchSessions,
      searchable: true,
      addPath: '/serd/new',
      addLabel: 'جدولة جلسة',
      emptyIcon: Icons.menu_book_outlined,
      emptyTitle: 'لا يوجد جلسات سرد بعد',
      emptySubtitle: 'جدول أول جلسة سرد لأحد الطلاب',
      tileBuilder: (context, s) => EntityTile(
        title: s.studentName,
        subtitle: [
          kSerdTypeLabels[s.sessionType] ?? s.sessionType,
          formatDateTime(s.scheduledAt, fallback: 'بدون موعد'),
          if (s.overallGrade != null) 'التقدير ${s.overallGrade}',
        ].join('  ·  '),
        leading: const TileIcon(Icons.menu_book_rounded),
        trailing: StatusChip(
          label: kSerdStatusLabels[s.status] ?? s.status,
          color: _statusColors[s.status] ?? Colors.grey,
        ),
        path: '/serd/${s.id}',
      ),
    );
  }
}
