// Following a live recitation word by word - the same logic as the website's
// apps/web/src/lib/quran/live-recite.ts (and its word comparison, recite.ts):
//
//   * the expected word -> uncovered, next one;
//   * a word a little further on -> the words in between were skipped
//     ("missing"), or said differently when something else was heard first ("wrong");
//   * two unexpected words in a row, or one that nothing follows (settle) -> wrong;
//   * repeating the word just said, the isti'adha / basmala before the first word,
//     a word the recogniser split in two -> no mistake;
//   * going back to read again - from the start of the ayah (or the one before), or a few
//     words back, after a stop (waqf) or to correct a word -> followed quietly word by word
//     until the student is back where they were; a word corrected this way is no mistake;
//   * a long silence on a word (forgot) -> missing.

final _marks = RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]');

/// Letters only, the hamza forms folded, no vowels or Quranic marks.
String plainWord(String w) => w
    .replaceAll(_marks, '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .replaceAll('ء', '')
    .replaceAll(RegExp('[^ء-ي]'), '');

String _skeleton(String w) => w.replaceAll(RegExp('[اوي]'), '');

int _distance(String a, String b) {
  if (a == b) return 0;
  final prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    var diag = prev[0];
    prev[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final up = prev[j];
      final c = diag + (a[i - 1] == b[j - 1] ? 0 : 1);
      prev[j] = [prev[j] + 1, prev[j - 1] + 1, c].reduce((x, y) => x < y ? x : y);
      diag = up;
    }
  }
  return prev[b.length];
}

/// Same word, only the long vowels apart (written small or not at all in the mushaf).
bool exactWord(String a, String b) => a.isNotEmpty && (a == b || _skeleton(a) == _skeleton(b));

/// Same word, allowing the spelling differences between the mushaf and speech recognition.
/// [slack]: one more letter allowed (the last word of an ayah - see LiveMatcher._matches).
bool sameWord(String expected, String heard, {int slack = 0}) {
  if (expected.isEmpty || heard.isEmpty) return false;
  if (expected == heard) return true;
  final se = _skeleton(expected), sh = _skeleton(heard);
  if (se == sh && se.isNotEmpty) return true;
  final long = se.length > sh.length ? se.length : sh.length;
  if (long < 3) return false;
  final allowed = (long ~/ 4 < 1 ? 1 : long ~/ 4) + (long >= 5 ? slack : 0);
  return _distance(se, sh) <= allowed;
}

/// The passage's words as speech recognition writes them, to bias the recogniser towards them
/// (Android 13+, RecognizerIntent.EXTRA_BIASING_STRINGS - see LiveSpeech.kt): the ayahs, then
/// each word. The mushaf's script is turned into the usual spelling where it differs (a small
/// alif written in full: ٱلۡعَٰلَمِينَ -> العالمين, except in the words that keep it small:
/// الرحمن, هذا, ذلك...); both spellings are given when they differ.
List<String> biasPhrases(List<(int, String)> ayahs, {int max = 400}) {
  String plain(String w) => w.replaceAll(_marks, '').replaceAll('ٱ', 'ا');
  String usual(String w) {
    var u = w
        .replaceAll(RegExp('ىٰ'), 'ى') // عَلَىٰ -> على
        .replaceAll(RegExp('وٰ'), 'ا') // ٱلصَّلَوٰةَ -> الصلاة
        .replaceAll('ٰ', 'ا');
    u = plain(u);
    const keep = {
      'الرحمان': 'الرحمن', 'هاذا': 'هذا', 'هاذه': 'هذه', 'هاذان': 'هذان', 'ذالك': 'ذلك', 'ذالكم': 'ذلكم',
      'لاكن': 'لكن', 'أولائك': 'أولئك', 'إلاه': 'إله', 'إلاها': 'إلها',
    };
    for (final e in keep.entries) {
      u = u.replaceAll(e.key, e.value);
    }
    return u;
  }

  final out = <String>{};
  for (final (_, text) in ayahs) {
    final words = text.split(RegExp(r'\s+')).where((w) => plainWord(w).isNotEmpty).toList();
    out.add(words.map(usual).join(' '));
  }
  for (final (_, text) in ayahs) {
    for (final w in text.split(RegExp(r'\s+'))) {
      if (plainWord(w).isEmpty) continue;
      out.add(usual(w));
      out.add(plain(w));
    }
  }
  return out.where((e) => e.isNotEmpty).take(max).toList();
}

