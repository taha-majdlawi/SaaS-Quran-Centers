import 'package:flutter/material.dart';
import '../../core/widgets/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import 'members_repository.dart';

/// Mirrors apps/web's /members page: the member table (with edit links),
/// an invite-by-email form, and the pending-invitation list.
class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  final _repository = MembersRepository(AppSupabase.client);
  String? _loadedForOrgId;
  late Future<void> _dataFuture;

  List<MemberRow> _members = [];
  List<PendingInvitation> _invitations = [];

  final _emailController = TextEditingController();
  String _inviteRole = 'teacher';
  bool _inviting = false;
  String? _message;
  bool _isError = false;

  Future<void> _load(String orgId) async {
    final results = await Future.wait<dynamic>([
      _repository.fetchMembers(orgId),
      _repository.fetchPendingInvitations(orgId),
    ]);
    _members = results[0] as List<MemberRow>;
    _invitations = results[1] as List<PendingInvitation>;
  }

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _dataFuture = _load(orgId);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _inviting = true;
      _message = null;
    });
    try {
      await _repository.createInvitation(organizationId: _loadedForOrgId!, email: email, role: _inviteRole);
      _emailController.clear();
      if (mounted) {
        setState(() { _message = 'تم إنشاء الدعوة'; _isError = false; });
        _reload(_loadedForOrgId!);
      }
    } catch (e) {
      if (mounted) setState(() { _message = friendlyError(e, 'حدث خطأ أثناء الدعوة'); _isError = true; });
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }

    return Scaffold(
      appBar: AppBar(
        leading: const DrawerLeading(),title: const Text('الأعضاء والأدوار')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/members/new-teacher');
          if (mounted && orgId != null) setState(() => _reload(orgId));
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('معلم جديد'),
      ),
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
                    if (_message != null) MessageBanner(message: _message!, isError: _isError),
                    ..._members.map((m) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(m.fullName ?? m.email ?? '—'),
                            subtitle: Text(
                              '${kMemberRoleLabels[m.role] ?? m.role} · ${kMemberStatusLabels[m.status] ?? m.status}',
                            ),
                            trailing: TextButton(
                              onPressed: () async {
                                await context.push('/members/${m.id}');
                                if (mounted) setState(() => _reload(orgId));
                              },
                              child: const Text('تعديل'),
                            ),
                          ),
                        )),
                    const Divider(height: 32),
                    Text('دعوة عضو جديد', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _inviteRole,
                      decoration: const InputDecoration(labelText: 'الدور'),
                      items: kMemberRoleLabels.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _inviteRole = v ?? _inviteRole),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _inviting ? null : _invite,
                      child: _inviting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('إنشاء دعوة'),
                    ),
                    if (_invitations.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('دعوات لسه ما انضمّت', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      ..._invitations.map((i) => Text('${i.email} — ${kMemberRoleLabels[i.role] ?? i.role}')),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
