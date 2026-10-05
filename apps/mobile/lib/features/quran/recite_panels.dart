import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/i18n/i18n.dart';
import '../../core/widgets/ui.dart';
import 'quran_data.dart';
import 'recitation_api.dart';

const _types = ['new_memorization', 'recent_review', 'distant_review'];
const _maxSeconds = 5 * 60;

/// A passage to repeat: from..to, [times] times.
class PassageRepeat {
  const PassageRepeat(this.from, this.to, this.times);
  final int from, to, times;
}

/// From / to fields, kept inside 1..[max] and in order.
class _RangeRow extends StatefulWidget {
  const _RangeRow({required this.from, required this.to, required this.max, required this.onChanged, this.enabled = true});

  final int from, to, max;
  final void Function(int from, int to) onChanged;
  final bool enabled;

  @override
  State<_RangeRow> createState() => _RangeRowState();
}

class _RangeRowState extends State<_RangeRow> {
  late final _from = TextEditingController(text: '${widget.from}');
  late final _to = TextEditingController(text: '${widget.to}');

  @override
  void didUpdateWidget(_RangeRow old) {
    super.didUpdateWidget(old);
    // set from outside (a new panel): show it, without fighting the typing
    if (int.tryParse(_from.text) != widget.from && old.from != widget.from) _from.text = '${widget.from}';
    if (int.tryParse(_to.text) != widget.to && old.to != widget.to) _to.text = '${widget.to}';
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context).recite;
    Widget field(String label, TextEditingController c, void Function(int) set) => SizedBox(
          width: 92,
          child: TextField(
            controller: c,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: label, isDense: true),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null && n >= 1 && n <= widget.max) set(n);
            },
          ),
        );
    return Wrap(spacing: 8, runSpacing: 8, children: [
      // put in order where they are used: typing "15" passes through "1"
      field(t.from, _from, (n) => widget.onChanged(n, widget.to)),
      field(t.to, _to, (n) => widget.onChanged(widget.from, n)),
    ]);
  }
}

/// Repeating a passage. Returns the choice, or a 0-times choice to stop repeating.
Future<PassageRepeat?> showRangeSheet(BuildContext context, {required int max, required PassageRepeat initial}) {
  var from = initial.from, to = initial.to, times = initial.times;
  return showModalBottomSheet<PassageRepeat>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) {
        final t = tr(context).recite;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(t.rangeTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              _RangeRow(from: from, to: to, max: max, onChanged: (f, x) => setSheet(() => (from, to) = (f, x))),
              const SizedBox(height: 12),
              Text(t.times, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final n in [1, 2, 3, 5, 7, 10, 20, 30]) ChoiceChip(label: Text('×$n'), selected: times == n, onSelected: (_) => setSheet(() => times = n)),
              ]),
              const SizedBox(height: 10),
              Text(fmt(t.rangeHint, {'from': from, 'to': to, 'times': times}), style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: FilledButton.icon(onPressed: () => Navigator.pop(context, PassageRepeat(from < to ? from : to, from < to ? to : from, times)), icon: const Icon(Icons.repeat_rounded), label: Text(t.apply))),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () => Navigator.pop(context, const PassageRepeat(0, 0, 0)), child: Text(t.rangeOff)),
              ]),
            ]),
          ),
        );
      },
    ),
  );
}

Widget _panel(BuildContext context, List<Widget> children) => Material(
      color: Colors.white,
      elevation: 3,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );

Widget _header(BuildContext context, String title, VoidCallback onClose) => Row(children: [
      Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
      IconButton(visualDensity: VisualDensity.compact, onPressed: onClose, icon: const Icon(Icons.close_rounded), tooltip: tr(context).recite.cancel),
    ]);

Widget _typeDropdown(BuildContext context, String value, ValueChanged<String> onChanged, {bool enabled = true}) => DropdownButtonFormField<String>(
      initialValue: value,
      isDense: true,
      decoration: InputDecoration(labelText: tr(context).recite.type, isDense: true),
      items: [for (final k in _types) DropdownMenuItem(value: k, child: Text(tr(context).labels.recitationType[k] ?? k))],
      onChanged: enabled ? (v) => v == null ? null : onChanged(v) : null,
    );

enum _Phase { setup, recording, working, result, sent }

