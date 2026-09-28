import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import 'gatherings_repository.dart';
import 'student_picker.dart';
import '../../core/i18n/i18n.dart';

class _Data {
  const _Data(this.detail, this.suggestions);
  final Map<String, dynamic> detail;
  final Map<String, List<Map<String, dynamic>>> suggestions;
}

/// One gathering: the names, and (for the admin) linking each name to a student.
class GatheringDetailScreen extends StatefulWidget {
  const GatheringDetailScreen({super.key, required this.gatheringId});
  final String gatheringId;

  @override
  State<GatheringDetailScreen> createState() => _GatheringDetailScreenState();
}

class _GatheringDetailScreenState extends State<GatheringDetailScreen> {
  final _repository = GatheringsRepository(AppSupabase.client);
  late Future<_Data> _future = _load();

  String get _orgId => context.read<TenantController>().active!.organization.id;

  Future<_Data> _load() async {
    final d = await _repository.gatheringDetail(widget.gatheringId);
    final sug = d['is_admin'] == true ? await _repository.suggestions(widget.gatheringId) : <String, List<Map<String, dynamic>>>{};
    return _Data(d, sug);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _do(Future<dynamic> Function() action, {String? ok}) async {
    try {
      final r = await action();
      if (!mounted) return;
      final msg = ok ?? (r is String && r.isNotEmpty ? r : null);
      if (msg != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      _reload();
    } on PostgrestException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context).gather.actionFailed)));
    }
  }

  Future<void> _match(String entryId, String rawName) async {
    final student = await pickStudent(context, _orgId, initialQuery: rawName);
    if (student == null) return;
    await _do(() async {
      final r = await _repository.matchEntry(entryId, student);
      return r['center_attendance'] == true ? currentStrings.gather.linkedAttended : '${r['note'] ?? currentStrings.gather.okLinked}';
    });
  }

  Future<void> _addName() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).gather.addName),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: tr(context).gather.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).common.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(context).gather.add)),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) await _do(() => _repository.addEntry(widget.gatheringId, c.text.trim()), ok: currentStrings.gather.nameAdded);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr(context).gather.activity)),
      body: AsyncBody<_Data>(
        future: _future,
        onRetry: _reload,
        builder: (context, data) {
          final d = data.detail;
          final admin = d['is_admin'] == true;
          final entries = [for (final e in (d['entries'] as List)) Map<String, dynamic>.from(e as Map)];
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Text('${d['title']}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(fmt(tr(context).gather.metaLine, {'session_date': d['session_date'], 'v': d['activity_type_label'] != null ? ' · ${d['activity_type_label']}' : '', 'v2': d['location'] != null ? ' · ${d['location']}' : '', 'v3': d['teacher_name'] ?? '—'}),
                  style: TextStyle(color: scheme.outline, fontSize: 12.5)),
              if (d['notes'] != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${d['notes']}')),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Text(fmt(tr(context).gather.namesN, {'n': entries.length}), style: const TextStyle(fontWeight: FontWeight.w800))),
                TextButton.icon(onPressed: _addName, icon: Icon(Icons.add_rounded, size: 18), label: Text(tr(context).gather.addName)),
              ]),
              for (final e in entries)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text('${e['raw_name']}', style: const TextStyle(fontWeight: FontWeight.w700))),
                        if (admin || e['status'] == 'pending')
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            onPressed: () => _do(() => _repository.deleteEntry(e['id'] as String), ok: tr(context).gather.nameDeleted),
                          ),
                      ]),
                      if (e['status'] == 'matched')
                        Text(fmt(tr(context).gather.linkedLine, {'matched_name': e['matched_name'], 'matched_code': e['matched_code'], 'v': e['matched_circle'] != null ? ' · ${e['matched_circle']}' : ''}), style: const TextStyle(color: Colors.green, fontSize: 12.5))
                      else if (e['status'] == 'skipped')
                        Text(tr(context).gather.skipped, style: TextStyle(color: scheme.outline, fontSize: 12.5))
                      else
                        Text(tr(context).gather.pending, style: TextStyle(color: Colors.amber.shade800, fontSize: 12.5)),
                      if (admin && e['status'] == 'pending') ...[
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 4, children: [
                          for (final s in data.suggestions[e['id']] ?? const <Map<String, dynamic>>[])
                            ActionChip(
                              label: Text('${s['full_name']}${s['circle'] != null ? ' · ${s['circle']}' : ''} (${((s['score'] as num) * 100).round()}%)', style: const TextStyle(fontSize: 11.5)),
                              onPressed: () => _do(() async {
                                final r = await _repository.matchEntry(e['id'] as String, s['student_id'] as String);
                                return r['center_attendance'] == true ? currentStrings.gather.linkedAttended : '${r['note'] ?? currentStrings.gather.okLinked}';
                              }),
                            ),
                          ActionChip(avatar: Icon(Icons.search_rounded, size: 16), label: Text(tr(context).gather.pickStudent), onPressed: () => _match(e['id'] as String, e['raw_name'] as String)),
                          ActionChip(label: Text(tr(context).gather.skip), onPressed: () => _do(() => _repository.skipEntry(e['id'] as String), ok: tr(context).gather.nameSkipped)),
                        ]),
                      ],
                      if (admin && e['status'] != 'pending')
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(onPressed: () => _do(() => _repository.unmatchEntry(e['id'] as String)), child: Text(tr(context).gather.unlink)),
                        ),
                    ]),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
}
