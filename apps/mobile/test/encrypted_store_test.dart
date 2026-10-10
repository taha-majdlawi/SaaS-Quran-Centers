import 'dart:convert';
import 'dart:typed_data';

import 'package:bustan_alquran_app/core/offline/encrypted_store.dart';
import 'package:bustan_alquran_app/core/offline/outbox.dart';
import 'package:flutter_test/flutter_test.dart';

CacheCipher _cipher([int seed = 7]) => CacheCipher(() async => Uint8List.fromList(List.generate(32, (i) => (i * seed) % 256)));

OutboxItem _item(Map<String, dynamic> payload) => OutboxItem(
      id: 0,
      userId: 'u1',
      kind: 'log_recitation',
      payload: payload,
      label: 'تسميع',
      createdAt: DateTime(2026, 10, 10),
    );

void main() {
  test('a saved copy is stored encrypted and read back as it was', () async {
    final inner = MemoryOfflineStore();
    final store = EncryptedOfflineStore(inner, _cipher());
    const json = '{"name":"أحمد محمد","phone":"0791234567"}';
    await store.writeCache('u1|students', json);

    final raw = (await inner.readCache('u1|students'))!;
    expect(raw.startsWith(CacheCipher.prefix), isTrue);
    expect(raw.contains('أحمد'), isFalse);
    expect(utf8.decode(base64Decode(raw.substring(3)), allowMalformed: true).contains('0791234567'), isFalse);
    expect(await store.readCache('u1|students'), json);
  });

  test('the same text never encrypts the same way twice (a new nonce each time)', () async {
    final c = _cipher();
    expect(await c.encrypt('x', 'cache:a'), isNot(await c.encrypt('x', 'cache:a')));
  });

  test('an altered, moved, or foreign-key copy is not opened', () async {
    final c = _cipher();
    final sealed = await c.encrypt('{"a":1}', 'cache:u1|a');
    // one byte changed
    final bytes = base64Decode(sealed.substring(3));
    bytes[20] ^= 1;
    expect(await c.decrypt('${CacheCipher.prefix}${base64Encode(bytes)}', 'cache:u1|a'), isNull);
    // moved under another key (another account's copy)
    expect(await c.decrypt(sealed, 'cache:u2|a'), isNull);
    // another phone's key
    expect(await _cipher(11).decrypt(sealed, 'cache:u1|a'), isNull);
    expect(await c.decrypt(sealed, 'cache:u1|a'), '{"a":1}');
  });

  test('copies saved before encryption are still read', () async {
    final inner = MemoryOfflineStore();
    await inner.writeCache('k', '{"old":true}');
    expect(await EncryptedOfflineStore(inner, _cipher()).readCache('k'), '{"old":true}');
  });

  test('queued writes are encrypted on the phone and replayed as they were', () async {
    final inner = MemoryOfflineStore();
    final store = EncryptedOfflineStore(inner, _cipher());
    final payload = {'p_student_id': 's1', 'p_note': 'حفظ ممتاز', 'p_from': 1};
    final added = await store.add(_item(payload));
    expect(added.payload, payload);

    final raw = (await inner.items()).single;
    expect(raw.payload.keys, ['_enc']);
    expect(jsonEncode(raw.payload).contains('s1'), isFalse);

    final back = (await store.items()).single;
    expect(back.payload, payload);
    expect(back.status, 'pending');
  });

  test('a queued write this phone cannot open is shown as failed, never replayed empty', () async {
    final inner = MemoryOfflineStore();
    await EncryptedOfflineStore(inner, _cipher()).add(_item({'p_student_id': 's1'}));
    final back = (await EncryptedOfflineStore(inner, _cipher(11)).items()).single;
    expect(back.status, 'failed');
    expect(back.error, EncryptedOfflineStore.unreadable);
    expect(back.payload, isEmpty);
  });

  test('writes queued before encryption are still replayed', () async {
    final inner = MemoryOfflineStore();
    await inner.add(_item({'p_student_id': 's1'}));
    expect((await EncryptedOfflineStore(inner, _cipher()).items()).single.payload, {'p_student_id': 's1'});
  });
}
