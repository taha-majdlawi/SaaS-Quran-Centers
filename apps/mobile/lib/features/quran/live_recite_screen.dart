import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/data/quran_data.dart';
import '../../core/i18n/i18n.dart';
import '../../core/monitoring/error_reporter.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import 'live_matcher.dart';
import 'live_speech.dart';
import 'quran_data.dart' show QuranTextService, arabicNumber;
import 'recitation_api.dart';

const _types = ['new_memorization', 'recent_review', 'distant_review'];
const _stall = Duration(seconds: 9); // silence on one word = forgotten
const _settle = Duration(milliseconds: 2500); // an unexpected word nothing followed = said wrong
const _ink = Color(0xFF17241E);

enum _Phase { setup, loading, live, result, sending, sent }

/// Reciting from memory with the phone following along: the chosen ayahs are hidden,
/// each word uncovers when it is said right, and a forgotten or wrong word stops the
/// student with a red mark, a sound and a vibration. The result goes to the teacher.
/// On Android 13+ the recitation is recorded from the start for the teacher (LiveSpeech: the app
/// takes the microphone and hands the sound to the recogniser); elsewhere it goes without one.
class LiveReciteScreen extends StatefulWidget {
  const LiveReciteScreen({super.key, this.studentId, this.surah, this.from, this.to, this.type});

  final String? studentId;
  final int? surah, from, to;
  final String? type;

  @override
  State<LiveReciteScreen> createState() => _LiveReciteScreenState();
}

class _LiveReciteScreenState extends State<LiveReciteScreen> {
  final _api = RecitationApi();
  final _stt = SpeechToText();
  final _native = LiveSpeech();
  bool _nativeMode = false; // recognition through LiveSpeech, with a recording
  int _nativeSession = -1; // LiveSpeech's recognition session
  List<String> _all = const []; // every word of the session so far, the unconfirmed last one too
  ({File file, int seconds})? _audio; // the recording, once finished
  String? _audioPath; // ... once uploaded (a second try does not upload it again)
  bool _canRecord = false;
  final _beep = AudioPlayer();
  final _note = TextEditingController();
  late final _fromCtl = TextEditingController(text: '$_from');
  late final _toCtl = TextEditingController(text: '$_to');
  late final String _orgId = context.read<TenantController>().active!.organization.id;

  List<ReciteStudent> _students = const [];
  String? _studentId;
  late int _surah = (widget.surah ?? 1).clamp(1, 114);
  late int _from = (widget.from ?? 1).clamp(1, ayahCount(_surah));
  late int _to = (widget.to ?? (_from + 4)).clamp(1, ayahCount(_surah));
  late String _type = _types.contains(widget.type) ? widget.type! : 'new_memorization';

  _Phase _phase = _Phase.setup;
  String? _error;
  LiveMatcher? _m;
  LiveMistake? _stop;
  bool _active = false; // the session is on (not paused, not finished)
  bool _listening = false;
  int _processed = 0; // words of the current recognition session already fed
  DateTime _lastProgress = DateTime.now();
  DateTime _lastHeard = DateTime.now();
  final _heard = <String>[];
  Timer? _timer;
  bool? _speechReady;
  String _localeId = 'ar_SA';