/// The student (or their guardian) recites a passage from memory: record, the
/// site checks it, the result shows on the page, then it goes to the teacher.
class RecitePanel extends StatefulWidget {
  const RecitePanel({
    super.key,
    required this.orgId,
    required this.surah,
    required this.max,
    required this.from,
    required this.to,
    required this.onHide,
    required this.onMarks,
    required this.onClose,
    this.initialType,
  });

  final String orgId;
  final int surah, max, from, to;
  final String? initialType;
  final ValueChanged<bool> onHide;
  final ValueChanged<WordMarks> onMarks;
  final VoidCallback onClose;

  @override
  State<RecitePanel> createState() => _RecitePanelState();
}

class _RecitePanelState extends State<RecitePanel> {
  final _api = RecitationApi();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final _note = TextEditingController();
  RecitePeople? _people;
  String? _studentId;
  late int _from = widget.from, _to = widget.to;
  late String _type = _types.contains(widget.initialType) ? widget.initialType! : 'new_memorization';
  _Phase _phase = _Phase.setup;
  String _status = '';
  String? _error;
  int _seconds = 0;
  Timer? _timer;
  String? _file;
  ReciteCheck? _check;
  ({String id, String path})? _saved;

  @override
  void initState() {
    super.initState();
    _api.people(widget.orgId).then((p) {
      if (!mounted) return;
      setState(() {
        _people = p;
        _studentId = p.students.isEmpty ? null : p.students.first.id;
      });
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _player.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final t = currentStrings.recite;
    setState(() => _error = null);
    if (!await _recorder.hasPermission()) {
      setState(() => _error = t.micDeniedApp);
      return;
    }
    final dir = await getTemporaryDirectory();
    _file = '${dir.path}/recite_${DateTime.now().millisecondsSinceEpoch}.wav';
    // the format the speech check expects: 16 kHz, mono, WAV
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1, echoCancel: true, noiseSuppress: true), path: _file!);
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
      if (_seconds >= _maxSeconds) _stop();
    });
    widget.onMarks(const {});
    widget.onHide(true);
    setState(() => _phase = _Phase.recording);
  }

  Future<void> _stop() async {
    final t = currentStrings.recite;
    _timer?.cancel();
    final path = await _recorder.stop() ?? _file;
    setState(() {
      _phase = _Phase.working;
      _status = t.uploading;
    });
    try {
      final saved = await _api.create(
        orgId: widget.orgId,
        studentId: _studentId!,
        type: _type,
        surah: widget.surah,
        from: _from < _to ? _from : _to,
        to: _from < _to ? _to : _from,
        file: File(path!),
        seconds: _seconds,
      );
      _saved = saved;
      if (mounted) setState(() => _status = t.checking);
      final check = await _api.check(saved.id);
      if (!mounted) return;
      widget.onMarks(check.marks);
      widget.onHide(false);
      setState(() {
        _check = check;
        _phase = _Phase.result;
      });
    } catch (e) {
      widget.onHide(false);
      if (mounted) {
        setState(() {
          _error = friendlyError(e, t.uploadFailed);
          _phase = _Phase.setup;
        });
      }
    }
  }

  Future<void> _send() async {
    final saved = _saved;
    if (saved == null) return;
    setState(() => _phase = _Phase.working);
    try {
      await _api.submit(saved.id, _note.text.trim().isEmpty ? null : _note.text.trim());
      _saved = null; // sent: it is the teacher's now, never discarded from here
      if (mounted) setState(() => _phase = _Phase.sent);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e, currentStrings.recite.error);
          _phase = _Phase.result;
        });
      }
    }
  }

  Future<void> _again() async {
    final saved = _saved;
    _saved = null;
    await _player.stop();
    if (saved != null) await _api.discard(saved.id, saved.path).catchError((_) {});
    widget.onMarks(const {});
    if (mounted) {
      setState(() {
        _check = null;
        _phase = _Phase.setup;
      });
    }
  }

  void _close() {
    if (_phase == _Phase.recording) {
      _timer?.cancel();
      _recorder.cancel();
    }
    // a checked recording that was never sent is not kept
    final saved = _saved;
    if (_phase == _Phase.result && saved != null) {
      _saved = null;
      _api.discard(saved.id, saved.path).catchError((_) {});
    }
    widget.onHide(false);
    widget.onMarks(const {});
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context).recite;
    final busy = _phase != _Phase.setup;
    final students = _people?.students ?? const <ReciteStudent>[];
    final mm = '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}';
    final check = _check;

    return _panel(context, [
      _header(context, t.reciteTitle, _close),
      if (students.length > 1)
        DropdownButtonFormField<String>(
          initialValue: _studentId,
          decoration: InputDecoration(labelText: t.student, isDense: true),
          items: [for (final s in students) DropdownMenuItem(value: s.id, child: Text(s.name))],
          onChanged: busy ? null : (v) => setState(() => _studentId = v),
        ),
      const SizedBox(height: 8),
      Row(children: [
        _RangeRow(from: _from, to: _to, max: widget.max, enabled: !busy, onChanged: (f, x) => setState(() {
          _from = f;
          _to = x;
        })),
        const SizedBox(width: 8),
        Expanded(child: _typeDropdown(context, _type, (v) => setState(() => _type = v), enabled: !busy)),
      ]),
      const SizedBox(height: 10),
      if (_phase == _Phase.setup) ...[
        FilledButton.icon(onPressed: _studentId == null ? null : _start, icon: const Icon(Icons.mic_rounded), label: Text(t.start)),
        const SizedBox(height: 6),
        Text(t.reciteHint, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
      ],
      if (_phase == _Phase.recording)
        Row(children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: _stop,
            icon: const Icon(Icons.stop_rounded),
            label: Text(t.stop),
          ),
          const SizedBox(width: 12),
          Icon(Icons.fiber_manual_record_rounded, color: Colors.red.shade700, size: 14),
          const SizedBox(width: 4),
          Expanded(child: Text('${t.recording}  $mm', style: TextStyle(color: Colors.red.shade700))),
        ]),
      if (_phase == _Phase.working)
        Row(children: [
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 10),
          Text(_status),
        ]),
      if (_phase == _Phase.result && check != null) ...[
        if (!check.available)
          MessageBanner(message: t.unavailable)
        else ...[
          Wrap(spacing: 14, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(fmt(t.score, {'n': check.score}), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
            Text('${check.ok} ${t.correct}'),
            Text('${check.missing} ${t.missing}', style: TextStyle(color: Colors.red.shade700)),
            Text('${check.wrong} ${t.wrong}', style: TextStyle(color: Colors.deepOrange.shade700)),
            if (check.extra > 0) Text('${check.extra} ${t.extra}', style: const TextStyle(color: Colors.grey)),
          ]),
          const SizedBox(height: 4),
          Text(t.legend, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        ],
        if (_file != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () async {
                await _player.setFilePath(_file!);
                await _player.play();
              },
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: Text(t.play),
            ),
          ),
        Text(t.autoNote, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
        const SizedBox(height: 6),
        TextField(controller: _note, maxLength: 300, decoration: InputDecoration(hintText: t.note, isDense: true, counterText: '')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: FilledButton.icon(onPressed: _send, icon: const Icon(Icons.send_rounded), label: Text(t.send))),
          const SizedBox(width: 8),
          OutlinedButton.icon(onPressed: _again, icon: const Icon(Icons.replay_rounded), label: Text(t.again)),
        ]),
      ],
      if (_phase == _Phase.sent) ...[
        MessageBanner(message: t.sent, isError: false),
        OutlinedButton(
          onPressed: () {
            _saved = null;
            _note.clear();
            widget.onMarks(const {});
            setState(() {
              _check = null;
              _phase = _Phase.setup;
            });
          },
          child: Text(t.again),
        ),
      ],
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: MessageBanner(message: _error!)),
    ]);
  }
}

