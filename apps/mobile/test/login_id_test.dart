import 'package:flutter_test/flutter_test.dart';
import 'package:bustan_alquran_app/features/auth/login_repository.dart';

// Mirrors apps/web/src/lib/accounts/login-id.test.ts: a number in any digits is the same account.
void main() {
  test('a number in any digits is the same account', () {
    expect(toLoginEmail('noor', '123'), '123@noor.id.bustan-alquran.com');
    expect(toLoginEmail('Noor ', ' ١٢٣ '), '123@noor.id.bustan-alquran.com');
    expect(toLoginEmail('noor', '۱۲۳'), '123@noor.id.bustan-alquran.com');
  });

  test('an email is used as typed, in lower case', () {
    expect(toLoginEmail('noor', ' Teacher@Mail.COM '), 'teacher@mail.com');
  });

  test('the old address only when Arabic digits were typed', () {
    expect(legacyLoginEmail('noor', '123'), isNull);
    expect(legacyLoginEmail('noor', 'a@b.co'), isNull);
    expect(legacyLoginEmail('noor', '١٢٣'), '١٢٣@noor.id.bustan-alquran.com');
  });
}
