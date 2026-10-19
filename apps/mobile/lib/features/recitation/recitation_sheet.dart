import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/quran_data.dart';
import '../../core/offline/sync_service.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/widgets/ui.dart';
import 'next_position.dart';
import 'recitation_repository.dart';
import '../../core/i18n/i18n.dart';

/// Opens the "log a recitation" sheet. Resolves to the total points awarded
/// (or null if the teacher cancelled).
Future<int?> showRecitationSheet(
  BuildContext context, {
  required String studentId,
  required String studentName,
  required List<GradeOption> grades,
  RecitationEntry? editing,
  /// Pre-fills the type and surah - e.g. opened from a "due for review" chip. Ignored while [editing].
  String? initialType,
  int? initialSurah,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => RecitationSheet(
      studentId: studentId,
      studentName: studentName,
      grades: grades,
      editing: editing,
      initialType: initialType,
      initialSurah: initialSurah,
    ),
  );
}

class _PartInput {
  int? surah;
  final from = TextEditingController(text: '1');
  final to = TextEditingController();

  void dispose() {
    from.dispose();
    to.dispose();
  }
}

/// The "record a recitation" sheet (use [showRecitationSheet]).
class RecitationSheet extends StatefulWidget {
  const RecitationSheet({super.key, required this.studentId, required this.studentName, required this.grades, this.editing, this.initialType, this.initialSurah});

  final String studentId;
  final String studentName;
  final List<GradeOption> grades;

  /// Set when correcting an existing recitation instead of logging a new one.
  final RecitationEntry? editing;
  final String? initialType;
  final int? initialSurah;

  @override
  State<RecitationSheet> createState() => _RecitationSheetState();
}

