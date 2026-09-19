import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
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
  late Future<List<ChatMessage>> _messagesFuture;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _repository.fetchMessages(widget.threadId);
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    final myUserId = context.read<AuthController>().currentUser!.id;
    await _repository.sendMessage(threadId: widget.threadId, senderId: myUserId, body: body);
    _bodyController.clear();
    if (mounted) {
      setState(() {
        _messagesFuture = _repository.fetchMessages(widget.threadId);
        _sending = false;
      });
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
            child: FutureBuilder<List<ChatMessage>>(
              future: _messagesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text('لا يوجد رسائل بعد'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
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
                      decoration: const InputDecoration(hintText: 'اكتب رسالة...'),
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
