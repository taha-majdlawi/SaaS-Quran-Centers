import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import 'notifications_repository.dart';

/// Mirrors apps/web's /notifications page: a send form plus the org's
/// notification log.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repository = NotificationsRepository(AppSupabase.client);
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String? _loadedForOrgId;
  late Future<void> _dataFuture;
  List<NotificationLogEntry> _log = [];
  List<NotificationRecipientOption> _members = [];
  String? _recipientId;
  bool _sending = false;
  String? _message;
  bool _isError = false;

  Future<void> _load(String orgId) async {
    final results = await Future.wait([
      _repository.fetchLog(orgId),
      _repository.fetchMembers(orgId),
    ]);
    _log = results[0] as List<NotificationLogEntry>;
    _members = results[1] as List<NotificationRecipientOption>;
  }

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _dataFuture = _load(orgId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_recipientId == null || _titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) return;
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await _repository.sendNotification(
        organizationId: _loadedForOrgId!,
        userId: _recipientId!,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );
      _titleController.clear();
      _bodyController.clear();
      if (mounted) {
        setState(() {
          _message = 'تم الإرسال';
          _isError = false;
          _recipientId = null;
        });
        _reload(_loadedForOrgId!);
      }
    } catch (e) {
      if (mounted) setState(() { _message = 'حدث خطأ أثناء الإرسال'; _isError = true; });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      drawer: const AppDrawer(),
      body: orgId == null
          ? const SizedBox.shrink()
          : FutureBuilder<void>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('إرسال إشعار', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (_message != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _message!,
                          style: TextStyle(color: _isError ? Colors.red.shade700 : Colors.green.shade700),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: _recipientId,
                      decoration: const InputDecoration(labelText: 'المستلم', border: OutlineInputBorder()),
                      items: _members.map((m) => DropdownMenuItem(value: m.userId, child: Text(m.label))).toList(),
                      onChanged: (v) => setState(() => _recipientId = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bodyController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'النص', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _sending ? null : _send,
                      child: _sending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('إرسال'),
                    ),
                    const Divider(height: 32),
                    Text('سجل الإشعارات', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_log.isEmpty)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('لا يوجد إشعارات بعد')))
                    else
                      ..._log.map((n) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(n.title),
                              subtitle: Text('${n.body}\n${n.sentAt}'),
                              isThreeLine: true,
                              trailing: Text(n.readAt != null ? 'مقروء' : 'غير مقروء', style: const TextStyle(fontSize: 12)),
                            ),
                          )),
                  ],
                );
              },
            ),
    );
  }
}