class _RecitationSheetState extends State<RecitationSheet> {
  late final _repository = RecitationRepository(AppSupabase.client);
  bool _showNotes = false;
  final _notes = TextEditingController();
  final List<_PartInput> _parts = [_PartInput()];
  String _type = 'new_memorization';
  String? _grade;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  /// Where the student stopped last time (new memorization), and the prefill it gave.
  NextPosition? _position;
  bool _autoFilled = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _type = e.type;
      _grade = e.grade;
      _notes.text = e.notes ?? '';
      _parts.first
        ..surah = e.surah
        ..from.text = '${e.ayahFrom}'
        ..to.text = '${e.ayahTo}';
    } else if (widget.initialSurah != null) {
      if (widget.initialType != null) _type = widget.initialType!;
      final s = widget.initialSurah!;
      _parts.first
        ..surah = s
        ..from.text = '1'
        ..to.text = '${ayahCount(s)}';
    } else {
      _loadPosition();
    }
  }

  /// A new recitation: carry on from where the student stopped (next_position.dart).
  Future<void> _loadPosition() async {
    try {
      final history = await _repository.fetchMemorizationHistory(widget.studentId);
      final position = nextPosition(history);
      if (!mounted || position == null) return;
      setState(() {
        _position = position;
        // only into an untouched form, and only for new memorization
        final first = _parts.first;
        if (_parts.length == 1 && first.surah == null && _type == 'new_memorization' && position.surah != null) {
          first
            ..surah = position.surah
            ..from.text = '${position.ayahFrom}'
            ..to.text = '${ayahCount(position.surah!)}';
          _autoFilled = true;
        }
      });
    } catch (_) {
      // no history yet / offline without a cache: the form simply starts empty
    }
  }

  /// "Finished Surah X ✓ - next: Surah Y" or "Reached Surah X, ayah N".
  Widget _positionBanner(BuildContext context, NextPosition pos) {
    final t = tr(context);
    final done = pos.finishedSurah;
    final color = done ? Colors.green : Colors.blue;
    final title = done ? fmt(t.rec.finishedSurah, {'surah': surahName(pos.lastSurah)}) : fmt(t.rec.reachedAyah, {'surah': surahName(pos.lastSurah), 'ayah': pos.lastAyah});
    final next = !done ? null : pos.surah == null ? t.rec.wholeQuranDone : fmt(t.rec.nextSurahIs, {'surah': surahName(pos.surah!)});
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.shade100)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(done ? Icons.check_circle_rounded : Icons.bookmark_rounded, size: 20, color: color.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: color.shade900)),
            if (next != null) ...[
              const SizedBox(height: 2),
              Text(next, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color.shade800)),
            ],
            if (_autoFilled) ...[
              const SizedBox(height: 4),
              Text(t.rec.carryOn, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700)),
            ],
          ]),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _notes.dispose();
    for (final p in _parts) {
      p.dispose();
    }
    super.dispose();
  }

  Future<int?> _pickSurah() {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const _SurahPicker(),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String? _validate() {
    if (_grade == null) return tr(context).rec.pickGrade;
    for (final p in _parts) {
      if (p.surah == null) return tr(context).rec.pickSurah;
      final from = int.tryParse(p.from.text.trim());
      final to = int.tryParse(p.to.text.trim());
      if (from == null || to == null || from < 1) return tr(context).rec.enterRange;
      if (to < from) return tr(context).rec.rangeOrder;
      if (to > ayahCount(p.surah!)) return fmt(tr(context).rec.tooFar, {'v': surahName(p.surah!), 'v2': ayahCount(p.surah!)});
    }
    return null;
  }

  Future<void> _save() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final orgId = context.read<TenantController>().active!.organization.id;
    final editing = widget.editing;
    if (editing != null) {
      try {
        final p = _parts.first;
        final queued = await _repository.updateRecitation(
          id: editing.id,
          type: _type,
          part: SurahPart(surah: p.surah!, ayahFrom: int.parse(p.from.text.trim()), ayahTo: int.parse(p.to.text.trim())),
          grade: _grade!,
          notes: _notes.text,
        );
        if (mounted) Navigator.pop(context, queued ? kQueuedPoints : 0);
      } on PostgrestException catch (e) {
        setState(() => _error = e.message);
      } on StateError catch (e) {
        setState(() => _error = e.message);
      } catch (_) {
        setState(() => _error = tr(context).serd.saveFailedNet);
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }
    final group = _parts.length > 1 ? _repository.newSessionGroupId() : null;
    var total = 0;
    var saved = 0;
    var queued = 0;
    try {
      // Keep the real hour if the date is today; a back-dated one uses midday.
      final now = DateTime.now();
      final recorded = (_date.year == now.year && _date.month == now.month && _date.day == now.day)
          ? now
          : DateTime(_date.year, _date.month, _date.day, 12);
      for (final p in List<_PartInput>.of(_parts)) {
        final result = await _repository.logRecitation(
          orgId: orgId,
          studentId: widget.studentId,
          studentName: widget.studentName,
          type: _type,
          part: SurahPart(surah: p.surah!, ayahFrom: int.parse(p.from.text.trim()), ayahTo: int.parse(p.to.text.trim())),
          grade: _grade!,
          notes: _notes.text,
          recordedAt: recorded,
          sessionGroupId: group,
        );
        total += result.pointsAwarded;
        if (result.queued) queued++;
        saved++;
        _parts.remove(p);
      }
      if (mounted) {
        if (queued > 0) {
          Navigator.pop(context, kQueuedPoints);
        } else {
          Navigator.pop(context, total);
        }
      }
    } on PostgrestException catch (e) {
      setState(() => _error = saved > 0 ? fmt(tr(context).rec.partial, {'saved': saved, 'message': e.message}) : e.message);
    } on StateError catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = tr(context).serd.saveFailedNet);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final brand = Theme.of(context).colorScheme.primary;
    final today = DateTime.now();
    final isToday = _date.year == today.year && _date.month == today.month && _date.day == today.day;
    final picked = widget.grades.where((g) => g.key == _grade).firstOrNull;
    final points = picked == null ? null : picked.points * _parts.length;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // who, and when
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
            child: Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: brand.withValues(alpha: 0.12),
                child: Text(initialsOf(widget.studentName), style: TextStyle(color: brand, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.studentName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  Text(widget.editing == null ? t.rec.newTitle : t.rec.editTitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                ]),
              ),
              if (widget.editing == null)
                ActionChip(
                  avatar: Icon(Icons.event_rounded, size: 16, color: isToday ? brand : Colors.orange.shade800),
                  label: Text(isToday ? t.rec.today : fmt(t.rec.dayMonth, {'day': _date.day, 'month': _date.month})),
                  labelStyle: TextStyle(color: isToday ? TeacherStyle.textPrimary : Colors.orange.shade900, fontWeight: FontWeight.w700),
                  backgroundColor: isToday ? TeacherStyle.surfaceAlt : Colors.orange.shade50,
                  onPressed: _pickDate,
                ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            ]),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (widget.editing == null && widget.initialSurah != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(Icons.replay_circle_filled_rounded, size: 18, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.rec.prefilled, style: TextStyle(fontSize: 12, color: Colors.amber.shade900))),
                    ]),
                  ),
                if (widget.editing == null && _position != null) _positionBanner(context, _position!),
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: MessageBanner(message: _error!)),

                // 1. what kind of work - one tap
                _Label(t.rec.type),
                Row(children: [
                  for (final e in kAchievementTypes.entries) ...[
                    if (e.key != kAchievementTypes.keys.first) const SizedBox(width: 8),
                    Expanded(
                      child: _Pill(
                        label: e.value,
                        icon: switch (e.key) { 'new_memorization' => Icons.auto_stories_rounded, 'recent_review' => Icons.replay_rounded, _ => Icons.history_rounded },
                        selected: _type == e.key,
                        onTap: () => setState(() => _type = e.key),
                      ),
                    ),
                  ],
                ]),

                // 2. where in the Quran
                const SizedBox(height: 18),
                for (var i = 0; i < _parts.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PartEditor(
                      part: _parts[i],
                      index: i,
                      canRemove: _parts.length > 1,
                      onChanged: () => setState(() {}),
                      onPickSurah: () async {
                        final s = await _pickSurah();
                        if (s != null) {
                          setState(() {
                            _parts[i].surah = s;
                            _parts[i].from.text = '1';
                            _parts[i].to.text = '${ayahCount(s)}';
                          });
                        }
                      },
                      onRemove: () => setState(() {
                        _parts[i].dispose();
                        _parts.removeAt(i);
                      }),
                    ),
                  ),
                if (widget.editing == null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _parts.add(_PartInput())),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      label: Text(t.rec.addSurah),
                    ),
                  ),

                // 3. how well - big tiles
                const SizedBox(height: 8),
                _Label(t.rec.grade),
                LayoutBuilder(builder: (context, c) {
                  final perRow = widget.grades.length <= 4 ? 2 : 3;
                  final w = (c.maxWidth - (perRow - 1) * 8) / perRow;
                  return Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final g in widget.grades)
                      SizedBox(
                        width: w,
                        child: _GradeTile(
                          label: g.label,
                          points: g.points,
                          color: TeacherStyle.gradeColor(widget.grades, g.key),
                          selected: _grade == g.key,
                          onTap: () => setState(() {
                            _grade = g.key;
                            _error = null;
                          }),
                        ),
                      ),
                  ]);
                }),

                // 4. a note only when needed
                const SizedBox(height: 14),
                if (_showNotes || _notes.text.isNotEmpty)
                  TextField(
                    controller: _notes,
                    maxLines: 2,
                    autofocus: _showNotes && _notes.text.isEmpty,
                    decoration: InputDecoration(labelText: t.rec.notes, prefixIcon: const Icon(Icons.edit_note_rounded)),
                  )
                else
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _showNotes = true),
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: Text(t.rec.addNote),
                    ),
                  ),
              ]),
            ),
          ),

          // always in reach: save, with what it is worth
          Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -3))]),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              label: Text(
                widget.editing != null
                    ? t.rec.saveEdit
                    : points == null
                        ? t.rec.saveBtn
                        : fmt(t.rec.saveWithPoints, {'n': points}),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// A small section heading inside the sheet.
class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: TeacherStyle.textPrimary)),
      );
}

