import 'package:bustan_alquran_app/core/widgets/fading_branches.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// The bottom-bar tabs fade in when switched to, keep their state, and the system
// back button on another tab returns to the home tab before it would leave the app.
void main() {
  late GoRouter router;
  Widget page(String name) => Scaffold(body: Center(child: Text(name)));

  setUp(() {
    router = GoRouter(initialLocation: '/dashboard', routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => PopScope(
          canPop: shell.currentIndex == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) shell.goBranch(0);
          },
          child: Scaffold(
            body: shell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: shell.goBranch,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'home'),
                NavigationDestination(icon: Icon(Icons.chat), label: 'chat'),
              ],
            ),
          ),
        ),
        navigatorContainerBuilder: (context, shell, children) => FadingBranches(currentIndex: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (_, _) => page('HOME'))]),
          StatefulShellBranch(routes: [GoRoute(path: '/chat', builder: (_, _) => page('CHAT'))]),
        ],
      ),
    ]);
  });

  testWidgets('only the open tab shows, and switching fades the other in', (t) async {
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('CHAT'), findsNothing);

    await t.tap(find.text('chat'));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('CHAT'), findsOneWidget); // mid-fade
    await t.pumpAndSettle();
    expect(find.text('CHAT'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('back on another tab goes to the home tab', (t) async {
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.tap(find.text('chat'));
    await t.pumpAndSettle();
    expect(find.text('CHAT'), findsOneWidget);

    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('CHAT'), findsNothing);
  });
}
