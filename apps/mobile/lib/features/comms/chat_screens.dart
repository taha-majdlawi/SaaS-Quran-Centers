import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/i18n/i18n.dart';

import '../../core/access/account_access.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import 'comms_repository.dart';
import '../../core/widgets/net_image.dart';

bool _isStaff(TenantController t) => t.active?.role == OrgRole.admin || t.active?.role == OrgRole.teacher;

// ---------------------------------------------------------------------------
// Conversations
// ---------------------------------------------------------------------------

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _repository = CommsRepository(AppSupabase.client);
  Future<List<ChatThreadRow>>? _future;
  String? _orgId;
  Timer? _timer;
  Timer? _debounce;
  RealtimeChannel? _channel;

  void _reload() {
    if (mounted && _orgId != null) setState(() => _future = _repository.threads(_orgId!));
  }

  /// Any change to a message of mine touches this list (new message, edit, delete, read receipt) -
  /// live over the socket instead of waiting for the poll, several rows in a burst only reload once.
  void _subscribe() {
    _channel = AppSupabase.client
        .channel('chat-list-$_orgId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 400), _reload);
          },
        )
        .subscribe();
  }

  @override
  void initState() {
    super.initState();
    // realtime covers freshness; this is only the fallback for a dropped socket
    _timer = Timer.periodic(const Duration(seconds: 25), (_) => _reload());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _debounce?.cancel();
    if (_channel != null) AppSupabase.client.removeChannel(_channel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final orgId = tenant.active?.organization.id;
    if (orgId != null && orgId != _orgId) {
      _orgId = orgId;
      _future = _repository.threads(orgId);
      if (_channel != null) AppSupabase.client.removeChannel(_channel!);
      _subscribe();
    }
    return Scaffold(
      appBar: AppBar(
        leading: DrawerLeading(),title: Text(tr(context).chat.title)),
      drawer: _isStaff(tenant) ? const AppDrawer() : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/chat/new');
          if (mounted) _reload();
        },
        icon: const Icon(Icons.edit_rounded),
        label: Text(tr(context).chat.newChat),
      ),
      body: _future == null
          ? const SizedBox.shrink()
          : AsyncBody<List<ChatThreadRow>>(
              future: _future!,
              onRetry: _reload,
              builder: (context, threads) => threads.isEmpty
                  ? EmptyState(icon: Icons.chat_bubble_outline_rounded, title: tr(context).chat.none, subtitle: tr(context).chat.noneHint)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      children: [
                        for (final t in threads)
                          Card(
                            child: ListTile(
                              onTap: () async {
                                await context.push('/chat/${t.otherId}');
                                if (mounted) _reload();
                              },
                              leading: InitialAvatar(t.otherName),
                              title: Row(children: [
                                Flexible(child: Text(t.otherName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                                const SizedBox(width: 6),
                                Text(kRoleLabels[t.otherRole] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
                                if (t.muted) const Padding(padding: EdgeInsetsDirectional.only(start: 4), child: Icon(Icons.notifications_off_outlined, size: 14, color: Colors.grey)),
                              ]),
                              subtitle: Text(t.lastDeleted ? tr(context).chat.deletedLast : '${t.lastMine ? tr(context).chat.you : ''}${t.lastBody ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: t.lastDeleted ? const TextStyle(fontStyle: FontStyle.italic) : null),
                              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text(t.lastAt == null ? '' : formatDate(t.lastAt), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                                if (t.unread > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(12)),
                                    child: Text('${t.unread}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                              ]),
                            ),
                          ),
                      ],
                    ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Who can I message
// ---------------------------------------------------------------------------

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _repository = CommsRepository(AppSupabase.client);
  late final Future<List<ChatContact>> _future = _repository.contacts(context.read<TenantController>().active!.organization.id);
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context).chat.newChat)),
      body: AsyncBody<List<ChatContact>>(
        future: _future,
        builder: (context, contacts) {
          final items = contacts.where((c) => _query.isEmpty || c.name.contains(_query)).toList();
          return Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(onChanged: (v) => setState(() => _query = v.trim()), decoration: InputDecoration(hintText: tr(context).chat.searchName, prefixIcon: Icon(Icons.search_rounded))),
            ),
            Expanded(
              child: items.isEmpty
                  ? EmptyState(icon: Icons.person_search_rounded, title: tr(context).chat.noContacts)
                  : ListView(children: [
                      for (final c in items)
                        ListTile(
                          leading: InitialAvatar(c.name),
                          title: Text(c.name),
                          subtitle: Text('${kRoleLabels[c.role] ?? ''}${c.detail == null ? '' : '  ·  ${c.detail}'}'),
                          onTap: () => context.pushReplacement('/chat/${c.userId}'),
                        ),
                    ]),
            ),
          ]);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One conversation (live)
// ---------------------------------------------------------------------------

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key, required this.otherId});

  final String otherId;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _repository = CommsRepository(AppSupabase.client);
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _uuid = const Uuid();
  List<ChatMessage> _messages = [];
  ChatThreadRow? _thread;
  String? _threadId;
  String? _name;
  String? _role;
  bool _canReply = true;
  bool _loading = true;
  bool _sending = false;
  Uint8List? _attachment; // picked but not sent yet
  String _attachmentExt = 'jpg';
  String? _error;
  Timer? _poll;
  RealtimeChannel? _channel;
  bool _markingRead = false;

  String get _orgId => context.read<TenantController>().active!.organization.id;
  String? get _myId => AppSupabase.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _init();
    // realtime delivers new/edited/read/deleted messages the instant they happen; this is only
    // the fallback for a socket that dropped without Flutter noticing.
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _pollNew());
  }

  @override
  void dispose() {
    _poll?.cancel();
    if (_channel != null) AppSupabase.client.removeChannel(_channel!);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final orgId = _orgId;
      final results = await Future.wait([_repository.threads(orgId), _repository.contacts(orgId)]);
      final threads = results[0] as List<ChatThreadRow>;
      final contacts = results[1] as List<ChatContact>;
      final thread = threads.where((t) => t.otherId == widget.otherId).firstOrNull;
      final contact = contacts.where((c) => c.userId == widget.otherId).firstOrNull;
      var msgs = <ChatMessage>[];
      if (thread != null) {
        msgs = await _repository.messages(orgId, thread.threadId);
        _maybeMarkRead(msgs);
      }
      if (!mounted) return;
      setState(() {
        _thread = thread;
        _name = thread?.otherName ?? contact?.name;
        _role = thread?.otherRole ?? contact?.role;
        _canReply = thread?.canReply ?? (contact != null);
        _messages = msgs;
        _loading = false;
      });
      if (thread != null) _subscribe(thread.threadId);
      _scrollToBottomSoon();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribe(String threadId) {
    if (_threadId == threadId && _channel != null) return;
    _threadId = threadId;
    if (_channel != null) AppSupabase.client.removeChannel(_channel!);
    _channel = AppSupabase.client
        .channel('chat-thread-$threadId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'thread_id', value: threadId),
          callback: (payload) {
            if (payload.newRecord.isEmpty) return;
            _mergeRow(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// A light safety-net poll: only rows newer than the last one we hold (edits/reads on OLD rows
  /// arrive over the socket instead, which is why this alone would not be enough).
  Future<void> _pollNew() async {
    if (_threadId == null) {
      // no thread existed when this screen opened - maybe the other side just started one
      try {
        final id = await _repository.threadWith(_orgId, widget.otherId);
        if (id == null) return;
        _subscribe(id);
        final msgs = await _repository.messages(_orgId, id);
        if (!mounted) return;
        setState(() => _messages = msgs);
        _maybeMarkRead(msgs);
        _scrollToBottomSoon();
      } catch (_) {}
      return;
    }
    try {
      final last = _messages.isEmpty ? null : _messages.last.createdAt;
      final fresh = await _repository.messagesAfter(_orgId, _threadId!, after: last);
      if (fresh.isEmpty) return;
      for (final m in fresh) {
        _upsert(m);
      }
      _maybeMarkRead(fresh);
      if (mounted) setState(() {});
      _scrollToBottomSoon();
    } catch (_) {}
  }

  ChatMessage _fromRow(Map<String, dynamic> row) => ChatMessage(
        id: row['id'] as String,
        mine: row['sender_id'] == _myId,
        body: row['body'] as String? ?? '',
        createdAt: row['created_at'] as String,
        editedAt: row['edited_at'] as String?,
        readAt: row['read_at'] as String?,
        imagePath: row['image_path'] as String?,
        deletedAt: row['deleted_at'] as String?,
        imageDeletedAt: row['image_deleted_at'] as String?,
      );

  void _mergeRow(Map<String, dynamic> row) {
    final m = _fromRow(row);
    final grew = _upsert(m);
    if (!mounted) return;
    setState(() {});
    if (!m.mine && m.readAt == null && !m.deleted) _maybeMarkRead([m]);
    if (grew) _scrollToBottomSoon();
  }

  /// Inserts or updates by id, kept sorted by time. Returns true if it was a brand-new message
  /// (not an update of one already shown).
  bool _upsert(ChatMessage m) {
    final i = _messages.indexWhere((x) => x.id == m.id);
    if (i >= 0) {
      _messages[i] = m;
      return false;
    }
    _messages.add(m);
    _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return true;
  }

  /// Reconciles the optimistic local echo with the real id once the send confirms. Realtime and this
  /// call race (both fire once the server commits): if realtime already delivered the authoritative
  /// row, drop the echo instead of renaming it, so a picture never briefly vanishes and nothing is shown twice.
  void _finalizeSent(String localId, String? messageId) {
    if (!mounted) return;
    setState(() {
      if (messageId != null && _messages.any((x) => x.id == messageId)) {
        _messages.removeWhere((x) => x.id == localId);
      } else {
        final i = _messages.indexWhere((x) => x.id == localId);
        if (i >= 0 && messageId != null) _messages[i] = _messages[i].copyWith(id: messageId, sending: false);
      }
    });
  }

  void _maybeMarkRead(List<ChatMessage> candidates) {
    if (_markingRead || _threadId == null) return;
    if (!candidates.any((m) => !m.mine && m.readAt == null && !m.deleted)) return;
    _markingRead = true;
    _repository.markRead(_threadId!).whenComplete(() => _markingRead = false);
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  /// Shows the message instantly (a local echo), then sends in the background - no wait before it appears.
  Future<void> _send() async {
    final text = _input.text.trim();
    final picture = _attachment;
    final ext = _attachmentExt;
    if ((text.isEmpty && picture == null) || _sending) return;
    if (picture != null) {
      try {
        AccessController.instance.ensureCanWrite();
      } on StateError catch (e) {
        setState(() => _error = e.message);
        return;
      }
    }

    final ref = _uuid.v4();
    final localId = 'local-$ref';
    setState(() {
      _sending = true;
      _error = null;
      _messages.add(ChatMessage(
        id: localId,
        mine: true,
        body: text,
        createdAt: DateTime.now().toUtc().toIso8601String(),
        localImage: picture,
        sending: true,
      ));
      _input.clear();
      _attachment = null;
    });
    _scrollToBottomSoon();

    try {
      final result = picture != null
          ? await _repository.sendImage(_orgId, widget.otherId, picture, ext, caption: text, clientRef: ref)
          : await _repository.send(_orgId, widget.otherId, text, clientRef: ref);
      final messageId = result['message_id'] as String?;
      final threadId = result['thread_id'] as String?;
      if (threadId != null) _subscribe(threadId);
      _finalizeSent(localId, messageId);
    } on PostgrestException catch (e) {
      _failLocal(localId, e.message);
    } on StorageException catch (e) {
      _failLocal(localId, e.message.contains('row-level security') ? AccessController.instance.lockMessage : currentStrings.chat.uploadFailed);
    } on StateError catch (e) {
      _failLocal(localId, e.message);
    } catch (_) {
      _failLocal(localId, currentStrings.chat.sendFailed);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _failLocal(String localId, String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      final i = _messages.indexWhere((x) => x.id == localId);
      if (i >= 0) _messages[i] = _messages[i].copyWith(sending: false, failed: true);
    });
  }

  Future<void> _retry(ChatMessage m) async {
    setState(() {
      final i = _messages.indexWhere((x) => x.id == m.id);
      if (i >= 0) _messages[i] = _messages[i].copyWith(failed: false, sending: true);
      _error = null;
    });
    try {
      final result = m.localImage != null
          ? await _repository.sendImage(_orgId, widget.otherId, m.localImage!, _attachmentExt, caption: m.body, clientRef: m.id.replaceFirst('local-', ''))
          : await _repository.send(_orgId, widget.otherId, m.body, clientRef: m.id.replaceFirst('local-', ''));
      final messageId = result['message_id'] as String?;
      final threadId = result['thread_id'] as String?;
      if (threadId != null) _subscribe(threadId);
      _finalizeSent(m.id, messageId);
    } on PostgrestException catch (e) {
      _failLocal(m.id, e.message);
    } on StateError catch (e) {
      _failLocal(m.id, e.message);
    } catch (_) {
      _failLocal(m.id, currentStrings.chat.stillFailing);
    }
  }

  /// Picks a picture and keeps it as a preview above the text box; nothing is sent until the send button.
  Future<void> _pickPicture() async {
    if (_sending) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: Icon(Icons.photo_library_rounded), title: Text(tr(context).chat.gallery), onTap: () => Navigator.pop(context, ImageSource.gallery)),
          ListTile(leading: Icon(Icons.photo_camera_rounded), title: Text(tr(context).chat.camera), onTap: () => Navigator.pop(context, ImageSource.camera)),
        ]),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 5 * 1024 * 1024) {
      setState(() => _error = currentStrings.chat.imageSize);
      return;
    }
    final name = picked.name;
    setState(() {
      _error = null;
      _attachment = bytes;
      _attachmentExt = name.contains('.') ? name.split('.').last : 'jpg';
    });
  }

  Future<void> _edit(ChatMessage m) async {
    final controller = TextEditingController(text: m.body);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).chat.editTitle),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).common.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(minimumSize: Size(90, 44)), child: Text(tr(context).common.save)),
        ],
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    if (ok != true || text.isEmpty) return;
    try {
      await _repository.edit(m.id, text);
      if (mounted) {
        setState(() {
          final i = _messages.indexWhere((x) => x.id == m.id);
          if (i >= 0) {
            _messages[i] = ChatMessage(id: m.id, mine: true, body: text, createdAt: m.createdAt, editedAt: DateTime.now().toUtc().toIso8601String(), readAt: m.readAt, imagePath: m.imagePath);
          }
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _delete(ChatMessage m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).chat.deleteTitle),
        content: Text(tr(context).chat.deleteBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).common.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(tr(context).common.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repository.deleteMessage(m.id);
      if (mounted) {
        setState(() {
          final i = _messages.indexWhere((x) => x.id == m.id);
          if (i >= 0) _messages[i] = ChatMessage(id: m.id, mine: m.mine, body: '', createdAt: m.createdAt, deletedAt: DateTime.now().toUtc().toIso8601String());
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = currentStrings.chat.deleteFailed);
    }
  }

  Future<void> _showActions(ChatMessage m) async {
    if (!m.editable && !m.deletable) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (m.editable) ListTile(leading: Icon(Icons.edit_rounded), title: Text(tr(context).common.edit), onTap: () => Navigator.pop(context, 'edit')),
          if (m.deletable) ListTile(leading: Icon(Icons.delete_outline_rounded, color: Colors.red), title: Text(tr(context).common.delete, style: TextStyle(color: Colors.red)), onTap: () => Navigator.pop(context, 'delete')),
        ]),
      ),
    );
    if (action == 'edit') await _edit(m);
    if (action == 'delete') await _delete(m);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          InitialAvatar(_name ?? '؟', radius: 16),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_name ?? '—', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text(kRoleLabels[_role] ?? '', style: const TextStyle(fontSize: 11.5)),
          ])),
        ]),
        actions: [
          if (_thread != null)
            IconButton(
              tooltip: _thread!.muted ? tr(context).chat.unmute : tr(context).chat.mute,
              icon: Icon(_thread!.muted ? Icons.notifications_off_rounded : Icons.notifications_none_rounded),
              onPressed: () async {
                final next = !_thread!.muted;
                await _repository.setMuted(_thread!.threadId, next);
                if (mounted) {
                  setState(() {
                    final t = _thread!;
                    _thread = ChatThreadRow(
                      threadId: t.threadId,
                      otherId: t.otherId,
                      otherName: t.otherName,
                      otherRole: t.otherRole,
                      unread: t.unread,
                      muted: next,
                      canReply: t.canReply,
                      lastAt: t.lastAt,
                      lastBody: t.lastBody,
                      lastMine: t.lastMine,
                      lastDeleted: t.lastDeleted,
                    );
                  });
                }
              },
            ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? Center(child: Text(tr(context).chat.start))
                  : ListView.builder(
                      controller: _scroll,
                      // anchored at the bottom: opens on the newest message and stays there while pictures load
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[_messages.length - 1 - i];
                        return Align(
                          alignment: m.mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
                          child: GestureDetector(
                            onLongPress: (m.editable || m.deletable) ? () => _showActions(m) : null,
                            onTap: m.failed ? () => _retry(m) : null,
                            child: Opacity(
                              opacity: m.sending ? 0.65 : 1,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                                decoration: BoxDecoration(
                                  color: m.failed ? Colors.red.shade100 : (m.mine ? scheme.primary : Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  if (m.deleted)
                                    Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.block_rounded, size: 14, color: m.mine ? Colors.white70 : Colors.black45),
                                      const SizedBox(width: 4),
                                      Text(tr(context).chat.deleted, style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: m.mine ? Colors.white70 : Colors.black45)),
                                    ])
                                  else ...[
                                    if (m.localImage != null)
                                      Padding(padding: const EdgeInsets.only(bottom: 6), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(m.localImage!, width: 220, fit: BoxFit.cover)))
                                    else if (m.imagePath != null)
                                      _ChatImage(repository: _repository, path: m.imagePath!)
                                    else if (m.imageDeletedAt != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text('📷 ${tr(context).chat.imageDeleted}', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: m.mine ? Colors.white70 : Colors.black45)),
                                      ),
                                    if (m.body.isNotEmpty) Text(m.body, style: TextStyle(color: m.failed ? Colors.red.shade900 : (m.mine ? Colors.white : Colors.black87))),
                                  ],
                                  const SizedBox(height: 3),
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                    Text(
                                      m.failed
                                          ? tr(context).chat.notSent
                                          : m.sending
                                              ? tr(context).chat.sending
                                              : m.deleted
                                                  ? formatDateTime(m.createdAt)
                                                  : '${formatDateTime(m.createdAt)}${m.editedAt == null ? '' : tr(context).chat.edited}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: m.failed ? Colors.red.shade900 : (m.mine ? Colors.white70 : Colors.black45),
                                      ),
                                    ),
                                    if (m.mine && !m.deleted && !m.sending && !m.failed) ...[
                                      const SizedBox(width: 3),
                                      Icon(
                                        m.readAt != null ? Icons.done_all_rounded : Icons.done_rounded,
                                        size: 13,
                                        color: m.readAt != null ? Colors.lightBlueAccent.shade100 : Colors.white70,
                                      ),
                                    ],
                                    if (m.sending) ...[
                                      const SizedBox(width: 4),
                                      SizedBox(width: 9, height: 9, child: CircularProgressIndicator(strokeWidth: 1.5, color: m.mine ? Colors.white70 : Colors.black45)),
                                    ],
                                  ]),
                                ]),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: MessageBanner(message: _error!)),
        if (_canReply && _attachment != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Stack(children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(_attachment!, height: 110, fit: BoxFit.cover)),
                PositionedDirectional(
                  top: 2,
                  end: 2,
                  child: InkWell(
                    onTap: _sending ? null : () => setState(() => _attachment = null),
                    child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close_rounded, size: 16, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ),
        if (_canReply)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Row(children: [
                IconButton(onPressed: _sending ? null : _pickPicture, icon: Icon(Icons.image_rounded), tooltip: tr(context).chat.attach),
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: InputDecoration(hintText: _attachment != null ? tr(context).chat.caption : tr(context).chat.write, counterText: ''),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _send, icon: const Icon(Icons.send_rounded)),
              ]),
            ),
          )
        else
          Padding(padding: EdgeInsets.all(14), child: Text(tr(context).chat.cantReply)),
      ]),
    );
  }
}

