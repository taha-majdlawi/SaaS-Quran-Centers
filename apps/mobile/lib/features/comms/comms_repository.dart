import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/offline/sync_service.dart';
import '../../core/i18n/i18n.dart';

Map<String, String> get kRoleLabels => currentStrings.labels.roles;

Map<String, String> get kAudienceLabels => currentStrings.labels.audience;

class ChatThreadRow {
  const ChatThreadRow({
    required this.threadId,
    required this.otherId,
    required this.otherName,
    required this.otherRole,
    required this.unread,
    required this.muted,
    required this.canReply,
    this.lastAt,
    this.lastBody,
    this.lastMine = false,
    this.lastDeleted = false,
  });
  final String threadId;
  final String otherId;
  final String otherName;
  final String otherRole;
  final String? lastAt;
  final String? lastBody;
  final bool lastMine;
  final bool lastDeleted;
  final int unread;
  final bool muted;
  final bool canReply;

  factory ChatThreadRow.fromJson(Map<String, dynamic> j) => ChatThreadRow(
        threadId: j['thread_id'] as String,
        otherId: j['other_id'] as String,
        otherName: (j['other_name'] as String?) ?? '—',
        otherRole: (j['other_role'] as String?) ?? '',
        lastAt: j['last_message_at'] as String?,
        lastBody: j['last_body'] as String?,
        lastMine: j['last_mine'] as bool? ?? false,
        lastDeleted: j['last_deleted'] as bool? ?? false,
        unread: (j['unread'] as num?)?.toInt() ?? 0,
        muted: j['muted'] as bool? ?? false,
        canReply: j['can_reply'] as bool? ?? false,
      );
}

class ChatContact {
  const ChatContact({required this.userId, required this.name, required this.role, this.detail});
  final String userId;
  final String name;
  final String role;
  final String? detail;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.mine,
    required this.body,
    required this.createdAt,
    this.editedAt,
    this.readAt,
    this.imagePath,
    this.deletedAt,
    this.imageDeletedAt,
    this.localImage,
    this.sending = false,
    this.failed = false,
  });
  final String id;
  final bool mine;
  final String body;
  final String createdAt;
  final String? editedAt;
  final String? readAt;
  final String? imagePath;
  final String? deletedAt;
  /// The picture was deleted after the center's keeping time (0091); the message stays.
  final String? imageDeletedAt;
  /// Set only on the optimistic local echo, before the server confirms it (an in-memory picture preview).
  final Uint8List? localImage;
  /// True for the brief window between tapping send and the server confirming it.
  final bool sending;
  final bool failed;

  bool get deleted => deletedAt != null;
  bool get editable => mine && !deleted && !sending && body.isNotEmpty && DateTime.now().difference(DateTime.parse(createdAt)) < const Duration(minutes: 30);
  /// Deletion has no time limit (removing your own words is always allowed), unlike editing.
  bool get deletable => mine && !deleted && !sending;

  ChatMessage copyWith({String? id, String? createdAt, String? readAt, String? imagePath, bool? sending, bool? failed}) => ChatMessage(
        id: id ?? this.id,
        mine: mine,
        body: body,
        createdAt: createdAt ?? this.createdAt,
        editedAt: editedAt,
        readAt: readAt ?? this.readAt,
        imagePath: imagePath ?? this.imagePath,
        deletedAt: deletedAt,
        imageDeletedAt: imageDeletedAt,
        // kept while sending OR failed (the retry bubble still needs its preview); dropped only once fully confirmed
        localImage: ((sending ?? this.sending) || (failed ?? this.failed)) ? localImage : null,
        sending: sending ?? this.sending,
        failed: failed ?? this.failed,
      );

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        mine: j['mine'] as bool? ?? false,
        body: j['body'] as String,
        createdAt: j['created_at'] as String,
        editedAt: j['edited_at'] as String?,
        readAt: j['read_at'] as String?,
        imagePath: j['image_path'] as String?,
        deletedAt: j['deleted_at'] as String?,
        imageDeletedAt: j['image_deleted_at'] as String?,
      );
}

class NotificationItem {
  const NotificationItem({required this.id, required this.eventKey, required this.title, required this.createdAt, required this.read, this.body, this.refId, this.deepLink});
  final String id;
  final String eventKey;
  final String title;
  final String? body;
  final String? refId;
  final String? deepLink;
  final String createdAt;
  final bool read;

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: j['id'] as String,
        eventKey: j['event_key'] as String,
        title: j['title'] as String,
        body: j['body'] as String?,
        refId: j['ref_id'] as String?,
        deepLink: j['deep_link'] as String?,
        createdAt: j['created_at'] as String,
        read: j['read'] as bool? ?? false,
      );
}

/// One switch on the person's notification-preferences screen.
class NotificationType {
  const NotificationType({required this.key, required this.name, required this.enabled});
  final String key;
  final String name;
  final bool enabled;

