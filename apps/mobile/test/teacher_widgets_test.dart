import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bustan_alquran_app/core/theme/teacher_style.dart';
import 'package:bustan_alquran_app/features/recitation/recitation_repository.dart';
import 'package:bustan_alquran_app/features/teacher/teacher_widgets.dart';

void main() {
  testWidgets('a student tile renders in RTL at phone width without overflow', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: Scaffold(
        body: Column(children: [
          TeacherStudentTile(
            student: const CircleStudent(id: '1', fullName: 'عبد الرحمن بن محمد بن أحمد الخطيب', studentCode: '01-0007', totalPoints: 120, recitedToday: 2, attendanceToday: 'present'),
            onOpen: () {},
            onRecord: () {},
            onAttendance: (_) {},
          ),
          const StatCard(icon: Icons.mic_rounded, label: 'كل التسميعات', value: '42', color: Colors.teal),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('رصد تسميع'), findsOneWidget);
    expect(find.text('سمّع اليوم ×2'), findsOneWidget);
  });

  test('grade colours follow the rank of the grade', () {
    const grades = [GradeOption(key: 'a', label: 'ممتاز', points: 10), GradeOption(key: 'b', label: 'جيد', points: 6), GradeOption(key: 'c', label: 'مقبول', points: 3), GradeOption(key: 'd', label: 'ضعيف', points: 1)];
    expect(TeacherStyle.gradeColor(grades, 'a'), TeacherStyle.success);
    expect(TeacherStyle.gradeColor(grades, 'd'), TeacherStyle.danger);
    expect(TeacherStyle.gradeColor(grades, null), TeacherStyle.textMuted);
  });
}
