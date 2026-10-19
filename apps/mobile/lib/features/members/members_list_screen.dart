import 'package:flutter/material.dart';
import '../../core/widgets/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import 'members_repository.dart';
import '../../core/i18n/i18n.dart';

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
  String _query = '';
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
        setState(() { _message = tr(context).mem.inviteCreated; _isError = false; });
        _reload(_loadedForOrgId!);
      }
    } catch (e) {
      if (mounted) setState(() { _message = friendlyError(e, tr(context).mem.inviteError); _isError = true; });
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
        leading: DrawerLeading(),title: Text(tr(context).nav.items['/members']!)),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/members/new-teacher');
          if (mounted && orgId != null) setState(() => _reload(orgId));
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(tr(context).mem.newTeacher),
      ),
      body: orgId == null
          ? const SizedBox.shrink()
          : FutureBuilder<void>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final q = _query.trim().toLowerCase();
                final shown = q.isEmpty
                    ? _members
                    : _members.where((m) => '${m.fullName ?? ''} ${m.email ?? ''}'.toLowerCase().contains(q)).toList();
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() => _reload(orgId));
                    await _dataFuture;
                  },
                  child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  // bottom room so the add-teacher button never covers the last row
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    if (_message != null) MessageBanner(message: _message!, isError: _isError),
                    if (_members.length > 8)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_rounded),
                            hintText: tr(context).ui.search,
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                    ...shown.map((m) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: InitialAvatar(m.fullName ?? m.email ?? '?', radius: 18),
                            title: Text(m.fullName ?? m.email ?? '—'),
                            subtitle: Text(
                              '${kMemberRoleLabels[m.role] ?? m.role} · ${kMemberStatusLabels[m.status] ?? m.status}',
                            ),
                            trailing: TextButton(
                              onPressed: () async {
                                await context.push('/members/${m.id}');
                                if (mounted) setState(() => _reload(orgId));
                              },
                              child: Text(tr(context).common.edit),
                            ),
                          ),
                        )),
                    const Divider(height: 32),
                    Text(tr(context).mem.inviteTitle, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: tr(context).mem.email),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _inviteRole,
                      decoration: InputDecoration(labelText: tr(context).mem.role),
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
                          : Text(tr(context).mem.inviteBtn),
                    ),
                    if (_invitations.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(tr(context).mem.pendingInvites, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      ..._invitations.map((i) => Text('${i.email} — ${kMemberRoleLabels[i.role] ?? i.role}')),
                    ],
                  ],
                  ),
                );
              },
            ),
    );
  }
}
