import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/access/module_keys.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../chat/chat_repository.dart';
import 'members_repository.dart';

/// Mirrors apps/web's members/[id] page: edit role/status/permissions,
/// with a self-edit/self-delete guard, or remove the member from the org.
/// Full account edits (email/password) live only on the web's Teachers
/// page - see members_repository.dart's comment on why that can't move
/// to mobile.
///
/// Also owns the chat contact picker (migration 0020's chat_contacts) -
/// there's no dedicated "chat permissions" screen, this is the one place an
/// admin edits any per-member setting, so it's the natural home for it too.
class MemberEditScreen extends StatefulWidget {
  const MemberEditScreen({super.key, required this.memberId});

  final String memberId;

  @override
  State<MemberEditScreen> createState() => _MemberEditScreenState();
}

class _MemberEditScreenState extends State<MemberEditScreen> {
  final _repository = MembersRepository(AppSupabase.client);
  final _chatRepository = ChatRepository(AppSupabase.client);
  MemberRow? _member;
  bool _isSelf = false;
  String _role = 'teacher';
  String _status = 'active';
  Set<String> _permissions = {};
  String? _orgId;
  List<ChatMemberOption> _otherMembers = [];
  Set<String> _contactUserIds = {};
  bool _loading = true;
  bool _submitting = false;
  bool _notFound = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orgId = context.read<TenantController>().active!.organization.id;
    _orgId = orgId;
    final myUserId = context.read<AuthController>().currentUser?.id;
    final results = await Future.wait<dynamic>([
      _repository.fetchMembers(orgId),
      _chatRepository.fetchMembers(orgId),
    ]);
    final members = results[0] as List<MemberRow>;
    final allChatMembers = results[1] as List<ChatMemberOption>;
    MemberRow? member;
    for (final m in members) {
      if (m.id == widget.memberId) {
        member = m;
        break;
      }
    }
    if (member == null) {
      // Not in this org's member list - e.g. a stale/foreign memberId in
      // the route. Show a clear message instead of hanging on the spinner
      // (RLS already guarantees `members` only ever contains this org's rows).
      if (mounted) setState(() { _notFound = true; _loading = false; });
      return;
    }
    _member = member;
    _isSelf = member.userId == myUserId;
    _role = member.role;
    _status = member.status;
    _permissions = member.permissions.toSet();
    _otherMembers = allChatMembers.where((m) => m.userId != member.userId).toList();
    _contactUserIds = await _chatRepository.fetchContactUserIds(orgId, member.userId);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await Future.wait([
        _repository.updateMember(
          id: widget.memberId,
          role: _role,
          status: _status,
          permissions: _permissions.toList(),
        ),
        _chatRepository.setContacts(organizationId: _orgId!, userId: _member!.userId, contactUserIds: _contactUserIds),
      ]);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = 'حدث خطأ أثناء الحفظ');
    } finally {
      if (mounted) setState(() => _submitting = false);
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
          : _notFound
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('تعذر العثور على هذا العضو.')),
                )
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
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: const InputDecoration(labelText: 'الدور', border: OutlineInputBorder()),
                      items: kMemberRoleLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setState(() => _role = v ?? _role),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder()),
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
                    // Admins bypass chat_contacts entirely (RLS lets them
                    // message anyone) - showing this picker for an admin
                    // member would just be a confusing no-op.
                    if (_role != 'admin') ...[
                      const SizedBox(height: 16),
                      Text('يقدر يحكي مع (محادثات)', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'قائمة يدوية - هاي هي الوحيدة اللي تتحكم مين يقدر يبدأ محادثة مع مين.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: _otherMembers.map((m) {
                          return FilterChip(
                            label: Text(m.label),
                            selected: _contactUserIds.contains(m.userId),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                _contactUserIds.add(m.userId);
                              } else {
                                _contactUserIds.remove(m.userId);
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
