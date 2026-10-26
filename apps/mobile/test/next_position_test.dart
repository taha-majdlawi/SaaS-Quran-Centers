import 'package:bustan_alquran_app/features/recitation/next_position.dart';
import 'package:flutter_test/flutter_test.dart';

MemorizedPart p(int s, int from, int to) => MemorizedPart(surah: s, ayahFrom: from, ayahTo: to);

void main() {
  test('nothing yet', () => expect(nextPosition([]), isNull));

  test('stopped in the middle: the same surah, the next ayah', () {
    final n = nextPosition([p(78, 1, 20)])!; // An-Naba has 40
    expect(n.finishedSurah, isFalse);
    expect(n.surah, 78);
    expect(n.ayahFrom, 21);
  });

  test('finished a surah, going down from An-Nas: the one before it', () {
    final n = nextPosition([p(112, 1, 4), p(113, 1, 5)])!;
    expect(n.finishedSurah, isTrue);
    expect(n.lastSurah, 112);
    expect(n.surah, 111);
    expect(n.ayahFrom, 1);
  });

  test('finished one surah only: from the end of the mushaf by default', () {
    expect(nextPosition([p(114, 1, 6)])!.surah, 113);
  });

  test('memorising from the start: the one after it', () {
    final n = nextPosition([p(3, 1, 200), p(2, 1, 286)])!;
    expect(n.surah, 4);
  });

  test('several recitations of the same surah are one step', () {
    expect(nextPosition([p(67, 16, 30), p(67, 1, 15), p(68, 1, 52)])!.surah, 66);
  });

  test('the whole Quran done', () {
    final n = nextPosition([p(1, 1, 7), p(2, 1, 286)])!;
    expect(n.finishedSurah, isTrue);
    expect(n.surah, isNull);
  });
}
