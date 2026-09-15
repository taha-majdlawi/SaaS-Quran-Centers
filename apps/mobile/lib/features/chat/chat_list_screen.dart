import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import 'chat_repository.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _repository = ChatRepository(AppSupabase.client);
  late Future<List<ChatThreadSummary>> _threadsFuture;
  String? _loadedForOrgId;

  void _reload() {
    final myUserId = context.read<AuthController>().currentUser!.id;
    _threadsFuture = _repository.fetchMyThreads(myUserId);
  }

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _loadedForOrgId = orgId;
      _reload();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('المحادثات')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/chat/new');
          if (mounted) setState(_reload);
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ChatThreadSummary>>(
        future: _threadsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final threads = snapshot.data!;
          if (threads.isEmpty) {
            return const Center(child: Text('لا يوجد محادثات بعد'));
          }
          return ListView.separated(
            itemCount: threads.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final t = threads[index];
              return ListTile(
                title: Text(t.otherLabel),
                trailing: Text(t.createdAt.split('T').first, style: const TextStyle(fontSize: 12)),
                onTap: () async {
                  await context.push('/chat/${t.id}');
                  if (mounted) setState(_reload);
                },
              );
            },
          );
        },
      ),
    );
  }
}
