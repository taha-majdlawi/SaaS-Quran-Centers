import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bustan_alquran_app/core/offline/outbox.dart';
import 'package:bustan_alquran_app/core/offline/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MemoryOfflineStore store;
  late SyncService sync;
  var user = 'teacher-a';
  final sent = <String>[];
  var online = true;

  setUp(() {
    store = MemoryOfflineStore();
    user = 'teacher-a';
    sent.clear();
    online = true;
    sync = SyncService(store, currentUser: () => user, connectivity: const Stream.empty());
    sync.register('log', (payload) async {
      if (!online) throw const SocketException('offline');
      if (payload['bad'] == true) throw const PostgrestException(message: 'الطالب ليس ضمن حلقتك', code: 'P0001');
      sent.add(payload['n'] as String);
    });
  });

  test('sent immediately when online', () async {
    final r = await sync.submit('log', {'n': '1'}, label: 'x');
    expect(r.queued, false);
    expect(sent, ['1']);
    expect(sync.pendingCount, 0);
  });

  test('queued when the network is down, uploaded in order when it returns', () async {
    online = false;
    expect((await sync.submit('log', {'n': '1'}, label: 'a')).queued, true);
    expect((await sync.submit('log', {'n': '2'}, label: 'b')).queued, true);
    expect(sync.pendingCount, 2);

    await sync.flush(); // still offline: nothing lost, nothing sent
    expect(sync.pendingCount, 2);
    expect(sent, isEmpty);

    online = true;
    await sync.flush();
    expect(sent, ['1', '2']);
    expect(sync.pendingCount, 0);
    expect(await store.items(), isEmpty);
  });

  test('a server refusal is thrown to the caller, not queued', () async {
    await expectLater(sync.submit('log', {'n': '1', 'bad': true}, label: 'x'), throwsA(isA<PostgrestException>()));
    expect(sync.pendingCount, 0);
  });

  test('a queued item the server later refuses is marked failed and does not block the rest', () async {
    online = false;
    await sync.submit('log', {'n': '1', 'bad': true}, label: 'bad');
    await sync.submit('log', {'n': '2'}, label: 'good');
    online = true;
    await sync.flush();
    expect(sent, ['2']);
    expect(sync.failedCount, 1);
    expect(sync.pendingCount, 0);
    expect(sync.mine.firstWhere((i) => i.status == 'failed').error, contains('حلقتك'));
  });

  test('a later write for the same key waits behind an older pending one, even online', () async {
    online = false;
    await sync.submit('log', {'n': 'old'}, label: 'a', orderKey: 'att:1');
    online = true;
    final r = await sync.submit('log', {'n': 'new'}, label: 'b', orderKey: 'att:1');
    expect(r.queued, true); // not sent ahead of the older one
    await sync.flush();
    expect(sent, ['old', 'new']);
  });

  test("another account's queue is never uploaded", () async {
    online = false;
    await sync.submit('log', {'n': 'a-item'}, label: 'a');
    online = true;
    user = 'teacher-b';
    await sync.flush();
    expect(sent, isEmpty);
    expect(sync.pendingCount, 0); // not b's
    user = 'teacher-a';
    await sync.flush();
    expect(sent, ['a-item']);
  });

  test('reads fall back to the last copy when offline', () async {
    final first = await sync.cached<List<String>>('circle', () async => ['ali', 'omar'], (j) => List<String>.from(j as List));
    expect(first, ['ali', 'omar']);
    expect(sync.usingCache, false);
    final offline = await sync.cached<List<String>>('circle', () async => throw const SocketException('x'), (j) => List<String>.from(j as List));
    expect(offline, ['ali', 'omar']);
    expect(sync.usingCache, true);
    // never seen before + offline = a real error
    await expectLater(sync.cached<List<String>>('other', () async => throw TimeoutException('t'), (j) => <String>[]), throwsA(isA<TimeoutException>()));
  });

  test('pending recitation / attendance are visible to the screens', () async {
    online = false;
    sync.register('log_recitation', (_) async => throw const SocketException('x'));
    sync.register('attendance', (_) async => throw const SocketException('x'));
    final now = DateTime.now();
    final day = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await sync.submit('log_recitation', {'p_student_id': 's1', 'p_recorded_at': now.toUtc().toIso8601String()}, label: 'r');
    await sync.submit('attendance', {'rows': [{'student_id': 's1', 'session_date': day, 'status': 'absent'}]}, label: 'a');
    expect(sync.pendingRecitationsToday('s1'), 1);
    expect(sync.pendingRecitationsToday('s2'), 0);
    expect(sync.pendingAttendance('s1', day), 'absent');
  });

  test('a viewing account is refused before anything is sent or queued', () async {
    SyncService.writeGuard = () => throw StateError('حساب عرض');
    addTearDown(() => SyncService.writeGuard = null);
    online = false; // even offline it must not enter the queue
    await expectLater(sync.submit('log', {'n': '1'}, label: 'x'), throwsA(isA<StateError>()));
    expect(sync.pendingCount, 0);
    expect(await store.items(), isEmpty);
  });
}
