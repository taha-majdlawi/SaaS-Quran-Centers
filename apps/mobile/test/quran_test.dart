import 'package:bustan_alquran_app/features/quran/mushaf_page_view.dart';
import 'package:bustan_alquran_app/features/quran/quran_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Ayah _a(int n, int page, [String text = 'كلمة اخرى ثالثة']) => Ayah(number: n, text: text, juz: 1, page: page);

void main() {
  test('stripBasmala removes the glued basmala but not from al-Fatiha', () {
    expect(stripBasmala(2, 1, 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ الٓمٓ'), 'الٓمٓ');
    expect(stripBasmala(1, 1, 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'), 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ');
    expect(stripBasmala(2, 2, 'ذَٰلِكَ'), 'ذَٰلِكَ');
  });

  test('toPages starts a new page whenever the Madinah page changes', () {
    final pages = toPages([_a(1, 2), _a(2, 2), _a(3, 3)]);
    expect(pages.map((p) => p.page), [2, 3]);
    expect(pages.first.ayahs.length, 2);
  });

  test('wordIndexAt keeps the last started word lit between words', () {
    const segs = [
      [0, 1, 0, 400],
      [1, 2, 450, 900],
      [2, 3, 900, 1500],
    ];
    expect(wordIndexAt(segs, 0), 0);
    expect(wordIndexAt(segs, 420), 0);
    expect(wordIndexAt(segs, 450), 1);
    expect(wordIndexAt(segs, 9000), 2);
    expect(wordIndexAt(null, 10), -1);
    expect(timingsFit('أ ب ج', segs), isTrue);
    expect(timingsFit('أ ب', segs), isFalse);
  });

  test('normalizeArabic folds hamza forms for the surah search', () {
    expect(normalizeArabic('الأعراف'), normalizeArabic('الاعراف'));
    expect(normalizeArabic('الإسراء').contains(normalizeArabic('الاسراء')), isTrue);
  });

  test('reciters: list or {reciters: list}, https only; url per ayah', () {
    final list = parseReciters({
      'reciters': [
        {'id': 7, 'name_ar': 'ق', 'base': 'https://a/x'},
        {'id': 'bad', 'base': 'http://insecure/'},
      ],
    });
    expect(list.length, 1);
    expect(list.first.ayahUrl(96, 1), 'https://a/x/096001.mp3');
    final center = centerReciters(kBuiltinReciters, 'Husary_128kbps,Alafasy_128kbps', 'Husary_128kbps');
    expect(center.map((r) => r.id), ['Husary_128kbps', 'Alafasy_128kbps']);
  });

  test('parseSurahFile reads the eqraa layout', () {
    final d = parseSurahFile(1, {
      'revelation_place': {'ar': 'مكية'},
      'verses': [
        {'number': 1, 'text': {'ar': 'بِسْمِ'}, 'juz': 1, 'page': 1, 'sajda': false},
        {'number': 2, 'text': {'ar': 'ٱلْحَمْدُ'}, 'juz': 1, 'page': 1, 'sajda': {'obligatory': true}},
      ],
      'audio': [
        {'reciter': {'ar': 'ق'}, 'rewaya': {'ar': 'حفص'}, 'link': 'https://x/1.mp3'},
      ],
    });
    expect(d.place, 'مكية');
    expect(d.ayahs[1].sajdaObligatory, isTrue);
    expect(d.audio.single.link, 'https://x/1.mp3');
  });

  testWidgets('a page renders hidden, lit and word-by-word ayahs', (tester) async {
    final page = toPages([_a(1, 1), _a(2, 1), _a(3, 1, 'أ ب')]).first;
    var tapped = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MushafPageView(
            page: page,
            surahName: 'الفاتحة',
            isFirst: true,
            hasBasmala: false,
            place: 'مكية',
            ayahCount: 3,
            fontSize: kMushafSizes[1],
            current: 2,
            word: 1,
            wordFits: (n) => n == 2,
            isRevealed: (n) => n != 3,
            testMode: true,
            bookmarks: const {1},
            onAyahTap: (n) => tapped = n,
            onTogglePage: () {},
          ),
        ),
      ),
    ));
    expect(find.textContaining('الجزء'), findsOneWidget);
    expect(find.textContaining('آياتها'), findsOneWidget);
    expect(tapped, 0);
  });
}