/// A picture inside a bubble: fetched through a short-lived signed link (the
/// bucket is private); tap to view it full screen.
class _ChatImage extends StatefulWidget {
  const _ChatImage({required this.repository, required this.path});

  final CommsRepository repository;
  final String path;

  @override
  State<_ChatImage> createState() => _ChatImageState();
}

class _ChatImageState extends State<_ChatImage> {
  // asked once per picture, not on every rebuild of the conversation
  late Future<String> _url = widget.repository.imageUrl(widget.path);

  @override
  void didUpdateWidget(_ChatImage old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) _url = widget.repository.imageUrl(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    return FutureBuilder<String>(
      future: _url,
      builder: (context, snap) {
        final url = snap.data;
        if (url == null) {
          return SizedBox(height: 120, width: 160, child: Center(child: snap.hasError ? const Icon(Icons.broken_image_rounded) : const CircularProgressIndicator(strokeWidth: 2)));
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GestureDetector(
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => Dialog.fullscreen(
                backgroundColor: Colors.black,
                child: Stack(children: [
                  Positioned.fill(child: InteractiveViewer(child: Center(child: NetImage(url, cacheKey: path, fit: BoxFit.contain)))),
                  SafeArea(child: IconButton(color: Colors.white, icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context))),
                ]),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: NetImage(url, width: 220, cacheKey: path, placeholder: const SizedBox(width: 220, height: 160)),
            ),
          ),
        );
      },
    );
  }
}
