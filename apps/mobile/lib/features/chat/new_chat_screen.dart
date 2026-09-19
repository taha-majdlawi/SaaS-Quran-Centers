import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'chat_repository.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _repository = ChatRepository(AppSupabase.client);
  List<ChatMemberOption> _members = [];
  String? _selectedUserId;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orgId = context.read<TenantController>().active!.organization.id;
    final myUserId = context.read<AuthController>().currentUser!.id;
    final members = await _repository.fetchMembers(orgId);
    _members = members.where((m) => m.userId != myUserId).toList();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (_selectedUserId == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final orgId = context.read<TenantController>().active!.organization.id;
      final myUserId = context.read<AuthController>().currentUser!.id;
      final threadId = await _repository.createThread(
        organizationId: orgId,
        myUserId: myUserId,
        otherUserId: _selectedUserId!,
      );
      if (mounted) context.pushReplacement('/chat/$threadId');
    } catch (e) {
      setState(() => _error = 'فشل إنشاء المحادثة - حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('محادثة جديدة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUserId,
                    decoration: const InputDecoration(labelText: 'مع'),
                    items: _members.map((m) => DropdownMenuItem(value: m.userId, child: Text(m.label))).toList(),
                    onChanged: (v) => setState(() => _selectedUserId = v),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('بدء المحادثة'),
                  ),
                ],
              ),
            ),
    );
  }
}
