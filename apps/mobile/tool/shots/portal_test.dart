import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bustan_alquran_app/core/i18n/i18n.dart';
import 'package:bustan_alquran_app/core/offline/outbox.dart';
import 'package:bustan_alquran_app/core/offline/sync_service.dart';
import 'package:bustan_alquran_app/core/widgets/garden.dart';
import 'package:bustan_alquran_app/core/widgets/org_avatar.dart';

import 'harness.dart';

void main() {
  setUpAll(loadFonts);
  testWidgets('portal home', (tester) async {
    final sync = SyncService(MemoryOfflineStore(), currentUser: () => 'u', connectivity: const Stream.empty());
    await shot(tester, 'portal_home', ChangeNotifierProvider.value(value: sync, child: Builder(builder: (context) {
      final t = tr(context);
      final p = t.portal;
      return Scaffold(
        body: ListView(padding: EdgeInsets.zero, children: [
          GardenHeader(
            leading: const OrgAvatar(name: 'مركز النور', size: 34, onDark: true),
            actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_rounded, color: Colors.white))],
            greeting: t.common.goodEvening,
            title: fmt(p.hello, {'name': 'عبدالله'}),
            subtitle: 'حلقة النور  ·  الشيخ أحمد',
            stats: [
              HeaderStat('4/30', t.garden.statJuz, icon: Icons.auto_stories_rounded),
              HeaderStat('320', t.garden.statPoints, icon: Icons.stars_rounded),
              HeaderStat('6', t.garden.statStreak, icon: Icons.local_fire_department_rounded),
              HeaderStat('92%', p.statAttendance, icon: Icons.how_to_reg_rounded),
            ],
            bottom: SizedBox(height: 38, child: ListView(scrollDirection: Axis.horizontal, children: [
              ChoiceChip(label: const Text('عبدالله'), selected: true, showCheckmark: false, selectedColor: Colors.white, side: BorderSide.none, labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700), onSelected: (_) {}),
              const SizedBox(width: 8),
              ChoiceChip(label: const Text('مريم'), selected: false, backgroundColor: Colors.white.withValues(alpha: 0.14), side: BorderSide.none, labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700), onSelected: (_) {}),
            ])),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: GardenSection(
              title: t.garden.explore,
              icon: Icons.explore_rounded,
              child: GardenGrid(children: [
                GardenTile(icon: Icons.calendar_month_rounded, label: p.calendar, color: const Color(0xFFC0392B), onTap: () {}),
                GardenTile(icon: Icons.chat_bubble_rounded, label: p.chat, color: const Color(0xFF1877C9), onTap: () {}, badge: 2),
                GardenTile(icon: Icons.campaign_rounded, label: p.announcementsLink, color: const Color(0xFF6D4AA8), onTap: () {}),
                GardenTile(icon: Icons.insights_rounded, label: p.report, color: const Color(0xFF0E7C86), onTap: () {}),
                GardenTile(icon: Icons.workspace_premium_rounded, label: p.certificates, color: const Color(0xFFB26A00), onTap: () {}),
                GardenTile(icon: Icons.auto_stories_rounded, label: p.quran, color: const Color(0xFF16835A), onTap: () {}),
              ]),
            ),
          ),
        ]),
      );
    })), height: 900);
  });
}
