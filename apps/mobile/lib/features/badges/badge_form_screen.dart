import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import '../engagement/engagement_models.dart';
import '../engagement/engagement_repository.dart';

const _palette = ['#f59e0b', '#ef4444', '#22c55e', '#3b82f6', '#a855f7', '#ec4899', '#14b8a6', '#64748b'];

class _FormData {
  const _FormData({required this.grades, required this.students, required this.circles, required this.holders, this.badge});
  final Map<String, String> grades;
  final List<({String id, String name})> students;
  final List<({String id, String name})> circles;
  final List<BadgeHolder> holders;
  final BadgeDef? badge;
}

/// Create / edit a badge (admin); award it to a student or a whole circle and
/// see who holds it. A teacher (badges module) gets only the award section.
class BadgeFormScreen extends StatefulWidget {
  const BadgeFormScreen({super.key, this.badgeId});

  final String? badgeId;

  @override
  State<BadgeFormScreen> createState() => _BadgeFormScreenState();
}

class _BadgeFormScreenState extends State<BadgeFormScreen> {
  final _repository = EngagementRepository(AppSupabase.client);
  late Future<_FormData> _future = _load();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _icon = TextEditingController(text: '🏅');
  final _threshold = TextEditingController(text: '0');
  final _duration = TextEditingController();
  String _color = '#f59e0b';
  String _rule = 'manual';
  String? _param;
  bool _active = true;
  bool _saving = false;
  String? _message;
  bool _isError = false;
  bool _filled = false;

  String get _orgId => context.read<TenantController>().active!.organization.id;
  bool get _isAdmin => context.read<TenantController>().active?.role == OrgRole.admin;