/// The teacher tests a student in the mushaf: the ayahs hidden, the mistakes
/// marked on the words, the result saved straight into the student's record.
class TestPanel extends StatefulWidget {
  const TestPanel({
    super.key,
    required this.orgId,
    required this.surah,
    required this.max,
    required this.from,
    required this.to,
    required this.marks,
    required this.wordText,
    required this.onReset,
    required this.onClose,
  });

  final String orgId;
  final int surah, max, from, to;
  final WordMarks marks;
  final String Function(int ayah, int word) wordText;
  final VoidCallback onReset;
  final VoidCallback onClose;

  @override
  State<TestPanel> createState() => _TestPanelState();
}

class _TestPanelState extends State<TestPanel> {
  final _api = RecitationApi();
  final _note = TextEditingController();
  RecitePeople? _people;
  List<({String key, String label})> _grades = const [];
  String? _studentId, _grade;
  late int _from = widget.from, _to = widget.to;
  String _type = 'new_memorization';
  bool _busy = false;
  String? _msg;
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    Future.wait([_api.people(widget.orgId), _api.grades(widget.orgId)]).then((r) {
      if (!mounted) return;
      final people = r[0] as RecitePeople;
      final grades = r[1] as List<({String key, String label})>;
      setState(() {
        _people = people;
        _grades = grades;
        _studentId = people.students.isEmpty ? null : people.students.first.id;
        _grade = grades.isEmpty ? null : grades.first.key;
      });
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  List<String> get _inRange => [
        for (final k in widget.marks.keys)
          if ((int.tryParse(k.split(':').first) ?? 0) >= _from && (int.tryParse(k.split(':').first) ?? 0) <= _to) k,
      ];

  Future<void> _save() async {
    final t = currentStrings.recite;
    if (_from > _to) {
      setState(() {
        _ok = false;
        _msg = t.badRange;
      });
      return;
    }
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final mistakes = [
        for (final k in _inRange)
          {'ayah': int.parse(k.split(':')[0]), 'word': int.parse(k.split(':')[1]), 'text': widget.wordText(int.parse(k.split(':')[0]), int.parse(k.split(':')[1]))},
      ];
      final r = await _api.recordTest(
        orgId: widget.orgId,
        studentId: _studentId!,
        type: _type,
        surah: widget.surah,
        from: _from,
        to: _to,
        grade: _grade!,
        mistakes: mistakes,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      final name = _people?.students.where((s) => s.id == _studentId).firstOrNull?.name ?? '';
      _note.clear();
      widget.onReset();
      setState(() {
        _ok = true;
        _msg = fmt(t.saved, {'name': name, 'points': r['points_awarded'] ?? 0});
      });
    } catch (e) {
      setState(() {
        _ok = false;
        _msg = friendlyError(e, t.error);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context).recite;
    final people = _people;
    if (people != null && people.students.isEmpty) {
      return _panel(context, [_header(context, t.testTitle, widget.onClose), Text(t.noStudents)]);
    }
    return _panel(context, [
      _header(context, t.testTitle, widget.onClose),
      DropdownButtonFormField<String>(
        initialValue: _studentId,
        isExpanded: true,
        decoration: InputDecoration(labelText: t.chooseStudent, isDense: true),
        items: [
          for (final s in people?.students ?? const <ReciteStudent>[])
            DropdownMenuItem(value: s.id, child: Text(s.circle == null ? s.name : '${s.name} — ${s.circle}', overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => setState(() => _studentId = v),
      ),
      const SizedBox(height: 8),
      Row(children: [
        _RangeRow(from: _from, to: _to, max: widget.max, onChanged: (f, x) => setState(() {
          _from = f;
          _to = x;
        })),
        const SizedBox(width: 8),
        Expanded(child: _typeDropdown(context, _type, (v) => setState(() => _type = v))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _grade,
            decoration: InputDecoration(labelText: t.grade, isDense: true),
            items: [for (final g in _grades) DropdownMenuItem(value: g.key, child: Text(g.label))],
            onChanged: (v) => setState(() => _grade = v),
          ),
        ),
        const SizedBox(width: 10),
        Chip(
          backgroundColor: Colors.red.shade50,
          label: Text(fmt(t.mistakes, {'n': arabicNumber(_inRange.length)}), style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w700)),
        ),
      ]),
      const SizedBox(height: 6),
      Text(t.testHint, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
      const SizedBox(height: 6),
      TextField(controller: _note, maxLength: 500, decoration: InputDecoration(hintText: t.testNote, isDense: true, counterText: '')),
      const SizedBox(height: 8),
      LoadingButton(label: t.save, icon: Icons.check_rounded, loading: _busy, onPressed: _studentId == null || _grade == null ? null : _save),
      if (_msg != null) Padding(padding: const EdgeInsets.only(top: 8), child: MessageBanner(message: _msg!, isError: !_ok)),
    ]);
  }
}
