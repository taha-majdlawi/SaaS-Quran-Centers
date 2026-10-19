import 'package:bustan_alquran_app/core/utils/national_id.dart';
import 'package:flutter_test/flutter_test.dart';

// Same cases as apps/web/src/lib/auth/national-id.test.ts.
void main() {
  test('digits in any script, spaces and dashes', () {
    expect(normalizeNationalId('123456789'), '123456789');
    expect(normalizeNationalId('١٢٣٤٥٦٧٨٩'), '123456789');
    expect(normalizeNationalId('۱۲۳ ۴۵۶-۷۸۹'), '123456789');
    expect(normalizeNationalId(' ab-12 34 '), 'AB1234');
  });
  test('not an ID', () {
    for (final v in ['', '12', 'x' * 21, 'abc@d.com', '12;drop', 'رقم1234', null]) {
      expect(normalizeNationalId(v), isNull, reason: '$v');
    }
  });
}