  @override
  void initState() {
    super.initState();
    LiveSpeech.supported().then((v) => mounted ? setState(() => _canRecord = v) : null);
    _api.people(_orgId).then((p) {
      if (!mounted) return;
      setState(() {
        _students = p.students;
        _studentId = p.students.where((s) => s.id == widget.studentId).firstOrNull?.id ?? (p.students.isEmpty ? null : p.students.first.id);
      });
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _active = false;
    _timer?.cancel();
    _stt.cancel();
    if (_nativeMode) _native.stop(discard: true);
    _audio?.file.delete().catchError((_) => _audio!.file);
    _beep.dispose();
    _note.dispose();
    _fromCtl.dispose();
    _toCtl.dispose();
    super.dispose();
  }

  ({int from, int to}) get _range => _from <= _to ? (from: _from, to: _to) : (from: _to, to: _from);

  Future<bool> _initSpeech() async {
    if (_speechReady == null) {
      _speechReady = await _stt.initialize(onStatus: _onStatus, onError: _onError).catchError((_) => false);
      if (_speechReady!) {
        // an Arabic language the phone's recogniser really has (Saudi first); a missing one would hear English
        try {
          final ids = [for (final l in await _stt.locales()) l.localeId];
          final ar = ids.where((id) => id.toLowerCase().startsWith('ar')).toList();
          _localeId = ar.firstWhere((id) => id.toLowerCase().replaceAll('-', '_') == 'ar_sa', orElse: () => ar.isNotEmpty ? ar.first : 'ar_SA');
        } catch (_) {}
      }
    }
    return _speechReady!;
  }

  void _onStatus(String status) {
    if (_nativeMode) return;
    // the recogniser ends a session after a pause: carry on while the recitation is on
    if ((status == 'done' || status == 'notListening') && mounted) {
      _takeLast(loose: true);
      setState(() => _listening = false);
      if (_active) Future.delayed(const Duration(milliseconds: 250), () => _active && !_stt.isListening ? _listen() : null);
    }
  }

  void _onError(SpeechRecognitionError e) {
    if (!mounted || _nativeMode) return;
    final msg = e.errorMsg;
    if (msg.contains('permission')) {
      _pause();
      setState(() => _error = currentStrings.live.micDenied);
    } else if (msg.contains('network')) {
      _pause();
      setState(() => _error = currentStrings.live.network);
    }
    // no_match / speech_timeout: the session simply restarts (_onStatus)
  }

  void _listen() {
    _processed = 0;
    _all = const [];
    _active = true;
    _lastProgress = DateTime.now();
    if (_nativeMode) {
      _nativeSession = -1;
      _native.resume();
      if (mounted) setState(() => _listening = true);
      return;
    }
    _stt.listen(
      onResult: _onResult,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        localeId: _localeId,
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 20),
      ),
    );
    if (mounted) setState(() => _listening = true);
  }

  void _onResult(SpeechRecognitionResult r) => _onText(r.recognizedWords, r.finalResult);

  /// LiveSpeech's events (see live_speech.dart).
  void _onNative(Map<String, dynamic> e) {
    if (!mounted || !_nativeMode) return;
    switch (e['type']) {
      case 'partial' || 'final':
        final session = (e['session'] as num?)?.toInt() ?? 0;
        if (session != _nativeSession) {
          // a new session: the last word of the one before, if it was the word expected
          _takeLast(loose: true);
          _nativeSession = session;
          _processed = 0;
          _all = const [];
        }
        _onText(e['text'] as String? ?? '', e['type'] == 'final');
      case 'listening':
        if (_active) setState(() => _listening = e['on'] == true);
      case 'error':
        final code = (e['code'] as num?)?.toInt();
        if (code == 9) {
          _pause();
          setState(() => _error = currentStrings.live.micDenied);
        } else if (code == 1 || code == 2 || code == 4) {
          _pause();
          setState(() => _error = currentStrings.live.network);
        }
      case 'fallback':
        // this phone's recogniser does not take the sound from the app: the usual recognition, no recording
        ErrorReporter.instance.crumb('live recite: recording not supported, fallback');
        _nativeMode = false;
        _native.stop(discard: true);
        setState(() => _canRecord = false);
        if (_active) _listen();
    }
  }

  void _onText(String text, bool isFinal) {
    if (!_active || _m == null) return;
    final words = stableWords(text, isFinal: isFinal);
    _all = stableWords(text, isFinal: true);
    while (_processed < words.length && _active) {
      _take(words[_processed]);
    }
    _takeLast();
  }

  void _take(String w) {
    _heard.add(w);
    _lastHeard = DateTime.now();
    _processed++;
    _handle(_m!.feed(w));
  }

  /// The last word, not confirmed yet, when it is the word expected - exactly, or loosely when
  /// the session ended: after the last word of an ayah comes a pause, nothing confirms it, and
  /// the session may end without it.
  void _takeLast({bool loose = false}) {
    if (_active && _m != null && _all.length == _processed + 1 && _m!.expects(_all.last, loose: loose)) _take(_all.last);
  }

  void _handle(LiveEvent? e) {
    if (e == null || !mounted) return;
    _lastProgress = DateTime.now();
    if (e.mistake != null) {
      _pause();
      setState(() => _stop = e.mistake);
      _alert();
    } else if (e.done) {
      _finish();
    } else {
      setState(() {});
    }
  }

