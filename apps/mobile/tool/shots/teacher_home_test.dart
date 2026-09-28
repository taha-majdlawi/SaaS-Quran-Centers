import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bustan_alquran_app/core/i18n/i18n.dart';
import 'package:bustan_alquran_app/core/offline/outbox.dart';
import 'package:bustan_alquran_app/core/offline/sync_service.dart';
import 'package:bustan_alquran_app/core/widgets/garden.dart';
import 'package:bustan_alquran_app/core/widgets/org_avatar.dart';
import 'package:bustan_alquran_app/features/recitation/recitation_repository.dart';
import 'package:bustan_alquran_app/features/teacher/teacher_home_widgets.dart';

import 'harness.dart';

Widget home(SyncService sync) => ChangeNotifierProvider.value(
      value: sync,
      child: Builder(builder: (context) {
        final t = tr(context);
        return Scaffold(
          body: ListView(padding: EdgeInsets.zero, children: [
            GardenHeader(
              leading: const OrgAvatar(name: 'مركز النور', size: 34, onDark: true),
              greeting: t.common.goodMorning,
              title: 'أ. أحمد الخطيب',
              subtitle: 'الأحد، ٢٨ سبتمبر',
              actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.person_search_rounded, color: Colors.white))],
              stats: [
                HeaderStat('2', t.garden.statCircles, icon: Icons.groups_rounded),
                HeaderStat('24', t.garden.statStudents, icon: Icons.people_alt_rounded),
                HeaderStat('9', t.garden.statRecited, icon: Icons.menu_book_rounded),
                HeaderStat('20', t.garden.statPresent, icon: Icons.check_circle_rounded),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TeacherQuickActions(actions: [
                  (icon: Icons.fact_check_rounded, label: t.nav.items['/attendance']!, color: const Color(0xFF16835A), onTap: () {}),
                  (icon: Icons.person_search_rounded, label: t.teach.findStudent, color: const Color(0xFF1877C9), onTap: () {}),
                  (icon: Icons.menu_book_rounded, label: t.serd.record, color: const Color(0xFFB26A00), onTap: () {}),
                  (icon: Icons.record_voice_over_rounded, label: t.gather.extNew, color: const Color(0xFF8E44AD), onTap: () {}),
                ]),
                GardenSection(
                  title: fmt(t.teach.yourCircles, {'n': 2}),
                  icon: Icons.groups_rounded,
                  child: Column(children: [
                    TeacherCircleCard(
                      circle: const MyCircle(id: 'a', name: 'حلقة النور', stageName: 'التمهيدي', studentCount: 12, assistant: false),
                      done: 7, total: 12, present: 11, absent: 1, dueReviews: 3, checkedIn: false,
                      roster: const SizedBox(height: 10),
                    ),
                    const TeacherCircleCard(
                      circle: MyCircle(id: 'b', name: 'حلقة الفرقان', stageName: 'المتقدم', studentCount: 12, assistant: true),
                      done: 12, total: 12, present: 9, absent: 0, checkedIn: true,
                    ),
                  ]),
                ),
              ]),
            ),
          ]),
        );
      }),
    );

void main() {
  setUpAll(loadFonts);
  testWidgets('teacher home ar', (t) async {
    final sync = SyncService(MemoryOfflineStore(), currentUser: () => 'u', connectivity: const Stream.empty());
    await shot(t, 'teacher_home_ar', home(sync), height: 1180);
  });
  testWidgets('teacher home en offline', (t) async {
    final sync = SyncService(MemoryOfflineStore(), currentUser: () => 'u', connectivity: const Stream.empty());
    sync.reportConnectivity(false);
    await shot(t, 'teacher_home_en', home(sync), lang: 'en', height: 1180, brand: const Color(0xFF2B5BA8));
  });
}
