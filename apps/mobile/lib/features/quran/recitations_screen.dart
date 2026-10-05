import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../core/data/quran_data.dart';
import '../../core/i18n/i18n.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/ui.dart';
import 'quran_data.dart';
import 'recitation_api.dart';

/// Recorded recitations: the teacher's inbox (approve / return) or, for the
/// family, the student's own list with the teacher's decision.
class RecitationsScreen extends StatefulWidget {
  const RecitationsScreen({super.key, this.family = false});

  final bool family;

  @override
  State<RecitationsScreen> createState() => _RecitationsScreenState();
}

class _RecitationsScreenState extends State<RecitationsScreen> {
  final _api = RecitationApi();
  final _player = AudioPlayer();
  late final String _orgId = context.read<TenantController>().active!.organization.id;
  Future<List<RecitationItem>>? _future;
  List<({String key, String label})> _grades = const [];
  List<ReciteStudent> _students = const [];
  String? _studentId;
  bool _reviewed = false;
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _api.grades(_orgId).then((g) => mounted ? setState(() => _grades = g) : null).catchError((_) {});
    _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed && mounted) setState(() => _playingId = null);
    });
    _reload();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = widget.family ? _family() : _api.inbox(_orgId, reviewed: _reviewed);
    });
  }

  Future<List<RecitationItem>> _family() async {
    if (_students.isEmpty) {
      _students = (await _api.people(_orgId)).students;
      _studentId ??= _students.isEmpty ? null : _students.first.id;
    }
    return _studentId == null ? const [] : _api.ofStudent(_orgId, _studentId!);
  }

  Future<void> _play(RecitationItem r) async {
    if (_playingId == r.id) {
      await _player.stop();
      setState(() => _playingId = null);
      return;
    }
    final url = await _api.audioUrl(r.audioPath!);
    if (url == null) return;
    setState(() => _playingId = r.id);
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => _playingId = null);
    }
  }

  Future<void> _review(RecitationItem r, bool approve) async {
    final t = currentStrings.recite;
    final note = TextEditingController();
    String? grade = _grades.isEmpty ? null : _grades.first.key;
    var type = r.type;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(approve ? t.approve : t.reject),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (approve) ...[
                DropdownButtonFormField<String>(
                  initialValue: grade,
                  decoration: InputDecoration(labelText: t.grade),
                  items: [for (final g in _grades) DropdownMenuItem(value: g.key, child: Text(g.label))],
                  onChanged: (v) => setDialog(() => grade = v),
                ),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: InputDecoration(labelText: t.type),
                  items: [for (final e in currentStrings.labels.recitationType.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                  onChanged: (v) => setDialog(() => type = v ?? type),
                ),
              ],
              TextField(controller: note, maxLength: 500, decoration: InputDecoration(labelText: approve ? t.testNote : t.rejectNote)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancel)),
            FilledButton(
              onPressed: (approve && grade == null) ? null : () => Navigator.pop(context, true),
              child: Text(approve ? t.approve : t.reject),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await _api.review(r.id, approve: approve, grade: grade, type: type, note: note.text.trim().isEmpty ? null : note.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? t.statusApproved : t.statusRejected)));
      _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e, t.error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context).recite;
    return Scaffold(
      appBar: AppBar(
        leading: widget.family ? null : DrawerLeading(),
        title: Text(widget.family ? t.myTitle : t.inboxTitle),
      ),
      drawer: widget.family ? null : const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<RecitationItem>>(
          future: _future,
          builder: (context, snap) {
            final header = <Widget>[
              if (!widget.family) ...[
                Text(t.inboxHint, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                const SizedBox(height: 10),
                SegmentedButton<bool>(
                  segments: [ButtonSegment(value: false, label: Text(t.pending)), ButtonSegment(value: true, label: Text(t.reviewed))],
                  selected: {_reviewed},
                  onSelectionChanged: (v) {
                    _reviewed = v.first;
                    _reload();
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (widget.family && _students.length > 1) ...[
                Wrap(spacing: 6, children: [
                  for (final s in _students)
                    ChoiceChip(
                      label: Text(s.name),
                      selected: s.id == _studentId,
                      onSelected: (_) {
                        _studentId = s.id;
                        _reload();
                      },
                    ),
                ]),
                const SizedBox(height: 10),
              ],
            ];
            if (snap.hasError) return ListView(children: [ErrorState(onRetry: _reload)]);
            if (snap.connectionState != ConnectionState.done) return ListView(padding: const EdgeInsets.all(16), children: [...header, const SkeletonCards()]);
            final items = snap.data ?? const [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                ...header,
                if (items.isEmpty) EmptyState(icon: Icons.mic_none_rounded, title: t.none),
                for (final r in items) _card(r),
                const SizedBox(height: 12),
                Text(t.autoNote, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _card(RecitationItem r) {
    final t = tr(context).recite;
    final (label, color) = switch (r.status) {
      'approved' => (t.statusApproved, Colors.green),
      'rejected' => (t.statusRejected, Colors.red),
      'submitted' => (t.statusSubmitted, Colors.amber),
      _ => (t.statusDraft, Colors.grey),
    };
    final check = r.check;
    final grade = _grades.where((g) => g.key == r.grade).firstOrNull?.label ?? r.grade;
    final flagged = r.kind == 'teacher_test'
        ? [for (final m in r.mistakes) (a: (m['ayah'] as num).toInt(), i: (m['word'] as num).toInt(), s: 'mistake', text: m['text'] as String?)]
        : [
            for (final e in check.marks.entries)
              (a: int.parse(e.key.split(':')[0]), i: int.parse(e.key.split(':')[1]), s: e.value, text: null as String?),
          ];
    final at = r.at;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                [if (!widget.family && r.student != null) r.student!, passageLabel(surahName(r.surah), r.from, r.to)].join('  ·  '),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            StatusChip(label: label, color: color),
          ]),
          const SizedBox(height: 4),
          Text(
            [
              tr(context).labels.recitationType[r.type] ?? r.type,
              if (r.kind == 'teacher_test') t.teacherTest,
              if (at != null) '${at.year}/${at.month}/${at.day} ${at.hour}:${at.minute.toString().padLeft(2, '0')}',
              if (!widget.family && r.circle != null) r.circle!,
              if (r.kind == 'self') r.autoScore != null ? '${fmt(t.autoScore, {'n': r.autoScore})} · ${check.missing} ${t.missing} · ${check.wrong} ${t.wrong}' : t.noAuto,
              if (r.kind == 'teacher_test') fmt(t.mistakes, {'n': r.mistakes.length}),
              ?grade,
              if (r.reviewer != null && r.kind == 'self' && r.status != 'submitted') fmt(t.reviewedBy, {'name': r.reviewer}),
            ].join('  ·  '),
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          if (flagged.isNotEmpty) _Words(surah: r.surah, items: flagged, teacherTest: r.kind == 'teacher_test'),
          if (r.studentNote != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(fmt(t.studentNote, {'note': r.studentNote}))),
          if (r.teacherNote != null)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text(fmt(t.teacherNote, {'note': r.teacherNote})),
            ),
          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            if (r.audioPath != null)
              TextButton.icon(
                onPressed: () => _play(r),
                icon: Icon(_playingId == r.id ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded),
                label: Text(t.play),
              ),
            TextButton.icon(
              onPressed: () => context.push('/quran/${r.surah}?ayah=${r.from}'),
              icon: const Icon(Icons.auto_stories_outlined),
              label: Text(t.openMushaf),
            ),
          ]),
          if (!widget.family && r.status == 'submitted')
            Row(children: [
              Expanded(child: FilledButton(onPressed: () => _review(r, true), child: Text(t.approve))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () => _review(r, false), style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700), child: Text(t.reject))),
            ]),
        ]),
      ),
    );
  }
}

