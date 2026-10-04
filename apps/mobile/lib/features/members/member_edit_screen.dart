import 'package:flutter/material.dart';
import '../../core/widgets/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/api/accounts_api.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/access/module_keys.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'members_repository.dart';
import '../../core/i18n/i18n.dart';

/// Mirrors apps/web's members/[id] page: edit role/status/permissions,
/// with a self-edit/self-delete guard, or remove the member from the org.
/// Full account edits (email/password) live only on the web's Teachers
/// page - see members_repository.dart's comment on why that can't move
/// to mobile.
class MemberEditScreen extends StatefulWidget {
  const MemberEditScreen({super.key, required this.memberId});

  final String memberId;

  @override
  State<MemberEditScreen> createState() => _MemberEditScreenState();
}

class _MemberEditScreenState extends State<MemberEditScreen> {
  final _repository = MembersRepository(AppSupabase.client);
  MemberRow? _member;
  bool _isSelf = false;
  bool _viewer = false;
  bool _savingViewer = false;
  String _role = 'teacher';
  String _status = 'active';
  Set<String> _permissions = {};
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
    final myUserId = context.read<AuthController>().currentUser?.id;
    final members = await _repository.fetchMembers(orgId);
    final member = members.firstWhere((m) => m.id == widget.memberId);
    _member = member;
    _isSelf = member.userId == myUserId;
    _role = member.role;
    _status = member.status;
    _permissions = member.permissions.toSet();
    try {
      _viewer = await _repository.isViewer(orgId, member.userId);
    } catch (_) {}
    try {
      final c = await _repository.contact(orgId, member.id);
      _phone.text = c.phone ?? '';
      _whatsapp.text = c.whatsapp ?? '';
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    final orgId = context.read<TenantController>().active!.organization.id;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repository.updateMember(
        id: widget.memberId,
        role: _role,
        status: _status,
        permissions: _permissions.toList(),
      );
      if (_role == 'teacher' || _role == 'admin') {
        await _repository.setContact(orgId, widget.memberId, _phone.text.trim(), _whatsapp.text.trim());
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = friendlyError(e, tr(context).stu.saveError));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  final _newPassword = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  bool _resetting = false;

  @override
  void dispose() {
    _newPassword.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final password = _newPassword.text.trim();
    if (password.length < 8) {
      setState(() => _error = tr(context).mem.password8);
      return;
    }
    setState(() {
      _resetting = true;
      _error = null;
    });
    try {
      final org = context.read<TenantController>().active!.organization;
      await AccountsApi().resetPassword(orgId: org.id, memberId: widget.memberId, password: password);
      _newPassword.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context).mem.passwordChanged)));
      }
    } on AccountsApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  Future<void> _saveViewer(bool value) async {
    setState(() {
      _savingViewer = true;
      _error = null;
    });
    try {
      final orgId = context.read<TenantController>().active!.organization.id;
      await _repository.setViewer(orgId, _member!.userId, value);
      if (mounted) {
        setState(() => _viewer = value);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context).mem.accountSaved)));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is PostgrestException ? e.message : tr(context).set.saveFailed);
    } finally {
      if (mounted) setState(() => _savingViewer = false);
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).mem.removeTitle),
        content: Text(fmt(tr(context).mem.removeBody, {'fullName': _member?.fullName ?? _member?.email})),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: Text(tr(context).common.cancel)),
          TextButton(onPressed: () => context.pop(true), child: Text(tr(context).common.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.removeMember(widget.memberId);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context).mem.editTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isSelf
              ? Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(tr(context).mem.selfNote),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(_member?.fullName ?? _member?.email ?? '', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    if (_error != null) MessageBanner(message: _error!),
                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: InputDecoration(labelText: tr(context).mem.role),
                      items: kMemberRoleLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setState(() => _role = v ?? _role),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: InputDecoration(labelText: tr(context).mem.statusLabel),
                      items: kMemberStatusLabels.entries
                          .where((e) => e.key != 'invited')
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _status = v ?? _status),
                    ),
                    if (_role == 'teacher' || _role == 'admin') ...[
                      const SizedBox(height: 16),
                      Text(tr(context).mem.contactTitle, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(labelText: tr(context).stu.phoneOpt),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _whatsapp,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(labelText: tr(context).stu.whatsapp, helperText: tr(context).mem.contactHint),
                      ),
                    ],
                    if (_role == 'teacher') ...[
                      const SizedBox(height: 16),
                      Text(tr(context).mem.modulesTitle, style: Theme.of(context).textTheme.titleSmall),
                      Wrap(
                        spacing: 4,
                        children: kModuleKeys.map((key) {
                          return FilterChip(
                            label: Text(kModuleLabels[key] ?? key),
                            selected: _permissions.contains(key),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                _permissions.add(key);
                              } else {
                                _permissions.remove(key);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(tr(context).stu.saveChanges),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr(context).mem.viewOnly),
                      subtitle: Text(tr(context).mem.viewOnlyHint),
                      value: _viewer,
                      onChanged: _savingViewer ? null : _saveViewer,
                    ),
                    SectionTitle(tr(context).mem.changePassword),
                    TextField(
                      controller: _newPassword,
                      decoration: InputDecoration(labelText: tr(context).mem.newPassword),
                    ),
                    const SizedBox(height: 10),
                    LoadingButton(label: tr(context).mem.changePassword, loading: _resetting, onPressed: _resetPassword),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _remove,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(tr(context).mem.removeTitle),
                    ),
                  ],
                ),
    );
  }
}