/// One choice of the recitation type.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).colorScheme.primary;
    return Material(
      color: selected ? brand : TeacherStyle.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? brand : TeacherStyle.border)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 20, color: selected ? Colors.white : TeacherStyle.textMuted),
            const SizedBox(height: 4),
            Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: TextStyle(height: 1.15, fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : TeacherStyle.textPrimary)),
          ]),
        ),
      ),
    );
  }
}

/// One grade as a big coloured tile with its points.
class _GradeTile extends StatelessWidget {
  const _GradeTile({required this.label, required this.points, required this.color, required this.selected, required this.onTap});
  final String label;
  final int points;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? color : color.withValues(alpha: 0.3), width: selected ? 2 : 1)),
          child: Row(children: [
            Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: selected ? Colors.white : color))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: selected ? Colors.white.withValues(alpha: 0.25) : Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Text('+$points', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: selected ? Colors.white : color)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PartEditor extends StatelessWidget {
  const _PartEditor({
    required this.part,
    required this.index,
    required this.canRemove,
    required this.onPickSurah,
    required this.onRemove,
    required this.onChanged,
  });

  final _PartInput part;
  final int index;
  final bool canRemove;
  final VoidCallback onPickSurah;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  void _step(TextEditingController c, int delta, int max) {
    final v = (int.tryParse(c.text.trim()) ?? 1) + delta;
    c.text = '${v.clamp(1, max)}';
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final brand = Theme.of(context).colorScheme.primary;
    final surah = part.surah;
    final max = surah == null ? null : ayahCount(surah);
    final whole = max != null && part.from.text.trim() == '1' && part.to.text.trim() == '$max';

    Widget number(String label, TextEditingController c) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: TeacherStyle.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Container(
              height: 48,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: TeacherStyle.border)),
              child: Row(children: [
                IconButton(visualDensity: VisualDensity.compact, onPressed: max == null ? null : () => _step(c, -1, max), icon: const Icon(Icons.remove_rounded, size: 20)),
                Expanded(
                  child: TextField(
                    controller: c,
                    enabled: max != null,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (_) => onChanged(),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    decoration: const InputDecoration(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, disabledBorder: InputBorder.none, filled: false, isDense: true, contentPadding: EdgeInsets.zero),
                  ),
                ),
                IconButton(visualDensity: VisualDensity.compact, onPressed: max == null ? null : () => _step(c, 1, max), icon: const Icon(Icons.add_rounded, size: 20)),
              ]),
            ),
          ]),
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: TeacherStyle.surfaceAlt, borderRadius: BorderRadius.circular(16), border: Border.all(color: TeacherStyle.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // the surah: a big button that says which one
        Material(
          color: surah == null ? brand.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPickSurah,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: surah == null ? brand.withValues(alpha: 0.4) : TeacherStyle.border)),
              child: Row(children: [
                Icon(Icons.menu_book_rounded, color: brand),
                const SizedBox(width: 10),
                Expanded(
                  child: surah == null
                      ? Text(t.rec.pickSurah, style: TextStyle(color: brand, fontWeight: FontWeight.w800, fontSize: 15))
                      : Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(fmt(t.stu.surahV, {'v': surahName(surah)}), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                          Text(fmt(t.rec.ayahsN, {'v': max}), style: const TextStyle(fontSize: 11.5, color: TeacherStyle.textMuted)),
                        ]),
                ),
                Text(surah == null ? '' : t.rec.change, style: TextStyle(color: brand, fontWeight: FontWeight.w700, fontSize: 12.5)),
                if (canRemove) IconButton(visualDensity: VisualDensity.compact, onPressed: onRemove, icon: const Icon(Icons.close_rounded, size: 20)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // the ayahs: steppers, and one tap for the whole surah
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          number(t.rec.fromAyah, part.from),
          const SizedBox(width: 10),
          number(t.rec.toAyah, part.to),
        ]),
        if (max != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilterChip(
              label: Text(t.rec.wholeSurah),
              labelStyle: TextStyle(color: brand, fontWeight: FontWeight.w700),
              checkmarkColor: brand,
              selectedColor: brand.withValues(alpha: 0.12),
              backgroundColor: Colors.white,
              selected: whole,
              showCheckmark: true,
              onSelected: (_) {
                part.from.text = '1';
                part.to.text = '$max';
                onChanged();
              },
            ),
          ),
        ],
      ]),
    );
  }
}

class _SurahPicker extends StatefulWidget {
  const _SurahPicker();

  @override
  State<_SurahPicker> createState() => _SurahPickerState();
}

class _SurahPickerState extends State<_SurahPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final items = [
      // from An-Nas down to Al-Fatiha: the order most students memorise in
      for (var i = 114; i >= 1; i--)
        if (_query.isEmpty || surahName(i).contains(_query) || '$i' == _query) i,
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(hintText: tr(context).rec.searchSurah, prefixIcon: Icon(Icons.search_rounded)),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final n = items[index];
                  return ListTile(
                    leading: CircleAvatar(radius: 16, child: Text('$n', style: const TextStyle(fontSize: 12))),
                    title: Text(surahName(n)),
                    subtitle: Text(fmt(tr(context).rec.ayahsN, {'v': ayahCount(n)})),
                    onTap: () => Navigator.pop(context, n),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
