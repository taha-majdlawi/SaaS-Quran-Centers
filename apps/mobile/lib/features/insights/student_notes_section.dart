import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import 'insights_repository.dart';
import '../../core/i18n/i18n.dart';
import '../../core/offline/sync_service.dart' show kQueuedMessage;

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
          title: Text(tr(context).ins.newNote),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: body, maxLines: 4, maxLength: 1000, decoration: InputDecoration(hintText: tr(context).ins.notePh)),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: guardianVisible,
              onChanged: (v) => setLocal(() => guardianVisible = v ?? false),
              title: Text(tr(context).ins.guardianVisible, style: TextStyle(fontSize: 13)),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).common.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(context).common.save)),
          ],
        ),
      ),
    );
    if (ok != true || body.text.trim().isEmpty) return;
    try {
      final queued = await _repository.addNote(widget.orgId, widget.studentId, body.text.trim(), guardianVisible: guardianVisible);
      if (mounted) {
        if (queued) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(kQueuedMessage)));
        setState(() => _future = _repository.notes(widget.orgId, widget.studentId));
      }
    } on PostgrestException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } on StateError catch (e) {
      // a viewing account / a center locked for non-payment: say which, not just "failed"
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context).ins.noteFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: SectionTitle(tr(context).ins.notesTitle)),
        TextButton.icon(onPressed: _add, icon: Icon(Icons.add_rounded, size: 18), label: Text(tr(context).ui.add)),
      ]),
      FutureBuilder<List<StudentNote>>(
        future: _future,
        builder: (context, snap) {
          final notes = snap.data;
          if (notes == null) return const SizedBox.shrink();
          if (notes.isEmpty) return Text(tr(context).ins.noNotes, style: TextStyle(color: scheme.outline, fontSize: 13));
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
                  Text('${n.author ?? '—'} · ${formatDate(n.createdAt)}${n.visibility == 'guardian_visible' ? tr(context).ins.guardianVisibleSuffix : ''}',
                      style: TextStyle(fontSize: 11.5, color: scheme.outline)),
                ]),
              ),
          ]);
        },
      ),
    ]);
  }
}
