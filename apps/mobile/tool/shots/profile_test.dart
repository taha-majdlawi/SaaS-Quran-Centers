import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bustan_alquran_app/core/offline/outbox.dart';
import 'package:bustan_alquran_app/core/offline/sync_service.dart';
import 'package:bustan_alquran_app/core/widgets/garden.dart';
import 'package:bustan_alquran_app/features/profiles/profile_widgets.dart';

import 'harness.dart';

void main() {
  setUpAll(loadFonts);
  testWidgets('circle profile numbers', (tester) async {
    final sync = SyncService(MemoryOfflineStore(), currentUser: () => 'u', connectivity: const Stream.empty());
    await shot(tester, 'profile_stats', ChangeNotifierProvider.value(value: sync, child: Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        const GardenHeader(title: 'حلقة النور', greeting: 'المرحلة الأولى', subtitle: 'المعلم: أحمد', stats: [HeaderStat('18/20', 'الطلاب', icon: Icons.people_alt_rounded), HeaderStat('91%', 'الحضور', icon: Icons.how_to_reg_rounded)]),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            PeriodPicker(value: 'month', onChanged: (_) {}),
            const SizedBox(height: 12),
            const ProfileStatGrid(children: [
              ProfileStat(icon: Icons.menu_book_rounded, label: 'التسميعات', value: '124', now: 124, prev: 100),
              ProfileStat(icon: Icons.record_voice_over_rounded, label: 'طلاب سمّعوا', value: '16/18', now: 16, prev: 17),
              ProfileStat(icon: Icons.stars_rounded, label: 'النقاط', value: '1850', now: 1850, prev: 1850),
              ProfileStat(icon: Icons.how_to_reg_rounded, label: 'الحضور', value: '91%', now: 91, prev: 86.5, points: true),
            ]),
          ]),
        ),
      ]),
    )), height: 700);
  });
}
