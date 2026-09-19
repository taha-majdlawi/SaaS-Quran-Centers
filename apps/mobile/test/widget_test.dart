import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bustan_alquran_app/core/theme/app_theme.dart';

void main() {
  test('parseBrandColor reads #rrggbb and falls back to the default teal', () {
    expect(parseBrandColor('#00346b'), const Color(0xFF00346B));
    expect(parseBrandColor('bad'), kDefaultBrandColor);
    expect(parseBrandColor(null), kDefaultBrandColor);
  });
}