enum LiveState { hidden, ok, missing, wrong }

class LiveWord {
  LiveWord(this.ayah, this.index, this.text) : plain = plainWord(text);
  final int ayah, index;
  final String text, plain;
  bool last = false; // the ayah's last word
  LiveState state = LiveState.hidden;
  String? heard;
}

class LiveMistake {
  const LiveMistake(this.wrong, this.at, this.heard);
  final bool wrong;
  final List<int> at;
  final String? heard;
}

/// What a heard word did: null (nothing to show), progress, done, or a mistake.
class LiveEvent {
  const LiveEvent.progress() : mistake = null, done = false;
  const LiveEvent.done() : mistake = null, done = true;
  const LiveEvent.mistake(LiveMistake this.mistake) : done = false;
  final LiveMistake? mistake;
  final bool done;
}

class LiveMatcher {
  LiveMatcher(List<(int, String)> ayahs) {
    for (final (n, text) in ayahs) {
      var i = 0;
      for (final m in RegExp(r'\S+').allMatches(text)) {
        final w = LiveWord(n, i++, m.group(0)!);
        if (w.plain.isNotEmpty) words.add(w);
      }
      if (words.isNotEmpty && words.last.ayah == n) words.last.last = true;
    }
  }

  static const _lookAhead = 3;
  static const _backWords = 8; // how far back a re-reading may start when not from the start of an ayah
  final words = <LiveWord>[];
  int pos = 0;
  final _unmatched = <String>[];
  int? _rewind; // reading again: the next word of the re-reading (null = not re-reading)
  final _replayed = <String>[]; // the words heard since the re-reading started

  /// The word being read now: the expected one, or the one reached while reading again.
  int get cursor => _rewind ?? pos;

  bool get done => pos >= words.length;
  int get mistakes => words.where((w) => w.state == LiveState.missing || w.state == LiveState.wrong).length;
  int get reached => words.where((w) => w.state != LiveState.hidden).length;
  bool get pending => pos > 0 && _unmatched.isNotEmpty;

  bool _matches(int k, String w) {
    if (k >= words.length) return false;
    final exp = words[k].plain;
    // the ayah's last word, the one expected now: the voice drops at the stop (waqf) and the
    // recogniser hears it less clearly - one more letter is allowed
    final slack = k == pos && words[k].last ? 1 : 0;
    return sameWord(exp, w, slack: slack) || (_unmatched.isNotEmpty && sameWord(exp, _unmatched.last + w, slack: slack));
  }

  /// Is this the word expected now? (exactly, or [loose]ly). The screen uses it to take the
  /// last word of a partial result at once instead of waiting for the recogniser to confirm it.
  bool expects(String raw, {bool loose = false}) {
    final w = plainWord(raw);
    if (done || w.isEmpty) return false;
    if (_rewind != null && exactWord(words[_rewind!].plain, w)) return true;
    return exactWord(words[pos].plain, w) || (loose && _matches(pos, w));
  }

  int _ayahStart(int k) {
    var s = k;
    while (s > 0 && words[s - 1].ayah == words[k].ayah) {
      s--;
    }
    return s;
  }

  /// Where the student went back to, if this word is an earlier one: the start of the current
  /// ayah or of the one before (the usual places to start again - waqf and ibtida'), or, exactly,
  /// a word a little way back.
  int? _backTo(String w, {required bool startsOnly}) {
    if (pos < 2) return null;
    final cur = _ayahStart(pos - 1);
    final from = cur > 0 ? _ayahStart(cur - 1) : 0;
    for (var j = pos - 2; j >= from; j--) {
      final start = j == 0 || words[j - 1].ayah != words[j].ayah;
      if (startsOnly ? start && sameWord(words[j].plain, w) : j >= pos - _backWords && exactWord(words[j].plain, w)) return j;
    }
    return null;
  }

  LiveEvent _startRewind(int j, String w) {
    _unmatched.clear(); // a word said wrong and then corrected by reading again
    _replayed
      ..clear()
      ..add(w);
    _rewind = j + 1 < pos ? j + 1 : null;
    return const LiveEvent.progress();
  }

  LiveEvent _advanceTo(int k) {
    words[k].state = LiveState.ok;
    pos = k + 1;
    _unmatched.clear();
    _rewind = null;
    return done ? const LiveEvent.done() : const LiveEvent.progress();
  }