  Future<_FormData> _load() async {
    final orgId = _orgId;
    final results = await Future.wait<dynamic>([
      _repository.gradeLabels(orgId),
      _repository.students(orgId).catchError((_) => <({String id, String name})>[]),
      _isAdmin ? _repository.circles(orgId) : Future.value(<({String id, String name})>[]),
      if (widget.badgeId != null) _repository.badgeDefs(orgId),
      if (widget.badgeId != null && _isAdmin) _repository.badgeHolders(orgId, widget.badgeId!),
    ]);
    final badge = widget.badgeId == null ? null : (results[3] as List<BadgeDef>).where((b) => b.id == widget.badgeId).firstOrNull;
    if (badge != null && !_filled) {
      _filled = true;
      _name.text = badge.name;
      _description.text = badge.description ?? '';
      _icon.text = badge.icon;
      _threshold.text = '${badge.threshold}';
      _duration.text = badge.durationDays?.toString() ?? '';
      _color = badge.colorHex;
      _rule = badge.ruleType;
      _param = badge.param;
      _active = badge.isActive;
    }
    return _FormData(
      grades: results[0] as Map<String, String>,
      students: results[1] as List<({String id, String name})>,
      circles: results[2] as List<({String id, String name})>,
      holders: widget.badgeId != null && _isAdmin ? results[4] as List<BadgeHolder> : const [],
      badge: badge,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _icon.dispose();
    _threshold.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _say(String text, {bool error = false}) => setState(() {
        _message = text;
        _isError = error;
      });

  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      if (mounted) {
        _say(done);
        setState(() => _future = _load());
      }
    } on PostgrestException catch (e) {
      if (mounted) _say(e.message, error: true);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _say('اسم الشارة مطلوب', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await _repository.saveBadge(
        _orgId,
        id: widget.badgeId,
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        icon: _icon.text.trim().isEmpty ? '🏅' : _icon.text.trim(),
        color: _color,
        ruleType: _rule,
        threshold: int.tryParse(_threshold.text.trim()) ?? 0,
        param: _rule == 'grade_count' ? _param : null,
        durationDays: int.tryParse(_duration.text.trim()),
        isActive: _active,
        sortOrder: 0,
      );
      if (mounted) context.pop();
    } on PostgrestException catch (e) {
      _say(e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickStudent(_FormData data) async {
    final picked = await showModalBottomSheet<({String id, String name})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _NamePicker(items: data.students, title: 'اختر الطالب'),
    );
    if (picked != null) await _run(() => _repository.awardBadge(widget.badgeId!, picked.id), 'مُنحت الشارة');
  }

  Future<void> _pickCircle(_FormData data) async {
    final picked = await showModalBottomSheet<({String id, String name})>(
      context: context,
      showDragHandle: true,
      builder: (context) => _NamePicker(items: data.circles, title: 'اختر الحلقة'),
    );
    if (picked != null) {
      try {
        final n = await _repository.awardToCircle(widget.badgeId!, picked.id);
        if (mounted) {
          _say('مُنحت لـ $n طالب');
          setState(() => _future = _load());
        }
      } on PostgrestException catch (e) {
        if (mounted) _say(e.message, error: true);
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الشارة'),
        content: const Text('تُحذف من كل الطلاب. متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repository.deleteBadge(_orgId, widget.badgeId!);
      if (mounted) context.pop();
    } on PostgrestException catch (e) {
      if (mounted) _say(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = _isAdmin;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.badgeId == null ? 'شارة جديدة' : 'الشارة'),
        actions: [if (admin && widget.badgeId != null) IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete)],
      ),
      body: AsyncBody<_FormData>(
        future: _future,
        builder: (context, data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_message != null) MessageBanner(message: _message!, isError: _isError),
            if (admin) ...[
              Row(children: [
                SizedBox(width: 72, child: TextField(controller: _icon, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26), maxLength: 4, decoration: const InputDecoration(counterText: '', labelText: 'رمز'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _name, decoration: const InputDecoration(labelText: 'الاسم'))),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                for (final c in _palette)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: hexColor(c), shape: BoxShape.circle, border: Border.all(width: 3, color: _color == c ? Colors.black87 : Colors.transparent)),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),
              TextField(controller: _description, maxLines: 2, decoration: const InputDecoration(labelText: 'الوصف')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _rule,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'القاعدة'),
                items: [for (final e in kRuleLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setState(() => _rule = v ?? 'manual'),
              ),
              if (_rule != 'manual') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _threshold,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'قيمة الشرط',
                    helperText: _rule == 'juz_complete' ? 'رقم الجزء (1–30)' : (_rule == 'weekly_attendance' ? 'نسبة % (1–100)' : 'العدد المطلوب'),
                  ),
                ),
              ],
              if (_rule == 'grade_count') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _param,
                  decoration: const InputDecoration(labelText: 'التقدير'),
                  items: [for (final g in data.grades.entries) DropdownMenuItem(value: g.key, child: Text(g.value))],
                  onChanged: (v) => setState(() => _param = v),
                ),
              ],
              const SizedBox(height: 12),
              TextField(controller: _duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'مدة الشارة بالأيام (فارغ = دائمة)')),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('فعّالة'), value: _active, onChanged: (v) => setState(() => _active = v)),
              const SizedBox(height: 8),
              LoadingButton(label: 'حفظ', loading: _saving, onPressed: _save),
            ],
            if (widget.badgeId != null) ...[
              const SectionTitle('منح الشارة يدويًا'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                FilledButton.tonalIcon(onPressed: () => _pickStudent(data), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('لطالب')),
                if (admin) OutlinedButton.icon(onPressed: () => _pickCircle(data), icon: const Icon(Icons.groups_rounded), label: const Text('لحلقة كاملة')),
              ]),
              if (admin) ...[
                SectionTitle('حاملو الشارة (${data.holders.length})'),
                if (data.holders.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('لم تُمنح لأحد بعد')),
                for (final h in data.holders)
                  Card(
                    child: ListTile(
                      leading: InitialAvatar(h.name, radius: 18),
                      title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${formatDate(h.awardedAt)}  ·  ${h.manual ? 'يدوي' : 'تلقائي'}${h.expiresAt == null ? '' : '  ·  تنتهي ${formatDate(h.expiresAt)}'}'),
                      trailing: TextButton(
                        onPressed: () => _run(() => _repository.awardBadge(widget.badgeId!, h.studentId, revoke: true), 'سُحبت الشارة'),
                        child: const Text('سحب', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _NamePicker extends StatefulWidget {
  const _NamePicker({required this.items, required this.title});
  final List<({String id, String name})> items;
  final String title;

  @override
  State<_NamePicker> createState() => _NamePickerState();
}

class _NamePickerState extends State<_NamePicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final items = widget.items.where((i) => _q.isEmpty || i.name.contains(_q)).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(autofocus: true, onChanged: (v) => setState(() => _q = v.trim()), decoration: InputDecoration(hintText: widget.title, prefixIcon: const Icon(Icons.search_rounded))),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) => ListTile(leading: InitialAvatar(items[i].name), title: Text(items[i].name), onTap: () => Navigator.pop(context, items[i])),
            ),
          ),
        ]),
      ),
    );
  }
}
