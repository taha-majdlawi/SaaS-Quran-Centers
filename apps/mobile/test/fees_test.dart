import 'package:bustan_alquran_app/features/fees/fees_screens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feeMoney drops trailing zeros and puts the currency after', () {
    expect(feeMoney(15, 'JD'), '15 JD');
    expect(feeMoney(12.5, 'JD'), '12.5 JD');
    expect(feeMoney('7.25', ''), '7.25');
    expect(feeMoney(null, '₪'), '0 ₪');
  });
}