  LiveEvent _wrongHere() {
    final heard = _unmatched.join(' ');
    words[pos]
      ..state = LiveState.wrong
      ..heard = heard;
    final at = [pos];
    pos += 1;
    _unmatched.clear();
    return LiveEvent.mistake(LiveMistake(true, at, heard));
  }

  LiveEvent? feed(String raw) {
    final w = plainWord(raw);
    if (w.isEmpty || done) return null;

    // reading again: following it until the student is back where they were
    final r = _rewind;
    if (r != null) {
      if (sameWord(words[r].plain, w)) {
        _replayed.add(w);
        _rewind = r + 1 < pos ? r + 1 : null;
        return const LiveEvent.progress();
      }
      if (r > 0 && exactWord(words[r - 1].plain, w)) return null; // a repeat while reading again
      // left the re-reading: one word only was not a re-reading after all, it is judged at the current word
      final lone = _replayed.length == 1 ? _replayed.first : null;
      _rewind = null;
      _replayed.clear();
      if (lone != null && !exactWord(words[pos].plain, w) && !_matches(pos, w)) _unmatched.add(lone);
    }

    // the word expected, said exactly; else repeating the word just said; then the looser match
    // (الرحمن / الرحيم are one letter apart: the loose match alone took one for the other)
    final repeat = pos > 0 && _unmatched.isEmpty;
    if (pos < words.length && exactWord(words[pos].plain, w)) return _advanceTo(pos);
    if (repeat && exactWord(words[pos - 1].plain, w)) return null;
    if (_matches(pos, w)) return _advanceTo(pos);
    if (repeat && sameWord(words[pos - 1].plain, w)) return null;
    // back to the start of the ayah (or the one before)
    final start = _backTo(w, startsOnly: true);
    if (start != null) return _startRewind(start, w);
    // (not before the first word: the basmala's words appear in the ayahs too)
    for (var k = 1; pos > 0 && k <= _lookAhead && pos + k < words.length; k++) {
      if (!_matches(pos + k, w)) continue;
      final at = [for (var j = 0; j < k; j++) pos + j];
      final wrong = _unmatched.isNotEmpty;
      final heard = wrong ? _unmatched.join(' ') : null;
      for (var j = 0; j < at.length; j++) {
        words[at[j]].state = wrong ? LiveState.wrong : LiveState.missing;
        if (j == 0 && heard != null) words[at[j]].heard = heard;
      }
      _advanceTo(pos + k);
      return LiveEvent.mistake(LiveMistake(wrong, at, heard));
    }
    // a few words back
    final back = _backTo(w, startsOnly: false);
    if (back != null) return _startRewind(back, w);
    if (pos == 0) {
      // the isti'adha, the basmala, a cough... before the first word
      _unmatched
        ..clear()
        ..add(w);
      return null;
    }
    _unmatched.add(w);
    return _unmatched.length < 2 ? null : _wrongHere();
  }

  /// An unexpected word that nothing followed: the current word was said wrong.
  LiveEvent? settle() => pending && !done ? _wrongHere() : null;

  /// Stuck on the current word (a long silence, or "I don't remember").
  LiveEvent? forgot() {
    if (done) return null;
    final at = [pos];
    words[pos].state = LiveState.missing;
    pos += 1;
    _unmatched.clear();
    _rewind = null;
    return LiveEvent.mistake(LiveMistake(false, at, null));
  }

  /// Ending early: what was not reached counts as missing.
  void finish() {
    for (final w in words) {
      if (w.state == LiveState.hidden) w.state = LiveState.missing;
    }
    pos = words.length;
    _rewind = null;
  }

  /// What is sent with the recitation (submit_live_recitation, 0087).
  Map<String, dynamic> result() {
    final list = [
      for (final w in words)
        {
          'a': w.ayah,
          'i': w.index,
          's': w.state == LiveState.hidden ? 'missing' : w.state.name,
          if (w.heard != null) 'h': w.heard,
        },
    ];
    final ok = list.where((w) => w['s'] == 'ok').length;
    return {'words': list, 'total': list.length, 'ok': ok, 'score': list.isEmpty ? 0 : (ok * 1000 / list.length).round() / 10};
  }
}

/// Words of a recognition session that will not change any more (the last one of a partial result may).
List<String> stableWords(String recognized, {required bool isFinal}) {
  final ws = recognized.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  return isFinal || ws.isEmpty ? ws : ws.sublist(0, ws.length - 1);
}