/// The flagged words written out (the result only stores their places).
class _Words extends StatelessWidget {
  const _Words({required this.surah, required this.items, required this.teacherTest});

  final int surah;
  final List<({int a, int i, String s, String? text})> items;
  final bool teacherTest;

  @override
  Widget build(BuildContext context) {
    final t = tr(context).recite;
    return FutureBuilder<SurahDetail>(
      future: QuranTextService().surah(surah),
      builder: (context, snap) {
        String word(({int a, int i, String s, String? text}) w) {
          if (w.text != null && w.text!.isNotEmpty) return w.text!;
          final text = snap.data?.ayahs.where((x) => x.number == w.a).firstOrNull?.text;
          if (text == null) return '…';
          final r = wordRanges(text);
          return w.i < r.length ? text.substring(r[w.i].$1, r[w.i].$2) : '…';
        }

        Widget row(String label, List<({int a, int i, String s, String? text})> list, Color color) => list.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(spacing: 8, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                  for (final w in list)
                    Text('${word(w)} ${arabicNumber(w.a)}', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 18, color: color)),
                ]),
              );

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          row(teacherTest ? t.markedMistakes.replaceAll('{list}', '') : t.missingWords, items.where((w) => w.s != 'wrong').toList(), Colors.red.shade700),
          row(t.heardAs, items.where((w) => w.s == 'wrong').toList(), Colors.deepOrange.shade700),
        ]);
      },
    );
  }
}
