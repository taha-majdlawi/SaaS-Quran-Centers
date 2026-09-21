import 'package:flutter/material.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import 'insights_repository.dart';

/// Append-only notes on a student, for the supervisor and the student's teacher (never shown to the student).
class StudentNotesSection extends StatefulWidget {
  const StudentNotesSection({super.key, required this.orgId, required this.studentId});

  final String orgId;
  final String studentId;

  @override
  State<StudentNotesSection> createState() => _StudentNotesSectionState();
}

class _StudentNotesSectionState extends State<StudentNotesSection> {
  final _repository = InsightsRepository(AppSupabase.client);
  late Future<List<StudentNote>> _future = _repository.notes(widget.orgId, widget.studentId);

  Future<void> _add() async {
    final body = TextEditingController();
    var guardianVisible = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('ملاحظة جديدة'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: body, maxLines: 4, maxLength: 1000, decoration: const InputDecoration(hintText: 'مثال: يستعجل في أواخر الآيات')),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: guardianVisible,
              onChanged: (v) => setLocal(() => guardianVisible = v ?? false),
              title: const Text('ظاهرة لولي الأمر', style: TextStyle(fontSize: 13)),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (ok != true || body.text.trim().isEmpty) return;
    try {
      await _repository.addNote(widget.orgId, widget.studentId, body.text.trim(), guardianVisible: guardianVisible);
      if (mounted) setState(() => _future = _repository.notes(widget.orgId, widget.studentId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر حفظ الملاحظة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: SectionTitle('ملاحظات المعلم')),
        TextButton.icon(onPressed: _add, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('إضافة')),
      ]),
      FutureBuilder<List<StudentNote>>(
        future: _future,
        builder: (context, snap) {
          final notes = snap.data;
          if (notes == null) return const SizedBox.shrink();
          if (notes.isEmpty) return Text('لا ملاحظات بعد', style: TextStyle(color: scheme.outline, fontSize: 13));
          return Column(children: [
            for (final n in notes)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.body, style: const TextStyle(fontSize: 13.5, height: 1.4)),
                  const SizedBox(height: 4),
                  Text('${n.author ?? '—'} · ${formatDate(n.createdAt)}${n.visibility == 'guardian_visible' ? ' · ظاهرة لولي الأمر' : ''}',
                      style: TextStyle(fontSize: 11.5, color: scheme.outline)),
                ]),
              ),
          ]);
        },
      ),
    ]);
  }
}
