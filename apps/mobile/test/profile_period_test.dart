import 'package:flutter_test/flutter_test.dart';

import 'package:bustan_alquran_app/features/profiles/profiles_repository.dart';

void main() {
  // the same cases as the web's previousRange
  ProfilePeriod p(String from, String to) => ProfilePeriod('x', DateTime.parse(from), DateTime.parse(to));
  String prev(String from, String to) {
    final q = p(from, to).previous;
    return '${q.fromIso}..${q.toIso}';
  }

  test('a period from the 1st compares with the same days of the month before', () {
    expect(prev('2026-09-01', '2026-09-30'), '2026-08-01..2026-08-31');
    expect(prev('2026-10-01', '2026-10-15'), '2026-09-01..2026-09-15');
    expect(prev('2026-03-01', '2026-03-31'), '2026-02-01..2026-02-28');
    expect(prev('2026-03-01', '2026-03-30'), '2026-02-01..2026-02-28');
    expect(prev('2026-01-01', '2026-01-31'), '2025-12-01..2025-12-31');
  });

  test('any other period compares with the same number of days just before', () {
    expect(prev('2026-09-10', '2026-09-19'), '2026-08-31..2026-09-09');
    expect(prev('2026-02-01', '2026-03-15'), '2025-12-20..2026-01-31');
  });

  test('the presets', () {
    final now = DateTime(2026, 9, 30, 15);
    expect(ProfilePeriod.of('month', now).fromIso, '2026-09-01');
    expect(ProfilePeriod.of('month', now).toIso, '2026-09-30');
    expect(ProfilePeriod.of('last_month', now).fromIso, '2026-08-01');
    expect(ProfilePeriod.of('last_month', now).toIso, '2026-08-31');
    expect(ProfilePeriod.of('90', now).fromIso, '2026-07-03');
  });
}
