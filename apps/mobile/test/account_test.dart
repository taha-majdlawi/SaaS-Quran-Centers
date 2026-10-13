import 'package:bustan_alquran_app/features/account/account_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a number login has no real email (nothing to mail, nothing to change)', () {
    expect(hasRealEmail('teacher@gmail.com'), isTrue);
    expect(hasRealEmail('12345@alnoor.id.bustan-alquran.com'), isFalse);
    expect(hasRealEmail('12345@ALNOOR.ID.BUSTAN-ALQURAN.COM'), isFalse);
    expect(hasRealEmail(null), isFalse);
    expect(hasRealEmail(''), isFalse);
  });
}
