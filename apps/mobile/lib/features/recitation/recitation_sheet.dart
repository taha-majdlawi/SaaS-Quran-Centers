import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/quran_data.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import 'recitation_repository.dart';

/// Opens the "log a recitation" sheet. Resolves to the total points awarded
/// (or null if the teacher cancelled).
Future<int?> showRecitationSheet(
  BuildContext context, {
  required String studentId,
  required String studentName,
  required List<GradeOption> grades,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => _RecitationSheet(studentId: studentId, studentName: studentName, grades: grades),
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

class _RecitationSheet extends StatefulWidget {
  const _RecitationSheet({required this.studentId, required this.studentName, required this.grades});

  final String studentId;
  final String studentName;
  final List<GradeOption> grades;

  @override
  State<_RecitationSheet> createState() => _RecitationSheetState();
}

class _RecitationSheetState extends State<_RecitationSheet> {
  final _repository = RecitationRepository(AppSupabase.client);
  final _notes = TextEditingController();
  final List<_PartInput> _parts = [_PartInput()];
  String _type = 'new_memorization';
  String? _grade;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

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
    if (_grade == null) return 'اختر تقييم التلاوة';
    for (final p in _parts) {
      if (p.surah == null) return 'اختر السورة';
      final from = int.tryParse(p.from.text.trim());
      final to = int.tryParse(p.to.text.trim());
      if (from == null || to == null || from < 1) return 'أدخل نطاق الآيات';
      if (to < from) return 'آية النهاية يجب أن تكون بعد آية البداية أو تساويها';
      if (to > ayahCount(p.surah!)) return 'سورة ${surahName(p.surah!)} فيها ${ayahCount(p.surah!)} آية فقط';
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
    final group = _parts.length > 1 ? _repository.newSessionGroupId() : null;
    var total = 0;
    var saved = 0;
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
          type: _type,
          part: SurahPart(surah: p.surah!, ayahFrom: int.parse(p.from.text.trim()), ayahTo: int.parse(p.to.text.trim())),
          grade: _grade!,
          notes: _notes.text,
          recordedAt: recorded,
          sessionGroupId: group,
        );
        total += result.pointsAwarded;
        saved++;
        _parts.remove(p);
      }
      if (mounted) Navigator.pop(context, total);
    } on PostgrestException catch (e) {
      setState(() => _error = saved > 0 ? 'حُفظ $saved، ولم يُحفظ الباقي: ${e.message}' : e.message);
    } catch (_) {
      setState(() => _error = 'تعذّر الحفظ، تأكد من الإنترنت وحاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = _date.year == today.year && _date.month == today.month && _date.day == today.day;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Text('تسجيل إنجاز يومي', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text(widget.studentName, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            if (_error != null) MessageBanner(message: _error!),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_rounded, size: 18),
              label: Text(isToday ? 'تاريخ التسميع: اليوم' : 'تاريخ التسميع: ${_date.year}/${_date.month}/${_date.day}'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'نوع الإنجاز', prefixIcon: Icon(Icons.bookmark_outline)),
              items: kAchievementTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            for (var i = 0; i < _parts.length; i++) ...[
              const SizedBox(height: 12),
              _PartEditor(
                part: _parts[i],
                index: i,
                canRemove: _parts.length > 1,
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
            ],
            TextButton.icon(
              onPressed: () => setState(() => _parts.add(_PartInput())),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('إضافة سورة أخرى لنفس الجلسة'),
            ),
            const SectionTitle('تقييم التلاوة'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in widget.grades)
                  ChoiceChip(
                    label: Text('${g.label}  ·  ${g.points}'),
                    selected: _grade == g.key,
                    onSelected: (_) => setState(() => _grade = g.key),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'ملاحظات الشيخ (اختياري)', prefixIcon: Icon(Icons.edit_note_rounded)),
            ),
            const SizedBox(height: 20),
            LoadingButton(label: 'حفظ التسميع', icon: Icons.check_rounded, loading: _saving, onPressed: _save),
          ],
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
  });

  final _PartInput part;
  final int index;
  final bool canRemove;
  final VoidCallback onPickSurah;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final max = part.surah == null ? null : ayahCount(part.surah!);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickSurah,
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text(part.surah == null ? 'اختر السورة' : 'سورة ${surahName(part.surah!)}'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                ),
              ),
              if (canRemove) IconButton(onPressed: onRemove, icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: part.from,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'من آية'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: part.to,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'إلى آية', helperText: max == null ? null : 'الحد $max'),
                ),
              ),
            ],
          ),
        ],
      ),
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
      for (var i = 1; i <= 114; i++)
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
                decoration: const InputDecoration(hintText: 'ابحث باسم السورة أو رقمها', prefixIcon: Icon(Icons.search_rounded)),
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
                    subtitle: Text('${ayahCount(n)} آية'),
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
