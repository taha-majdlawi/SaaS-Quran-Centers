// Renders widgets to PNGs with the app's real fonts, to look at a design
// without a device:  flutter test tool/shots/<name>_test.dart --update-goldens
// The images land in tool/shots/goldens/ (not committed).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bustan_alquran_app/core/i18n/i18n.dart';
import 'package:bustan_alquran_app/core/theme/app_theme.dart';

Future<void> loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(File(f).readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  }

  await family('Tajawal', [
    'assets/fonts/Tajawal-Regular.ttf',
    'assets/fonts/Tajawal-Medium.ttf',
    'assets/fonts/Tajawal-Bold.ttf',
    'assets/fonts/Tajawal-ExtraBold.ttf',
  ]);
  await family('AmiriQuran', ['assets/fonts/AmiriQuran-Regular.ttf']);
  await family('MaterialIcons', ['/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
}

/// A phone-sized frame (390 x 844 logical pixels) in [lang].
Future<void> shot(WidgetTester tester, String name, Widget child, {String lang = 'ar', double height = 844, Color brand = kDefaultBrandColor}) async {
  final strings = lang == 'en' ? S.en : S.ar;
  currentStrings = strings;
  tester.view.physicalSize = Size(390 * 2, height * 2);
  tester.view.devicePixelRatio = 2;
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(brand),
    home: StringsScope(
      strings: strings,
      child: Directionality(textDirection: strings.isAr ? TextDirection.rtl : TextDirection.ltr, child: child),
    ),
  ));
  await tester.pumpAndSettle();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
  addTearDown(tester.view.reset);
}
