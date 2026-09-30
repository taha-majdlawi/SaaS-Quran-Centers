import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bustan_alquran_app/core/offline/outbox.dart';
import 'package:bustan_alquran_app/core/offline/sync_service.dart';
import 'package:bustan_alquran_app/core/widgets/garden.dart';

import 'harness.dart';

void main() {
  setUpAll(loadFonts);
  testWidgets('home header with the sync button', (tester) async {
    final sync = SyncService(MemoryOfflineStore(), currentUser: () => 'u', connectivity: const Stream.empty());
    sync.reportConnectivity(false);
    sync.register('x', (_) async => null);
    await sync.submit('x', {}, label: 'x');
    await sync.submit('x', {}, label: 'y');
    await shot(tester, 'sync_button', ChangeNotifierProvider.value(value: sync, child: Scaffold(
      body: GardenHeader(
        greeting: 'مساء الخير',
        title: 'الشيخ أحمد',
        subtitle: 'الثلاثاء 30 سبتمبر',
        actions: [const SyncButton(), IconButton(onPressed: () {}, icon: const Icon(Icons.person_search_rounded, color: Colors.white))],
      ),
    )), height: 360);
  });
}
