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
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
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
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = friendlyError(e, 'حدث خطأ أثناء الحفظ'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  final _newPassword = TextEditingController();
  bool _resetting = false;

  @override
  void dispose() {
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final password = _newPassword.text.trim();
    if (password.length < 8) {
      setState(() => _error = 'كلمة السر 8 أحرف على الأقل');
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة السر')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حُفظت حالة الحساب')));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e is PostgrestException ? e.message : 'تعذّر الحفظ');
    } finally {
      if (mounted) setState(() => _savingViewer = false);
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف من المركز'),
        content: Text('متأكد إنك بدك تحذف "${_member?.fullName ?? _member?.email}" من المركز؟ رح يفقد كل صلاحياته هنا فورًا.'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => context.pop(true), child: const Text('حذف')),
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
      appBar: AppBar(title: const Text('تعديل عضو')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isSelf
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('لا يمكنك تعديل أو حذف صلاحياتك الخاصة من هنا - اطلب من مدير آخر إن وجد.'),
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
                      decoration: const InputDecoration(labelText: 'الدور'),
                      items: kMemberRoleLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setState(() => _role = v ?? _role),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'الحالة'),
                      items: kMemberStatusLabels.entries
                          .where((e) => e.key != 'invited')
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _status = v ?? _status),
                    ),
                    if (_role == 'teacher') ...[
                      const SizedBox(height: 16),
                      Text('الوحدات التي يمكنه الوصول لها', style: Theme.of(context).textTheme.titleSmall),
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
                          : const Text('حفظ التعديلات'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('حساب عرض فقط'),
                      subtitle: const Text('يرى ولا يعدّل: يبقى دوره كما هو لكن لا يُحفظ له أي تغيير في هذا المركز.'),
                      value: _viewer,
                      onChanged: _savingViewer ? null : _saveViewer,
                    ),
                    const SectionTitle('تغيير كلمة السر'),
                    TextField(
                      controller: _newPassword,
                      decoration: const InputDecoration(labelText: 'كلمة سر جديدة (8 أحرف على الأقل)'),
                    ),
                    const SizedBox(height: 10),
                    LoadingButton(label: 'تغيير كلمة السر', loading: _resetting, onPressed: _resetPassword),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _remove,
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('حذف من المركز'),
                    ),
                  ],
                ),
    );
  }
}
