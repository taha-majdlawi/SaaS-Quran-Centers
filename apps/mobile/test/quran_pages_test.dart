import 'package:bustan_alquran_app/core/data/quran_pages.dart';
import 'package:flutter_test/flutter_test.dart';

// The same examples as the points spec and supabase/tests (0096's recitation_pages).
void main() {
  double r(double v) => (v * 100).round() / 100;
  test('604 pages, ending at ayah 6236', () {
    expect(kPageFirstAyah.length, 604);
    expect(ayahId(114, 6), 6236);
  });
  test('Al-Fatiha is one page', () => expect(r(recitationPages(1, 1, 7)), 1.0));
  test('Al-Baqara 1-5 is page 2', () => expect(r(recitationPages(2, 1, 5)), 1.0));
  test('Al-Ikhlas ~ 0.27', () => expect(r(recitationPages(112, 1, 4)), 0.27));
  test('Nuh ~ 1.67', () => expect(r(recitationPages(71, 1, 28)), 1.67));
  test('points: page x grade x factor, at least 1, 0 for a worthless grade', () {
    expect(estimatePagePoints(pages: 1, gradePoints: 10, type: 'new_memorization'), 10);
    expect(estimatePagePoints(pages: 1, gradePoints: 10, type: 'recent_review'), 5);
    expect(estimatePagePoints(pages: recitationPages(71, 1, 28), gradePoints: 5, type: 'new_memorization'), 8);
    expect(estimatePagePoints(pages: recitationPages(112, 1, 4), gradePoints: 10, type: 'new_memorization'), 3);
    expect(estimatePagePoints(pages: recitationPages(112, 1, 4), gradePoints: 5, type: 'distant_review'), 1);
    expect(estimatePagePoints(pages: 1, gradePoints: 0, type: 'new_memorization'), 0);
  });
}
