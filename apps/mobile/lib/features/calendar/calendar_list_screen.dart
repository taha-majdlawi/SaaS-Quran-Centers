import 'package:flutter/material.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/entity_list.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import 'calendar_repository.dart';

class CalendarListScreen extends StatelessWidget {
  const CalendarListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = CalendarRepository(AppSupabase.client);
    return EntityListScreen<CalendarEventSummary>(
      title: 'التقويم',
      loader: repository.fetchEvents,
      searchable: true,
      addPath: '/calendar/new',
      addLabel: 'فعالية جديدة',
      emptyIcon: Icons.calendar_month_outlined,
      emptyTitle: 'لا يوجد فعاليات بعد',
      emptySubtitle: 'أضف رحلات وفعاليات المركز وسجّل الطلاب فيها',
      tileBuilder: (context, e) => EntityTile(
        title: e.title,
        subtitle: '${formatDateTime(e.startsAt)}  ·  ${e.location ?? "بدون مكان"}',
        leading: const TileIcon(Icons.calendar_month_rounded, color: Colors.teal),
        trailing: e.requiresGuardianConsent ? const StatusChip(label: 'موافقة ولي أمر', color: Colors.orange) : null,
        path: '/calendar/${e.id}',
        searchText: e.location,
      ),
    );
  }
}