  NotificationType copyWith({bool? enabled}) => NotificationType(key: key, name: name, enabled: enabled ?? this.enabled);
}

class NotificationPrefs {
  const NotificationPrefs({required this.types, required this.quietFrom, required this.quietTo, required this.paused});
  final List<NotificationType> types;
  final String quietFrom;
  final String quietTo;
  final bool paused;
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    required this.pinned,
    required this.draft,
    required this.canEdit,
    this.circleId,
    this.circleName,
    this.publishedAt,
    this.expiresOn,
    this.author,
  });
  final String id;
  final String title;
  final String body;
  final String audience;
  final String? circleId;
  final String? circleName;
  final bool pinned;
  final bool draft;
  final bool canEdit;
  final String? publishedAt;
  final String? expiresOn;
  final String? author;

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        audience: j['audience'] as String,
        circleId: j['circle_id'] as String?,
        circleName: j['circle_name'] as String?,
        pinned: j['pinned'] as bool? ?? false,
        draft: j['draft'] as bool? ?? false,
        canEdit: j['can_edit'] as bool? ?? false,
        publishedAt: j['published_at'] as String?,
        expiresOn: j['expires_on'] as String?,
        author: j['author'] as String?,
      );
}

/// Mirrors apps/web's lib/comms/actions.ts. Who may message whom, audience of an
/// announcement and inbox preferences are all enforced by SQL RPCs.
class CommsRepository {
  CommsRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  List<Map<String, dynamic>> _list(dynamic v) => [for (final e in (v as List? ?? const [])) e as Map<String, dynamic>];

  // ---- chat ------------------------------------------------------------------

  Future<List<ChatThreadRow>> threads(String orgId) async =>
      [for (final t in _list((await SyncService.instance.raw('comms.threads:$orgId', () => _client.rpc('chat_threads_list', params: {'p_org': orgId}))))) ChatThreadRow.fromJson(t)];

  Future<List<ChatContact>> contacts(String orgId) async => [
        for (final c in _list((await SyncService.instance.raw('comms.contacts:$orgId', () => _client.rpc('chat_contacts', params: {'p_org': orgId})))))
          ChatContact(userId: c['user_id'] as String, name: c['name'] as String, role: c['role'] as String, detail: c['detail'] as String?),
      ];

  Future<int> unreadChat(String orgId) async => ((await SyncService.instance.raw('comms.unreadChat:$orgId', () => _client.rpc('chat_unread_count', params: {'p_org': orgId}))) as num).toInt();

  Future<String?> threadWith(String orgId, String otherId) async =>
      await _client.rpc('chat_thread_with', params: {'p_org': orgId, 'p_other': otherId}) as String?;

  Future<List<ChatMessage>> messages(String orgId, String threadId) async => [
        for (final m in _list((await SyncService.instance.raw('comms.messages:$orgId:$threadId', () => _client.rpc('chat_thread_messages', params: {'p_org': orgId, 'p_thread': threadId, 'p_after': null, 'p_limit': 80})))))
          ChatMessage.fromJson(m),
      ];

  /// Only what is newer than [after] (ISO created_at) - the light poll used once the thread id is known.
  Future<List<ChatMessage>> messagesAfter(String orgId, String threadId, {String? after, int limit = 60}) async => [
        for (final m in _list(await _client.rpc('chat_thread_messages', params: {'p_org': orgId, 'p_thread': threadId, 'p_after': after, 'p_limit': limit})))
          ChatMessage.fromJson(m),
      ];

  Future<void> markRead(String threadId) => _client.rpc('mark_thread_read', params: {'p_thread': threadId});

  /// One client_ref per composed message: a retry after a dropped response never double-sends.
  /// Returns {message_id, thread_id, duplicate} so the caller can show the real message instantly (no reload round-trip).
  Future<Map<String, dynamic>> send(String orgId, String otherId, String body, {String? clientRef}) async =>
      Map<String, dynamic>.from(await _client.rpc('send_chat_message', params: {
        'p_org': orgId,
        'p_other': otherId,
        'p_body': body,
        'p_client_ref': clientRef ?? _uuid.v4(),
      }) as Map);

