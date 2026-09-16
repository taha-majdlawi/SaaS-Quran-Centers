import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/chat/chat_realtime.dart';
import '../../core/supabase/supabase_client.dart';
import 'chat_repository.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key, required this.threadId});

  final String threadId;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _repository = ChatRepository(AppSupabase.client);
  final _bodyController = TextEditingController();
  late final ChatThreadRealtime _realtime;
  List<ChatMessage>? _messages;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    // Delivers messages from the OTHER participant live - my own sends are
    // appended locally the moment the insert succeeds (below), so this only
    // needs to dedupe by id in case the broadcast for my own message arrives
    // too (it will, harmlessly - see _onIncomingMessage).
    _realtime = ChatThreadRealtime(threadId: widget.threadId, onMessage: _onIncomingMessage);
  }

  Future<void> _load() async {
    final messages = await _repository.fetchMessages(widget.threadId);
    if (mounted) setState(() => _messages = messages);
  }

  void _onIncomingMessage(ChatMessage message) {
    final current = _messages;
    if (current == null || current.any((m) => m.id == message.id)) return;
    setState(() => _messages = [...current, message]);
  }

  @override
  void dispose() {
    _realtime.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    final myUserId = context.read<AuthController>().currentUser!.id;
    try {
      final sent = await _repository.sendMessage(threadId: widget.threadId, senderId: myUserId, body: body);
      _bodyController.clear();
      if (mounted) {
        setState(() {
          _messages = [...?_messages, sent];
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = context.read<AuthController>().currentUser!.id;

    return Scaffold(
      appBar: AppBar(title: const Text('محادثة')),
      body: Column(
        children: [
          Expanded(
            child: _messages == null
                ? const Center(child: CircularProgressIndicator())
                : _messages!.isEmpty
                    ? const Center(child: Text('لا يوجد رسائل بعد'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages!.length,
                        itemBuilder: (context, index) {
                          final m = _messages![index];
                          final mine = m.senderId == myUserId;
                          return Align(
                            alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              constraints: const BoxConstraints(maxWidth: 280),
                              decoration: BoxDecoration(
                                color: mine ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                m.body,
                                style: TextStyle(color: mine ? Colors.white : Colors.black87),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bodyController,
                      decoration: const InputDecoration(hintText: 'اكتب رسالة...', border: OutlineInputBorder()),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