  void _pause() {
    _active = false;
    if (_nativeMode) {
      _native.pause(); // the recording carries on
    } else {
      _stt.cancel();
    }
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _alert() async {
    HapticFeedback.heavyImpact();
    try {
      await _beep.setAsset('assets/sounds/wrong.wav');
      await _beep.play();
    } catch (_) {}
  }

  Future<void> _begin() async {
    final t = currentStrings.live;
    setState(() {
      _error = null;
      _phase = _Phase.loading;
    });
    if (!await _initSpeech()) {
      setState(() {
        _phase = _Phase.setup;
        _error = t.appUnsupported;
      });
      return;
    }
    try {
      final detail = await QuranTextService().surah(_surah);
      final r = _range;
      final ayahs = [for (final a in detail.ayahs) if (a.number >= r.from && a.number <= r.to) (a.number, a.text)];
      if (ayahs.isEmpty) throw StateError(t.error);
      _m = LiveMatcher(ayahs);
    } catch (e) {
      setState(() {
        _phase = _Phase.setup;
        _error = friendlyError(e, t.error);
      });
      return;
    }
    _heard.clear();
    _stop = null;
    await _audio?.file.delete().catchError((_) => _audio!.file);
    _audio = null;
    _audioPath = null;
    // recorded from the start, where the phone can (Android 13+)
    _nativeMode = false;
    if (_canRecord) {
      final dir = await getTemporaryDirectory();
      _nativeMode = await _native.start('${dir.path}/recite_${DateTime.now().millisecondsSinceEpoch}.m4a', _localeId.replaceAll('_', '-'), _onNative);
    }
    if (!mounted) return;
    setState(() => _phase = _Phase.live);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final m = _m;
      if (!_active || m == null || m.done) return;
      final now = DateTime.now();
      if (m.pending && now.difference(_lastHeard) > _settle) return _handle(m.settle());
      final wait = m.pos == 0 ? _stall * 1.6 : _stall;
      if (now.difference(_lastProgress) > wait) _handle(m.forgot());
    });
    _listen();
  }

  void _resume() {
    setState(() => _stop = null);
    if (_m?.done ?? true) {
      _finish();
      return;
    }
    _listen();
  }

  /// "Finish and send" does both: the recitation goes to the teacher right away
  /// (a second "send" button after the result was easy to miss - nothing was ever sent).
  Future<void> _finish() async {
    _pause();
    _timer?.cancel();
    _m?.finish();
    if (!mounted) return;
    setState(() {
      _stop = null;
      _phase = _Phase.sending;
    });
    if (_nativeMode) {
      _nativeMode = false;
      _audio = await _native.stop(discard: _heard.isEmpty);
    }
    if (!mounted) return;
    setState(() {
      _phase = _Phase.result;
      // nothing heard at all (the microphone, the recognition service): nothing to send
      _error = _heard.isEmpty ? currentStrings.live.nothingHeard : null;
    });
    if (_heard.isNotEmpty) _send();
  }

  void _again() => setState(() {
        _phase = _Phase.setup;
        _error = null;
      });

  Future<void> _send() async {
    final m = _m;
    if (m == null || _studentId == null) return;
    setState(() {
      _phase = _Phase.sending;
      _error = null;
    });
    try {
      final r = _range;
      final audio = _audio;
      if (audio != null && _audioPath == null) {
        try {
          _audioPath = await _api.uploadLiveAudio(orgId: _orgId, studentId: _studentId!, file: audio.file);
        } catch (e, st) {
          ErrorReporter.instance.report(e, st, context: 'live recite: upload'); // the result still goes
        }
      }
      await _api.submitLive(
        audioPath: _audioPath,
        duration: _audioPath == null ? null : audio?.seconds,
        orgId: _orgId,
        studentId: _studentId!,
        type: _type,
        surah: _surah,
        from: r.from,
        to: r.to,
        result: m.result(),
        transcript: _heard.join(' '),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      await audio?.file.delete().catchError((_) => audio.file);
      if (mounted) setState(() => _phase = _Phase.sent);
    } catch (e, st) {
      ErrorReporter.instance.report(e, st, context: 'live recite: send');
      if (mounted) {
        setState(() {
          _error = '${currentStrings.live.notSent}\n${friendlyError(e, currentStrings.live.error)}';
          _phase = _Phase.result;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context).live;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.title),
        actions: [TextButton(onPressed: () => context.push('/my/recitations${_studentId == null ? '' : '?s=$_studentId'}'), child: Text(t.mine))],
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
          if (_phase == _Phase.setup || _phase == _Phase.loading) ..._setup(context) else ..._session(context),
          if (_error != null && (_phase == _Phase.setup || _phase == _Phase.loading))
            Padding(padding: const EdgeInsets.only(top: 12), child: MessageBanner(message: _error!)),
        ]),
      ),
      // the controls never scroll out of sight (a long passage pushed them below the screen)
      bottomNavigationBar: _phase == _Phase.setup || _phase == _Phase.loading
          ? null
          : Material(
              elevation: 12,
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      ..._controls(context),
                      if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: MessageBanner(message: _error!)),
                    ]),
                  ),
                ),
              ),
            ),
    );
  }

  List<Widget> _setup(BuildContext context) {
    final t = tr(context).live;
    final count = ayahCount(_surah);
    Widget number(String label, TextEditingController c, void Function(int) set) => Expanded(
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: label),
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null && n >= 1 && n <= count) set(n);
            },
          ),
        );
    return [
      Text(t.hint, style: TextStyle(color: Colors.grey.shade700)),
      const SizedBox(height: 16),
      if (_students.length > 1) ...[
        DropdownButtonFormField<String>(
          initialValue: _studentId,
          isExpanded: true,
          decoration: InputDecoration(labelText: t.student),
          items: [for (final s in _students) DropdownMenuItem(value: s.id, child: Text(s.name))],
          onChanged: (v) => setState(() => _studentId = v),
        ),
        const SizedBox(height: 12),
      ],
      DropdownButtonFormField<int>(
        initialValue: _surah,
        isExpanded: true,
        menuMaxHeight: 420,
        decoration: InputDecoration(labelText: t.surah),
        items: [for (var i = 1; i <= 114; i++) DropdownMenuItem(value: i, child: Text('$i. ${surahName(i)}'))],
        onChanged: (v) => setState(() {
          _surah = v ?? 1;
          final c = ayahCount(_surah);
          _from = _from.clamp(1, c);
          _to = _to.clamp(1, c);
          _fromCtl.text = '$_from';
          _toCtl.text = '$_to';
        }),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _type,
        isExpanded: true,
        decoration: InputDecoration(labelText: t.type),
        items: [for (final k in _types) DropdownMenuItem(value: k, child: Text(tr(context).labels.recitationType[k] ?? k))],
        onChanged: (v) => setState(() => _type = v ?? _type),
      ),
      const SizedBox(height: 12),
      Row(children: [
        number(t.from, _fromCtl, (n) => _from = n),
        const SizedBox(width: 12),
        number(t.to, _toCtl, (n) => _to = n),
      ]),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text('${surahName(_surah)} · ${fmt(tr(context).quran.ayahs, {'n': count})}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ),
      const SizedBox(height: 12),
      TextField(controller: _note, maxLength: 300, decoration: InputDecoration(labelText: t.note, counterText: '')),
      const SizedBox(height: 18),
      FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: _studentId == null || _phase == _Phase.loading ? null : _begin,
        icon: _phase == _Phase.loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.mic_rounded),
        label: Text(_phase == _Phase.loading ? t.loading : t.start),
      ),
      const SizedBox(height: 8),
      Text(_canRecord ? t.appAudio : t.appNoAudio, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black45)),
    ];
  }

  List<Widget> _session(BuildContext context) {
    final t = tr(context).live;
    final m = _m!;
    final r = _range;
    final scheme = Theme.of(context).colorScheme;
    final hidden = TextStyle(color: Colors.transparent, shadows: [
      Shadow(color: _ink.withValues(alpha: 0.5), blurRadius: 9),
      Shadow(color: _ink.withValues(alpha: 0.3), blurRadius: 16),
    ]);
    final wrong = const TextStyle(
      color: Color(0xFFB42318),
      backgroundColor: Color(0xFFFDE7E5),
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.wavy,
      decorationColor: Color(0xFFB42318),
    );
    final spans = <InlineSpan>[];
    for (var k = 0; k < m.words.length; k++) {
      final w = m.words[k];
      final isNext = _phase == _Phase.live && k == m.pos;
      var style = switch (w.state) {
        LiveState.hidden => hidden,
        LiveState.ok => const TextStyle(color: _ink),
        _ => wrong,
      };
      if (isNext) style = style.copyWith(backgroundColor: const Color(0x33F5C04E));
      spans.add(TextSpan(text: w.text, style: style));
      final last = k == m.words.length - 1 || m.words[k + 1].ayah != w.ayah;
      spans.add(TextSpan(text: last ? ' ۝${arabicNumber(w.ayah)} ' : ' ', style: last ? TextStyle(color: scheme.primary) : null));
    }

    return [
      Row(children: [
        Expanded(child: Text('${surahName(_surah)} ${r.from}–${r.to}', style: const TextStyle(fontWeight: FontWeight.w800))),
        if (_phase == _Phase.live && _nativeMode)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: Row(children: [
              Icon(Icons.fiber_manual_record, size: 12, color: Colors.red.shade600),
              const SizedBox(width: 2),
              Text(t.recording, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
            ]),
          ),
        if (_phase == _Phase.live)
          Row(children: [
            Icon(Icons.circle, size: 10, color: _listening ? Colors.green : Colors.grey),
            const SizedBox(width: 4),
            Text(_listening ? t.listening : t.paused, style: TextStyle(fontSize: 12, color: _listening ? Colors.green.shade700 : Colors.grey)),
          ]),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        Text(fmt(t.progress, {'n': m.reached, 'total': m.words.length}), style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(width: 12),
        Text(fmt(t.mistakesN, {'n': m.mistakes}), style: TextStyle(fontSize: 12, color: m.mistakes > 0 ? Colors.red.shade700 : Colors.black54, fontWeight: m.mistakes > 0 ? FontWeight.w700 : null)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: m.words.isEmpty ? 0 : m.reached / m.words.length, minHeight: 6)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(color: const Color(0xFFFFFDF6), border: Border.all(color: const Color(0xFFE7DFC9)), borderRadius: BorderRadius.circular(18)),
        child: Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
          strutStyle: const StrutStyle(fontFamily: 'AmiriQuran', fontSize: 26, height: 2.1, forceStrutHeight: true),
          style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 26, height: 2.1, color: _ink),
        ),
      ),
    ];
  }

  /// Always in sight at the bottom of the screen: the stop, finish-and-send, the result and its send button.
  List<Widget> _controls(BuildContext context) {
    final t = tr(context).live;
    final m = _m!;
    final scheme = Theme.of(context).colorScheme;
    final stopped = _stop == null ? '' : _stop!.at.map((i) => m.words[i].text).join(' ');
    final res = m.result();
    return [
      if (_stop != null)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.red.shade50, border: Border.all(color: Colors.red.shade300, width: 2), borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_stop!.wrong ? t.stopWrong : t.stopMissing, style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red.shade800, fontSize: 16)),
            const SizedBox(height: 4),
            Row(children: [
              Text('${t.correctIs} ', style: TextStyle(color: Colors.red.shade900)),
              Flexible(child: Text(stopped, textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 24, color: Colors.red.shade900))),
            ]),
            if (_stop!.heard != null) Text(fmt(t.heard, {'w': _stop!.heard}), style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: _resume,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(t.resume),
            ),
          ]),
        ),
      if (_phase == _Phase.live && _stop == null)
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => _handle(_m?.forgot()), child: Text(t.forgot))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.icon(onPressed: _finish, icon: const Icon(Icons.stop_rounded), label: Text(t.finish))),
        ]),
      if (_phase == _Phase.sent) ...[
        MessageBanner(message: t.sent, isError: false),
        const SizedBox(height: 8),
      ],
      if (_phase == _Phase.result || _phase == _Phase.sending || _phase == _Phase.sent) ...[
        Row(children: [
          Text(t.result, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 10),
          Text(fmt(t.score, {'n': res['score']}), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: scheme.primary)),
        ]),
        if (m.mistakes > 0) ...[
          const SizedBox(height: 6),
          Text(t.mistakeList, style: const TextStyle(color: Colors.black54)),
          Wrap(spacing: 10, children: [
            for (final w in m.words.where((w) => w.state == LiveState.missing || w.state == LiveState.wrong))
              Text(w.text, textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 20, color: Colors.red.shade700)),
          ]),
        ],
        if (_audio != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.mic_rounded, size: 16, color: scheme.primary),
            const SizedBox(width: 4),
            Text(fmt(t.withAudio, {'t': '${_audio!.seconds ~/ 60}:${(_audio!.seconds % 60).toString().padLeft(2, '0')}'}), style: TextStyle(fontSize: 12, color: scheme.primary)),
          ]),
        ],
        const SizedBox(height: 6),
        Text(t.resultNote, style: const TextStyle(fontSize: 12, color: Colors.black45)),
        const SizedBox(height: 10),
      ],
      if (_phase == _Phase.sending)
        LoadingButton(label: t.sending, icon: Icons.send_rounded, loading: true, onPressed: null),
      if (_phase == _Phase.result)
        Row(children: [
          if (_heard.isNotEmpty) ...[
            Expanded(child: LoadingButton(label: t.retry, icon: Icons.send_rounded, loading: false, onPressed: _send)),
            const SizedBox(width: 10),
          ],
          OutlinedButton.icon(onPressed: _again, icon: const Icon(Icons.replay_rounded), label: Text(t.again)),
        ]),
      if (_phase == _Phase.sent) ...[
        Row(children: [
          Expanded(child: FilledButton(onPressed: _again, child: Text(t.again))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton(onPressed: () => context.push('/my/recitations${_studentId == null ? '' : '?s=$_studentId'}'), child: Text(t.mine))),
        ]),
      ],
    ];
  }
}
