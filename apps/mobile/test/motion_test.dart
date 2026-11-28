import 'package:bustan_alquran_app/core/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The garden's motion ends where the screen would be without it, cleans up after
// itself, and does not move at all when the device asks for reduced motion.
void main() {
  Widget app(Widget child, {bool reduce = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: Scaffold(body: Center(child: child)),
        ),
      );

  double opacityOf(WidgetTester t, String text) =>
      t.widget<Opacity>(find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first).opacity;

  testWidgets('GrowIn starts hidden and ends fully shown', (t) async {
    await t.pumpWidget(app(const GrowIn(child: Text('leaf'))));
    expect(opacityOf(t, 'leaf'), lessThan(0.2));
    await t.pumpAndSettle();
    expect(opacityOf(t, 'leaf'), 1);
  });

  testWidgets('GrowIn is shown at once with reduced motion', (t) async {
    await t.pumpWidget(app(const GrowIn(delay: Duration(milliseconds: 300), child: Text('leaf')), reduce: true));
    await t.pump();
    expect(opacityOf(t, 'leaf'), 1);
  });

  testWidgets('CountUp grows to its number; other text stays as it is', (t) async {
    await t.pumpWidget(app(const Column(children: [CountUp('42'), CountUp('٣ أيام')])));
    expect(find.text('42'), findsNothing);
    expect(find.text('٣ أيام'), findsOneWidget);
    await t.pumpAndSettle();
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('the leaf burst removes itself, and does not start with reduced motion', (t) async {
    late BuildContext ctx;
    await t.pumpWidget(app(Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    })));
    final before = find.byType(CustomPaint).evaluate().length;
    celebrateWithLeaves(ctx);
    await t.pump();
    expect(find.byType(CustomPaint).evaluate().length, greaterThan(before));
    await t.pump(const Duration(seconds: 2));
    expect(find.byType(CustomPaint).evaluate().length, before);

    await t.pumpWidget(app(Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    }), reduce: true));
    final still = find.byType(CustomPaint).evaluate().length;
    celebrateWithLeaves(ctx);
    await t.pump();
    expect(find.byType(CustomPaint).evaluate().length, still);
  });
}
