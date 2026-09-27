import 'package:bustan_alquran_app/core/access/account_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> access({Map<String, dynamic>? usage, Map<String, dynamic>? billing}) =>
      {'is_read_only': false, 'usage': usage, 'billing': billing};

  test('students and guardians (no usage) never get plan warnings', () {
    expect(planWarningsFrom(access(billing: {'enforced': true, 'state': 'trial', 'kind': 'trial', 'days_left': 2})), isEmpty);
  });

  test('capacity: few students left, teachers full', () {
    final w = planWarningsFrom(access(usage: {'students_left': 3, 'max_students': 100, 'teachers_left': 0, 'max_teachers': 8}));
    expect(w.map((e) => e.text), ['تبقى 3 طلاب يمكن إضافتهم ضمن الخطة', 'وصل المركز للحد الأقصى من المعلمين (8)']);
    expect(w.last.urgent, isTrue);
  });

  test('expiry only while enforced, and only within 7 days', () {
    final u = {'students_left': null, 'teachers_left': null};
    expect(planWarningsFrom(access(usage: u, billing: {'enforced': false, 'state': 'trial', 'kind': 'trial', 'days_left': 2})), isEmpty);
    expect(planWarningsFrom(access(usage: u, billing: {'enforced': true, 'state': 'active', 'kind': 'paid', 'days_left': 20})), isEmpty);
    final w = planWarningsFrom(access(usage: u, billing: {'enforced': true, 'state': 'trial', 'kind': 'trial', 'days_left': 1}));
    expect(w.single.text, 'تنتهي الفترة التجريبية خلال يوم واحد');
  });
}
