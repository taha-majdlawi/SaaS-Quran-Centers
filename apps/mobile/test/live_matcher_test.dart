import 'package:flutter_test/flutter_test.dart';
import 'package:bustan_alquran_app/features/quran/live_matcher.dart';

// al-Ikhlas as the mushaf writes it
const ikhlas = [
  (1, 'قُلۡ هُوَ ٱللَّهُ أَحَدٌ'),
  (2, 'ٱللَّهُ ٱلصَّمَدُ'),
  (3, 'لَمۡ يَلِدۡ وَلَمۡ يُولَدۡ'),
  (4, 'وَلَمۡ يَكُن لَّهُۥ كُفُوًا أَحَدُۢ'),
];

List<LiveEvent?> feedAll(LiveMatcher m, String text) => [for (final w in text.split(' ')) m.feed(w)];

void main() {
  test('a correct recitation uncovers every word; the basmala before it is ignored', () {
    final m = LiveMatcher(ikhlas);
    final events = feedAll(m, 'بسم الله الرحمن الرحيم قل هو الله أحد الله الصمد لم يلد ولم يولد ولم يكن له كفوا أحد');
    expect(m.mistakes, 0);
    expect(m.done, isTrue);
    expect(events.whereType<LiveEvent>().last.done, isTrue);
    expect(m.result()['score'], 100);
  });

  test('a skipped word is missing, a different one wrong with what was heard', () {
    final m = LiveMatcher(ikhlas);
    feedAll(m, 'قل هو الله أحد الله لم');
    expect(m.words[5].state, LiveState.missing);
    final w = LiveMatcher(ikhlas);
    feedAll(w, 'قل هو الله الكريم الله');
    expect(w.words[3].state, LiveState.wrong);
    expect(w.words[3].heard, 'الكريم');
  });

  test('settle, forgot and finish', () {
    final m = LiveMatcher(ikhlas);
    feedAll(m, 'قل هو الله أحد الله الكريم');
    expect(m.pending, isTrue);
    expect(m.settle()?.mistake?.wrong, isTrue);
    m.forgot();
    expect(m.words[6].state, LiveState.missing);
    m.finish();
    expect((m.result()['words'] as List).every((w) => w['s'] != 'hidden'), isTrue);
  });

  test('a repeat is not a mistake; only settled words are used', () {
    final m = LiveMatcher(ikhlas);
    feedAll(m, 'قل هو هو الله');
    expect(m.mistakes, 0);
    expect(stableWords('قل هو الله أح', isFinal: false), ['قل', 'هو', 'الله']);
  });

  test('al-Fatiha: الرحيم right after الرحمن is not taken for a repeat of it', () {
    const fatiha = [
      (1, 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ'),
      (2, 'ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ'),
      (3, 'ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ'),
      (4, 'مَٰلِكِ يَوۡمِ ٱلدِّينِ'),
    ];
    final m = LiveMatcher(fatiha);
    feedAll(m, 'بسم الله الرحمن الرحيم الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين');
    expect(m.mistakes, 0);
    expect(m.done, isTrue);
    final r = LiveMatcher(fatiha);
    feedAll(r, 'بسم الله الرحمن الرحمن الرحيم الحمد لله رب العالمين');
    expect(r.mistakes, 0);
  });

  test('the expected word is recognised early, the last word of an ayah a little more loosely', () {
    final m = LiveMatcher(ikhlas);
    feedAll(m, 'قل هو الله');
    expect(m.expects('أحد'), isTrue);
    expect(m.expects('الصمد'), isFalse);
    final f = LiveMatcher([(5, 'إِيَّاكَ نَعۡبُدُ وَإِيَّاكَ نَسۡتَعِينُ')]);
    feedAll(f, 'إياك نعبد وإياك');
    expect(f.expects('تستعي', loose: true), isTrue); // the end swallowed at the stop
    expect(f.expects('تستعي'), isFalse);
  });
}
