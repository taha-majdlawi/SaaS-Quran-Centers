import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/i18n.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/ui.dart';
import '../reports/reports_repository.dart';
import '../../core/offline/sync_service.dart';

Map<String, String> get _status => currentStrings.labels.deletionStatus;
Map<String, String> get _roles => currentStrings.labels.roles;

/// Admin: data-deletion requests from members / families.
class DeletionRequestsScreen extends StatefulWidget {
  const DeletionRequestsScreen({super.key});

  @override
  State<DeletionRequestsScreen> createState() => _DeletionRequestsScreenState();
}

class _DeletionRequestsScreenState extends State<DeletionRequestsScreen> {
  Future<List<Map<String, dynamic>>>? _future;
  String? _orgId;

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await SyncService.instance.raw('deletion-requests:$_orgId', () => AppSupabase.client.rpc('list_deletion_requests', params: {'p_org': _orgId})) as List;
    return [for (final r in rows) r as Map<String, dynamic>];
  }

  Future<void> _review(String id, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AppSupabase.client.rpc('review_deletion_request', params: {'p_org': _orgId, 'p_id': id, 'p_status': status});
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(currentStrings.priv.updated)));
      setState(() => _future = _load());
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e, currentStrings.priv.updateFailed))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final org = context.watch<TenantController>().active?.organization;
    if (org == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_orgId != org.id) {
      _orgId = org.id;
      _future = _load();
    }
    return Scaffold(
      appBar: AppBar(
        leading: DrawerLeading(),title: Text(tr(context).priv.requestsTitle)),
      drawer: const AppDrawer(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(onRetry: () => setState(() => _future = _load()));
          final rows = snap.data;
          if (rows == null) return const Center(child: CircularProgressIndicator());
          if (rows.isEmpty) return EmptyState(icon: Icons.privacy_tip_rounded, title: tr(context).priv.noRequests);
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(tr(context).priv.reviewHint, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 8),
            for (final r in rows)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('${r['name'] ?? '—'} (${_roles[r['role']] ?? r['role']})', style: const TextStyle(fontWeight: FontWeight.w700))),
                      StatusChip(label: _status[r['status']] ?? '${r['status']}', color: r['status'] == 'pending' ? Colors.amber : Colors.grey),
                    ]),
                    if (r['student'] != null) Text(fmt(tr(context).priv.student, {'name': r['student']}), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    if (r['reason'] != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${r['reason']}')),
                    Text(reportDay(r['created_at']), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    if (r['status'] == 'pending' || r['status'] == 'approved')
                      Wrap(spacing: 8, children: [
                        if (r['status'] == 'pending') ...[
                          TextButton(onPressed: () => _review(r['id'] as String, 'approved'), child: Text(tr(context).priv.approve)),
                          TextButton(onPressed: () => _review(r['id'] as String, 'rejected'), child: Text(tr(context).priv.reject, style: TextStyle(color: Colors.red))),
                        ],
                        TextButton(onPressed: () => _review(r['id'] as String, 'completed'), child: Text(tr(context).priv.done)),
                      ]),
                  ]),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

/// A member / family asks for their own data to be deleted.
class MyPrivacyScreen extends StatefulWidget {
  const MyPrivacyScreen({super.key});

  @override
  State<MyPrivacyScreen> createState() => _MyPrivacyScreenState();
}

class _MyPrivacyScreenState extends State<MyPrivacyScreen> {
  final _reason = TextEditingController();
  Future<Map<String, dynamic>?>? _future;
  String? _orgId;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _load() async =>
      await SyncService.instance.raw('my-deletion:$_orgId', () => AppSupabase.client.rpc('my_deletion_request', params: {'p_org': _orgId})) as Map<String, dynamic>?;

  Future<void> _send() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).priv.confirmTitle),
        content: Text(tr(context).priv.confirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).common.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(context).priv.sendRequest, style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppSupabase.client.rpc('request_account_deletion', params: {'p_org': _orgId, 'p_reason': _reason.text.trim().isEmpty ? null : _reason.text.trim()});
      _reason.clear();
      if (mounted) setState(() => _future = _load());
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e, currentStrings.priv.sendFailed));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final org = context.watch<TenantController>().active?.organization;
    if (org == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_orgId != org.id) {
      _orgId = org.id;
      _future = _load();
    }
    return Scaffold(
      appBar: AppBar(title: Text(tr(context).priv.title)),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(onRetry: () => setState(() => _future = _load()));
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final last = snap.data;
          final pending = last?['status'] == 'pending';
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(fmt(tr(context).priv.intro, {'org': org.name}), style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            if (_error != null) MessageBanner(message: _error!),
            if (last != null)
              Card(child: ListTile(leading: Icon(Icons.history_rounded), title: Text(fmt(tr(context).priv.last, {'status': _status[last['status']] ?? last['status']})), subtitle: Text(reportDay(last['created_at'])))),
            if (!pending) ...[
              TextField(controller: _reason, maxLines: 3, maxLength: 500, decoration: InputDecoration(labelText: tr(context).priv.reason)),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : _send,
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: _busy ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(tr(context).priv.submit),
              ),
            ],
          ]);
        },
      ),
    );
  }
}
