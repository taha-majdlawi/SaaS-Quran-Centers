import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/access/account_access.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import 'comms_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted && _orgId != null) setState(() => _future = _repository.threads(_orgId!));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final orgId = tenant.active?.organization.id;
    if (orgId != null && orgId != _orgId) {
      _orgId = orgId;
      _future = _repository.threads(orgId);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('المحادثات')),
      drawer: _isStaff(tenant) ? const AppDrawer() : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/chat/new');
          if (mounted) setState(() => _future = _repository.threads(_orgId!));
        },
        icon: const Icon(Icons.edit_rounded),
        label: const Text('محادثة جديدة'),
      ),
      body: _future == null
          ? const SizedBox.shrink()
          : AsyncBody<List<ChatThreadRow>>(
              future: _future!,
              onRetry: () => setState(() => _future = _repository.threads(_orgId!)),
              builder: (context, threads) => threads.isEmpty
                  ? const EmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'لا توجد محادثات بعد', subtitle: 'ابدأ محادثة جديدة بالزر أدناه')
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      children: [
                        for (final t in threads)
                          Card(
                            child: ListTile(
                              onTap: () async {
                                await context.push('/chat/${t.otherId}');
                                if (mounted) setState(() => _future = _repository.threads(_orgId!));
                              },
                              leading: InitialAvatar(t.otherName),
                              title: Row(children: [
                                Flexible(child: Text(t.otherName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800))),
                                const SizedBox(width: 6),
                                Text(kRoleLabels[t.otherRole] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
                                if (t.muted) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.notifications_off_outlined, size: 14, color: Colors.grey)),
                              ]),
                              subtitle: Text('${t.lastMine ? 'أنت: ' : ''}${t.lastBody ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
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
      appBar: AppBar(title: const Text('محادثة جديدة')),
      body: AsyncBody<List<ChatContact>>(
        future: _future,
        builder: (context, contacts) {
          final items = contacts.where((c) => _query.isEmpty || c.name.contains(_query)).toList();
          return Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(onChanged: (v) => setState(() => _query = v.trim()), decoration: const InputDecoration(hintText: 'ابحث بالاسم', prefixIcon: Icon(Icons.search_rounded))),
            ),
            Expanded(
              child: items.isEmpty
                  ? const EmptyState(icon: Icons.person_search_rounded, title: 'لا يوجد من يمكنك مراسلته')
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
  List<ChatMessage> _messages = [];
  ChatThreadRow? _thread;
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
  String? _pendingRef; // reused if the same text is retried

  String get _orgId => context.read<TenantController>().active!.organization.id;

  @override
  void initState() {
    super.initState();
    _load(first: true);
    // Realtime nudges an immediate refresh; the timer is the fallback when the socket drops.
    _poll = Timer.periodic(const Duration(seconds: 6), (_) => _load());
    _channel = AppSupabase.client
        .channel('chat-${widget.otherId}')
        .onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'chat_messages', callback: (_) => _load())
        .subscribe();
  }

  @override
  void dispose() {
    _poll?.cancel();
    if (_channel != null) AppSupabase.client.removeChannel(_channel!);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool first = false}) async {
    try {
      final orgId = _orgId;
      final threads = await _repository.threads(orgId);
      final thread = threads.where((t) => t.otherId == widget.otherId).firstOrNull;
      var msgs = <ChatMessage>[];
      if (thread != null) {
        msgs = await _repository.messages(orgId, thread.threadId);
        if (msgs.any((m) => !m.mine && m.readAt == null)) await _repository.markRead(thread.threadId);
      }
      if (first && thread == null) {
        final contacts = await _repository.contacts(orgId);
        final c = contacts.where((c) => c.userId == widget.otherId).firstOrNull;
        _name = c?.name;
        _role = c?.role;
        _canReply = c != null;
      }
      if (!mounted) return;
      final grew = msgs.length > _messages.length;
      setState(() {
        _thread = thread ?? _thread;
        _name = thread?.otherName ?? _name;
        _role = thread?.otherRole ?? _role;
        if (thread != null) _canReply = thread.canReply;
        _messages = msgs;
        _loading = false;
      });
      if (grew) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        });
      }
    } catch (_) {
      if (mounted && first) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final picture = _attachment;
    if ((text.isEmpty && picture == null) || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    _pendingRef ??= const Uuid().v4();
    try {
      if (picture != null) {
        AccessController.instance.ensureCanWrite();
        await _repository.sendImage(_orgId, widget.otherId, picture, _attachmentExt, caption: text, clientRef: _pendingRef);
        _attachment = null;
      } else {
        await _repository.send(_orgId, widget.otherId, text, clientRef: _pendingRef);
      }
      _pendingRef = null;
      _input.clear();
      await _load();
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } on StorageException catch (e) {
      setState(() => _error = e.message.contains('row-level security') ? kViewerMessage : 'تعذّر رفع الصورة');
    } on StateError catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'تعذّر الإرسال، تأكد من الإنترنت وحاول مجددًا');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Picks a picture and keeps it as a preview above the text box; nothing is sent until the send button.
  Future<void> _pickPicture() async {
    if (_sending) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.photo_library_rounded), title: const Text('من المعرض'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
          ListTile(leading: const Icon(Icons.photo_camera_rounded), title: const Text('التقاط صورة'), onTap: () => Navigator.pop(context, ImageSource.camera)),
        ]),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 5 * 1024 * 1024) {
      setState(() => _error = 'حجم الصورة الأقصى 5 ميغابايت');
      return;
    }
    final name = picked.name;
    setState(() {
      _error = null;
      _attachment = bytes;
      _attachmentExt = name.contains('.') ? name.split('.').last : 'jpg';
      _pendingRef = null;
    });
  }

  Future<void> _edit(ChatMessage m) async {
    final controller = TextEditingController(text: m.body);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الرسالة'),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(minimumSize: const Size(90, 44)), child: const Text('حفظ')),
        ],
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    if (ok != true || text.isEmpty) return;
    try {
      await _repository.edit(m.id, text);
      await _load();
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
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
              tooltip: _thread!.muted ? 'تفعيل التنبيهات' : 'كتم',
              icon: Icon(_thread!.muted ? Icons.notifications_off_rounded : Icons.notifications_none_rounded),
              onPressed: () async {
                await _repository.setMuted(_thread!.threadId, !_thread!.muted);
                await _load();
              },
            ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? const Center(child: Text('ابدأ المحادثة'))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final m = _messages[i];
                        return Align(
                          alignment: m.mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
                          child: GestureDetector(
                            onLongPress: m.editable ? () => _edit(m) : null,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                              decoration: BoxDecoration(color: m.mine ? scheme.primary : Colors.grey.shade200, borderRadius: BorderRadius.circular(14)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (m.imagePath != null) _ChatImage(repository: _repository, path: m.imagePath!),
                                if (m.body.isNotEmpty) Text(m.body, style: TextStyle(color: m.mine ? Colors.white : Colors.black87)),
                                const SizedBox(height: 3),
                                Text(
                                  '${formatDateTime(m.createdAt)}${m.editedAt == null ? '' : ' · عُدّلت'}${m.mine && m.readAt != null ? ' · ✓✓' : ''}',
                                  style: TextStyle(fontSize: 10, color: m.mine ? Colors.white70 : Colors.black45),
                                ),
                              ]),
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
                IconButton(onPressed: _sending ? null : _pickPicture, icon: const Icon(Icons.image_rounded), tooltip: 'إرفاق صورة'),
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    onChanged: (_) => _pendingRef = null,
                    decoration: InputDecoration(hintText: _attachment != null ? 'أضف تعليقًا (اختياري)...' : 'اكتب رسالتك...', counterText: ''),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _sending ? null : _send, icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded)),
              ]),
            ),
          )
        else
          const Padding(padding: EdgeInsets.all(14), child: Text('لا يمكنك مراسلة هذا المستخدم حاليًا')),
      ]),
    );
  }
}


/// A picture inside a bubble: fetched through a short-lived signed link (the
/// bucket is private); tap to view it full screen.
class _ChatImage extends StatelessWidget {
  const _ChatImage({required this.repository, required this.path});

  final CommsRepository repository;
  final String path;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: repository.imageUrl(path),
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
                  Positioned.fill(child: InteractiveViewer(child: Center(child: Image.network(url)))),
                  SafeArea(child: IconButton(color: Colors.white, icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context))),
                ]),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(url, width: 220, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.broken_image_rounded)),
            ),
          ),
        );
      },
    );
  }
}
