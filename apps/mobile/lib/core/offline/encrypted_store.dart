import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

import 'outbox.dart';

/// Encryption for what the app keeps on the phone (students' names, phones,
/// results, queued writes): AES-256-CTR, then HMAC-SHA256 over it (encrypt-then-MAC;
/// pointycastle's GCM is ~20x slower in pure Dart). The key is made on the phone
/// and kept in the keystore/keychain (flutter_secure_storage), never in the
/// database file: a copy of the file alone (a rooted phone, a backup tool) reads nothing.
///
/// Each value is bound to where it is stored (the cache key / the outbox), so a
/// saved copy cannot be moved under another key. A value saved before
/// encryption (no prefix) is read as it is, then written encrypted next time.
class CacheCipher {
  CacheCipher(this._loadKey);

  /// The key from the keystore, made on first use.
  factory CacheCipher.secureStorage() => CacheCipher(() async {
        const storage = FlutterSecureStorage();
        const name = 'offline_cache_key_v1';
        final saved = await storage.read(key: name);
        if (saved != null) return base64Decode(saved);
        final key = randomBytes(32);
        await storage.write(key: name, value: base64Encode(key));
        return key;
      });

  static const prefix = 'e1:';
  static const _ivLength = 16, _tagLength = 32;

  final Future<Uint8List> Function() _loadKey;
  Future<(Uint8List, Uint8List)>? _keys;

  static final _random = Random.secure();
  static Uint8List randomBytes(int n) => Uint8List.fromList(List.generate(n, (_) => _random.nextInt(256)));

  /// One key to encrypt, another to sign, both from the stored key.
  Future<(Uint8List, Uint8List)> _derive() async {
    final master = await _loadKey();
    Uint8List sub(String label) => Uint8List.fromList(Hmac(sha256, master).convert(utf8.encode(label)).bytes);
    return (sub('bustan-offline-enc'), sub('bustan-offline-mac'));
  }

  Uint8List _ctr(Uint8List key, Uint8List iv, Uint8List input) =>
      (CTRStreamCipher(AESEngine())..init(true, ParametersWithIV(KeyParameter(key), iv))).process(input);

  List<int> _tag(Uint8List macKey, String context, Uint8List iv, Uint8List sealed) {
    final h = Hmac(sha256, macKey);
    final ctx = utf8.encode(context);
    final length = (ByteData(4)..setUint32(0, ctx.length)).buffer.asUint8List();
    return h.convert((BytesBuilder(copy: false)..add(length)..add(ctx)..add(iv)..add(sealed)).takeBytes()).bytes;
  }

  Future<String> encrypt(String plain, String context) async {
    final (encKey, macKey) = await (_keys ??= _derive());
    final iv = randomBytes(_ivLength);
    final sealed = _ctr(encKey, iv, Uint8List.fromList(utf8.encode(plain)));
    return prefix + base64Encode((BytesBuilder(copy: false)..add(iv)..add(sealed)..add(_tag(macKey, context, iv, sealed))).takeBytes());
  }

  /// null when the value cannot be opened (another key, altered, or moved).
  Future<String?> decrypt(String stored, String context) async {
    if (!stored.startsWith(prefix)) return stored; // saved before encryption
    try {
      final (encKey, macKey) = await (_keys ??= _derive());
      final bytes = base64Decode(stored.substring(prefix.length));
      if (bytes.length < _ivLength + _tagLength) return null;
      final iv = Uint8List.sublistView(bytes, 0, _ivLength);
      final sealed = Uint8List.sublistView(bytes, _ivLength, bytes.length - _tagLength);
      final tag = Uint8List.sublistView(bytes, bytes.length - _tagLength);
      final expected = _tag(macKey, context, iv, sealed);
      var diff = 0; // constant time
      for (var i = 0; i < _tagLength; i++) {
        diff |= expected[i] ^ tag[i];
      }
      if (diff != 0) return null;
      return utf8.decode(_ctr(encKey, iv, sealed));
    } catch (_) {
      return null;
    }
  }
}

/// An [OfflineStore] whose outbox payloads and saved copies are encrypted
/// before they reach [inner] (the sqflite file on the phone).
class EncryptedOfflineStore implements OfflineStore {
  EncryptedOfflineStore(this.inner, this.cipher);

  final OfflineStore inner;
  final CacheCipher cipher;

  static const _field = '_enc';

  /// The error of a queued write this phone can no longer open (its key is gone).
  static const unreadable = 'تعذّر فتح هذا التسجيل على هذا الجهاز';
  static const _outbox = 'outbox';

  Future<OutboxItem> _seal(OutboxItem item) async => OutboxItem(
        id: item.id,
        userId: item.userId,
        kind: item.kind,
        payload: {_field: await cipher.encrypt(jsonEncode(item.payload), _outbox)},
        label: item.label,
        createdAt: item.createdAt,
        orderKey: item.orderKey,
        status: item.status,
        error: item.error,
        attempts: item.attempts,
      );

  Future<OutboxItem> _open(OutboxItem item) async {
    final sealed = item.payload[_field];
    if (sealed is! String) return item; // queued before encryption
    final plain = await cipher.decrypt(sealed, _outbox);
    return OutboxItem(
      id: item.id,
      userId: item.userId,
      kind: item.kind,
      payload: plain == null ? const {} : jsonDecode(plain) as Map<String, dynamic>,
      label: item.label,
      createdAt: item.createdAt,
      orderKey: item.orderKey,
      // unreadable on this phone (its key is gone): shown in the sync center, never replayed empty
      status: plain == null ? 'failed' : item.status,
      error: plain == null ? unreadable : item.error,
      attempts: item.attempts,
    );
  }

  @override
  Future<List<OutboxItem>> items() async => Future.wait((await inner.items()).map(_open));

  @override
  Future<OutboxItem> add(OutboxItem item) async {
    final saved = await inner.add(await _seal(item));
    return OutboxItem(
      id: saved.id,
      userId: item.userId,
      kind: item.kind,
      payload: item.payload,
      label: item.label,
      createdAt: item.createdAt,
      orderKey: item.orderKey,
    );
  }

  @override
  Future<void> update(OutboxItem item) async => inner.update(await _seal(item));

  @override
  Future<void> remove(int id) => inner.remove(id);

  @override
  Future<String?> readCache(String key) async {
    final saved = await inner.readCache(key);
    return saved == null ? null : cipher.decrypt(saved, 'cache:$key');
  }

  @override
  Future<void> writeCache(String key, String json) async => inner.writeCache(key, await cipher.encrypt(json, 'cache:$key'));

  @override
  Future<void> pruneCache(Duration age) => inner.pruneCache(age);
}
