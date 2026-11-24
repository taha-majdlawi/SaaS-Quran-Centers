import 'package:flutter/material.dart';
import '../../core/widgets/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/utils/national_id.dart';
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
  final _nameController = TextEditingController();
  final _nationalIdController = TextEditingController();
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
    _nameController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    // optional; when typed it must be a valid ID (accepting the invitation saves it - 0099)
    final rawId = _nationalIdController.text.trim();
    final nationalId = normalizeNationalId(rawId);
    if (rawId.isNotEmpty && nationalId == null) {
      setState(() { _message = tr(context).stu.nationalIdInvalid; _isError = true; });
      return;
    }
    setState(() {
      _inviting = true;
      _message = null;
    });
    try {
      final sent = await _repository.createInvitation(
        organizationId: _loadedForOrgId!,
        email: email,
        role: _inviteRole,
        fullName: _nameController.text.trim(),
        nationalId: nationalId,
      );
      _emailController.clear();
      _nameController.clear();
      _nationalIdController.clear();
      if (mounted) {
        setState(() { _message = sent ? fmt(tr(context).mem.inviteSent, {'email': email}) : tr(context).mem.inviteCreated; _isError = false; });
        _reload(_loadedForOrgId!);
      }
    } catch (e) {
      if (mounted) setState(() { _message = friendlyError(e, tr(context).mem.inviteError); _isError = true; });
    } finally {
      if (mounted) setState(() => _inviting = false);
    }
  }

  Future<void> _cancel(PendingInvitation inv) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(ctx).mem.cancelInvite),
        content: Text(fmt(tr(ctx).mem.cancelConfirm, {'email': inv.email})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr(ctx).common.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr(ctx).mem.cancelInvite, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _repository.cancelInvitation(_loadedForOrgId!, inv.id);
      if (mounted) setState(() => _reload(_loadedForOrgId!));
    } catch (e) {
      if (mounted) setState(() { _message = friendlyError(e, tr(context).mem.inviteError); _isError = true; });
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
                      controller: _nameController,
                      maxLength: 120,
                      decoration: InputDecoration(labelText: tr(context).mem.inviteName, counterText: ''),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(labelText: tr(context).mem.email),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nationalIdController,
                      textDirection: TextDirection.ltr,
                      maxLength: 24,
                      decoration: InputDecoration(labelText: tr(context).stu.nationalId, counterText: ''),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _inviteRole,
                      decoration: InputDecoration(labelText: tr(context).mem.role),
                      // no "student": a student needs a student record, made from the students page
                      items: kMemberRoleLabels.entries
                          .where((e) => e.key != 'student')
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _inviteRole = v ?? _inviteRole),
                    ),
                    const SizedBox(height: 8),
                    Text(tr(context).mem.inviteDetailsHint, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
                      ..._invitations.map((i) => Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              dense: true,
                              title: Text(i.fullName?.isNotEmpty == true ? i.fullName! : i.email),
                              subtitle: Text([
                                if (i.fullName?.isNotEmpty == true) i.email,
                                kMemberRoleLabels[i.role] ?? i.role,
                                if (i.nationalId != null) i.nationalId!,
                                if (i.expired) tr(context).mem.inviteExpired,
                              ].join(' · ')),
                              trailing: IconButton(
                                tooltip: tr(context).mem.cancelInvite,
                                icon: const Icon(Icons.close_rounded, color: Colors.red),
                                onPressed: () => _cancel(i),
                              ),
                            ),
                          )),
                    ],
                  ],
                  ),
                );
              },
            ),
    );
  }
}
