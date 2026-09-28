import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// The app's navigation shape: tabs in a StatefulShellRoute, every other screen
// a top-level route that opens ABOVE the tabs (no bar), and the family portal
// (outside the shell) able to push the chat tab's screen.
void main() {
  late GoRouter router;
  Widget page(String name) => Scaffold(body: Center(child: Text(name)));

  setUp(() {
    router = GoRouter(initialLocation: '/dashboard', routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Scaffold(
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
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (_, _) => page('HOME'))]),
          StatefulShellBranch(routes: [GoRoute(path: '/chat', builder: (_, _) => page('CHAT'))]),
        ],
      ),
      GoRoute(path: '/students/:id/file', builder: (_, s) => page('FILE ${s.pathParameters['id']}')),
      GoRoute(path: '/my', builder: (_, _) => page('PORTAL')),
    ]);
  });

  testWidgets('a pushed screen covers the bar and comes back to the tab', (t) async {
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('HOME'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await t.tap(find.text('chat'));
    await t.pumpAndSettle();
    expect(find.text('CHAT'), findsOneWidget);

    router.push('/students/s1/file');
    await t.pumpAndSettle();
    expect(find.text('FILE s1'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    router.pop();
    await t.pumpAndSettle();
    expect(find.text('CHAT'), findsOneWidget); // the tab kept its place
  });

  testWidgets('the portal can open the chat and go back', (t) async {
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/my');
    await t.pumpAndSettle();
    router.push('/chat');
    await t.pumpAndSettle();
    expect(find.text('CHAT'), findsOneWidget);
    router.pop();
    await t.pumpAndSettle();
    expect(find.text('PORTAL'), findsOneWidget);
  });
}
