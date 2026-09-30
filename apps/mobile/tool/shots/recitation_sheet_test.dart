import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bustan_alquran_app/features/recitation/recitation_repository.dart';
import 'package:bustan_alquran_app/features/recitation/recitation_sheet.dart';

import 'harness.dart';

const _grades = [
  GradeOption(key: 'excellent', label: 'ممتاز', points: 10),
  GradeOption(key: 'very_good', label: 'جيد جدًا', points: 7),
  GradeOption(key: 'good', label: 'جيد', points: 5),
  GradeOption(key: 'weak', label: 'يحتاج إعادة', points: 1),
];

Widget _frame(Widget sheet) => Scaffold(
      backgroundColor: Colors.black54,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(padding: const EdgeInsets.only(top: 16), child: sheet),
        ),
      ),
    );

void main() {
  setUpAll(loadFonts);
  testWidgets('recitation sheet, empty', (tester) async {
    await shot(tester, 'recitation_sheet_empty', _frame(const RecitationSheet(studentId: 's', studentName: 'عبدالله محمد الأحمد', grades: _grades)));
  });
  testWidgets('recitation sheet, filled', (tester) async {
    await shot(tester, 'recitation_sheet_filled', _frame(const RecitationSheet(studentId: 's', studentName: 'عبدالله محمد الأحمد', grades: _grades, initialType: 'recent_review', initialSurah: 67)));
    await tester.tap(find.text('ممتاز'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/recitation_sheet_graded.png'));
  });
  testWidgets('recitation sheet, en', (tester) async {
    await shot(tester, 'recitation_sheet_en', _frame(const RecitationSheet(studentId: 's', studentName: 'Abdullah Mohammad', grades: _grades, initialSurah: 36)), lang: 'en');
  });
}
