import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import 'gatherings_repository.dart';

/// Shared activities: upload the attendees' names, the admin links each name to a student.
class GatheringsScreen extends StatefulWidget {
  const GatheringsScreen({super.key});

  @override
  State<GatheringsScreen> createState() => _GatheringsScreenState();
}

class _GatheringsScreenState extends State<GatheringsScreen> {
  final _repository = GatheringsRepository(AppSupabase.client);
  Future<List<Map<String, dynamic>>>? _future;
  String? _orgId;
  bool _admin = false;

  void _reload() => setState(() => _future = _repository.gatherings(_orgId!, admin: _admin));

  Future<void> _create() async {
    final types = await _repository.activityTypes(_orgId!);
    if (!mounted) return;
    final title = TextEditingController();
    final location = TextEditingController();
    final notes = TextEditingController();
    final names = TextEditingController();
    var date = DateTime.now();
    String? typeId;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('رفع نشاط جديد', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'اسم النشاط')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                initialValue: typeId,
                decoration: const InputDecoration(labelText: 'نوع النشاط'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('— بدون —')),
                  for (final t in types) DropdownMenuItem<String?>(value: t['id'] as String, child: Text('${t['name']}')),
                ],
                onChanged: (v) => setLocal(() => typeId = v),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.event_rounded),
                label: Text('${date.year}/${date.month}/${date.day}'),
                onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now());
                  if (d != null) setLocal(() => date = d);
                },
              ),
              const SizedBox(height: 10),
              TextField(controller: location, decoration: const InputDecoration(labelText: 'المكان (اختياري)')),
              const SizedBox(height: 10),
              TextField(controller: names, minLines: 5, maxLines: 10, decoration: const InputDecoration(labelText: 'الحاضرون — اسم في كل سطر', alignLabelWithHint: true)),
              const SizedBox(height: 10),
              TextField(controller: notes, decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)')),
              const SizedBox(height: 14),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('رفع النشاط')),
            ]),
          ),
        ),
      ),
    );
    if (ok != true) return;
    final list = names.text.split(RegExp(r'[\n،,]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    try {
      final n = await _repository.submitGathering(_orgId!,
          title: title.text.trim(), typeId: typeId, date: date, location: location.text.trim().isEmpty ? null : location.text.trim(), notes: notes.text.trim().isEmpty ? null : notes.text.trim(), names: list);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('رُفع النشاط بـ $n اسم')));
        _reload();
      }
    } on PostgrestException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر الرفع — تحقّق من الاتصال')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final orgId = tenant.active?.organization.id;
    if (orgId != null && orgId != _orgId) {
      _orgId = orgId;
      _admin = tenant.active?.role == OrgRole.admin;
      _future = _repository.gatherings(orgId, admin: _admin);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('المجالس والأنشطة')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add_rounded), label: const Text('رفع نشاط')),
      body: _future == null
          ? const SizedBox.shrink()
          : AsyncBody<List<Map<String, dynamic>>>(
              future: _future!,
              onRetry: _reload,
              builder: (context, list) => RefreshIndicator(
                onRefresh: () async => _reload(),
                child: list.isEmpty
                    ? ListView(children: const [SizedBox(height: 80), EmptyState(icon: Icons.groups_2_rounded, title: 'لا أنشطة مرفوعة بعد')])
                    : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), children: [
                        for (final g in list)
                          Card(
                            child: ListTile(
                              title: Text('${g['title']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                '${g['session_date']}${g['activity_type_label'] != null ? ' · ${g['activity_type_label']}' : ''}${g['teacher_name'] != null ? ' · ${g['teacher_name']}' : ''}\n'
                                '${g['total']} اسم · رُبط ${g['matched']}${(g['skipped'] as num) > 0 ? ' · تُجوهل ${g['skipped']}' : ''}',
                              ),
                              isThreeLine: true,
                              trailing: Chip(
                                visualDensity: VisualDensity.compact,
                                side: BorderSide.none,
                                backgroundColor: (g['status'] == 'reviewed' ? Colors.green : Colors.amber).withValues(alpha: 0.18),
                                label: Text(g['status'] == 'reviewed' ? 'تمت المراجعة' : (g['pending'] != null ? 'بانتظار (${g['pending']})' : 'بانتظار المشرف'), style: const TextStyle(fontSize: 11)),
                              ),
                              onTap: () async {
                                await context.push('/gatherings/${g['id']}');
                                if (mounted) _reload();
                              },
                            ),
                          ),
                      ]),
              ),
            ),
    );
  }
}
