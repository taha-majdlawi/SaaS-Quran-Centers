import 'package:bustan_alquran_app/core/data/quran_data.dart';
import 'package:bustan_alquran_app/core/i18n/i18n.dart';
import 'package:bustan_alquran_app/core/tenant/organization.dart';
import 'package:bustan_alquran_app/features/my_portal/record_extras.dart';
import 'package:bustan_alquran_app/features/serd/serd_models.dart';
import 'package:bustan_alquran_app/features/serd/serd_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => currentStrings = S.ar);

  test('fmt fills placeholders and leaves unknown ones', () {
    expect(fmt('مرحبًا، {name}', {'name': 'سالم'}), 'مرحبًا، سالم');
    expect(fmt('{a} of {b}', {'a': 3}), '3 of {b}');
  });

  test('only students and guardians get their chosen language', () async {
    final c = LocaleController.instance;
    await c.choose('en');
    expect(c.effective(OrgRole.student), 'en');
    expect(c.effective(OrgRole.guardian), 'en');
    expect(c.effective(OrgRole.teacher), 'ar');
    expect(c.effective(OrgRole.admin), 'ar');
    expect(c.effective(null), 'ar');
    await c.choose('ar');
    expect(c.effective(OrgRole.student), 'ar');
  });

  test('every label map has the same keys in every language', () {
    final ar = S.ar.labels, en = S.en.labels;
    for (final pair in [
      (ar.recitationType, en.recitationType),
      (ar.attendance, en.attendance),
      (ar.rule, en.rule),
      (ar.registration, en.registration),
      (ar.certKind, en.certKind),
    ]) {
      expect(pair.$2.keys.toSet(), pair.$1.keys.toSet());
    }
    expect(en.months.length, 12);
    expect(en.weekdays.length, 7);
  });

  test('names follow the current language; staff wording is unchanged in Arabic', () {
    expect(surahName(18), 'الكهف');
    expect(const SerdPart(juz: 3, den: 2, index: 1, juzName: 'تلك الرسل').label, 'جزء 3 — تلك الرسل (النصف الأول)');

    currentStrings = S.en;
    expect(surahName(18), 'Al-Kahf');
    expect(surahNameArabic(18), 'الكهف');
    expect(const SerdPart(juz: 3, den: 2, index: 1, juzName: 'تلك الرسل').label, 'Juz 3 (1st half)');
  });

  testWidgets('portal pieces render in English, left to right', (tester) async {
    currentStrings = S.en;
    await tester.pumpWidget(MaterialApp(
      home: StringsScope(
        strings: S.en,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: Column(children: [
              MonthlySummaryCard(recitations: 3, ayahs: 20, attendanceRate: 0.5, points: 40),
              SerdSummaryCard(summary: null),
              AttendanceListSection(rows: []),
            ]),
          ),
        ),
      ),
    ));
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('No approved serd yet'), findsOneWidget);
    expect(find.text('No attendance records yet'), findsOneWidget);
  });
}