  /// Uploads a picture into `<org>/<me>/` (private bucket) and sends it as a message.
  /// Needs the network (a picture is never queued offline).
  Future<Map<String, dynamic>> sendImage(String orgId, String otherId, Uint8List bytes, String extension, {String caption = '', String? clientRef}) async {
    final me = _client.auth.currentUser!.id;
    final ext = const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension.toLowerCase()) ? extension.toLowerCase() : 'jpg';
    final path = '$orgId/$me/${_uuid.v4()}.${ext == 'jpeg' ? 'jpg' : ext}';
    final mime = ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
    try {
      await _client.storage.from('chat-images').uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime));
    } on StorageException {
      // refused because the center's storage is full (0091)? say so
      final st = await _client.rpc('org_storage', params: {'p_org': orgId}).catchError((_) => null);
      if (st is Map && st['full'] == true) throw StateError(currentStrings.chat.storageFull);
      rethrow;
    }
    return Map<String, dynamic>.from(await _client.rpc('send_chat_message', params: {
      'p_org': orgId,
      'p_other': otherId,
      'p_body': caption,
      'p_client_ref': clientRef ?? _uuid.v4(),
      'p_image_path': path,
    }) as Map);
  }

  final Map<String, ({String url, DateTime at})> _signed = {};

  /// A short-lived link to a private picture (kept for 50 minutes, the link lives 60).
  Future<String> imageUrl(String path) async {
    final hit = _signed[path];
    if (hit != null && DateTime.now().difference(hit.at) < const Duration(minutes: 50)) return hit.url;
    final url = await _client.storage.from('chat-images').createSignedUrl(path, 3600);
    _signed[path] = (url: url, at: DateTime.now());
    return url;
  }

  Future<void> edit(String messageId, String body) => _client.rpc('edit_chat_message', params: {'p_message': messageId, 'p_body': body});

  /// Deletes my own message (tombstone) and, if it carried a picture, removes it from storage too.
  Future<void> deleteMessage(String messageId) async {
    final r = await _client.rpc('delete_chat_message', params: {'p_message': messageId}) as Map;
    final path = r['image_path'] as String?;
    if (path != null) {
      try {
        await _client.storage.from('chat-images').remove([path]);
      } catch (_) {}
    }
  }

  Future<void> setMuted(String threadId, bool muted) => _client.rpc('set_thread_muted', params: {'p_thread': threadId, 'p_muted': muted});

  // ---- notifications ------------------------------------------------------------

  Future<List<NotificationItem>> notifications(String orgId) => SyncService.instance.cached<List<NotificationItem>>(
        'notifications:$orgId',
        () async => await _client.rpc('my_notifications', params: {'p_org': orgId, 'p_limit': 80}),
        (rows) => [for (final n in _list(rows)) NotificationItem.fromJson(n)],
      );

  Future<int> unreadNotifications(String orgId) async =>
      ((await SyncService.instance.raw('comms.unreadNotifications:$orgId', () => _client.rpc('unread_notifications_count', params: {'p_org': orgId}))) as num).toInt();

  Future<void> markAllRead(String orgId) => _client.rpc('mark_notifications_read', params: {'p_org': orgId, 'p_ids': null});

  Future<NotificationPrefs> prefs(String orgId) async {
    final j = (await SyncService.instance.raw('comms.prefs:$orgId', () => _client.rpc('my_notification_types', params: {'p_org': orgId}))) as Map<String, dynamic>;
    return NotificationPrefs(
      types: [for (final t in _list(j['types'])) NotificationType(key: t['event_key'] as String, name: t['name'] as String, enabled: t['enabled'] as bool? ?? true)],
      quietFrom: j['quiet_from'] as String? ?? '',
      quietTo: j['quiet_to'] as String? ?? '',
      paused: j['paused'] as bool? ?? false,
    );
  }

  Future<void> setPref(String orgId, String event, bool enabled) =>
      _client.rpc('set_notification_pref', params: {'p_org': orgId, 'p_event': event, 'p_enabled': enabled});

  // ---- announcements ---------------------------------------------------------------

  Future<List<Announcement>> announcements(String orgId) async =>
      [for (final a in _list((await SyncService.instance.raw('comms.announcements:$orgId', () => _client.rpc('list_announcements', params: {'p_org': orgId}))))) Announcement.fromJson(a)];

  Future<void> saveAnnouncement(
    String orgId, {
    String? id,
    required String title,
    required String body,
    required String audience,
    String? circleId,
    required bool pinned,
    required bool publish,
    String? expiresOn,
  }) {
    return _client.rpc('save_announcement', params: {
      'p_org': orgId,
      'p_id': id,
      'p_title': title,
      'p_body': body,
      'p_audience': audience,
      'p_circle': circleId,
      'p_pinned': pinned,
      'p_publish': publish,
      'p_expires': expiresOn,
    });
  }

  Future<void> deleteAnnouncement(String orgId, String id) => _client.rpc('delete_announcement', params: {'p_org': orgId, 'p_id': id});

  Future<List<({String id, String name})>> myCircles(String orgId, {required bool isAdmin, required String userId}) async {
    var q = _client.from('circles').select('id, name').eq('organization_id', orgId);
    if (!isAdmin) {
      final mine = (await SyncService.instance.raw('comms.myCircles:$orgId:$isAdmin:$userId', () => _client.rpc('my_circle_ids', params: {'p_org': orgId}))) as List;
      if (mine.isEmpty) return [];
      q = q.inFilter('id', [for (final m in mine) m['id'] as String]);
    }
    final rows = await q.order('name');
    return [for (final r in rows as List) (id: r['id'] as String, name: r['name'] as String)];
  }
}
