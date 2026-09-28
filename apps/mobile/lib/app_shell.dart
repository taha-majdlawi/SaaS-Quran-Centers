import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/i18n/i18n.dart';
import 'core/offline/sync_service.dart';
import 'core/tenant/organization.dart';
import 'core/tenant/tenant_controller.dart';

/// The staff app's tabs, in branch order (the router's StatefulShellRoute uses the same order).
const kShellBranches = ['/dashboard', '/students', '/serd', '/chat', '/more'];

/// Which branches the signed-in member gets as tabs (home and More always).
List<int> visibleShellBranches(TenantController tenant) => [
      0,
      if (tenant.hasModule('students')) 1,
      if (tenant.hasModule('serd')) 2,
      if (tenant.hasModule('chat')) 3,
      4,
    ];

/// The paths that already have a tab (the More hub leaves them out).
Set<String> shellTabPaths(TenantController tenant) => {for (final i in visibleShellBranches(tenant)) kShellBranches[i]};

/// Home / Students / Serd / Messages / More for teachers and admins. Students and
/// guardians have their own portal tabs, so for them (they can still open the
/// chat) the bar is not shown.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final role = tenant.active?.role;
    if (role == null || role == OrgRole.student || role == OrgRole.guardian) return shell;

    final t = tr(context).garden;
    final sync = context.watch<SyncService>();
    final branches = visibleShellBranches(tenant);
    final selected = branches.indexOf(shell.currentIndex).clamp(0, branches.length - 1);
    final waiting = sync.pendingCount + sync.failedCount;

    NavigationDestination dest(int branch) => switch (branch) {
          0 => NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: t.tabHome),
          1 => NavigationDestination(icon: const Icon(Icons.people_alt_outlined), selectedIcon: const Icon(Icons.people_alt_rounded), label: t.tabStudents),
          2 => NavigationDestination(icon: const Icon(Icons.menu_book_outlined), selectedIcon: const Icon(Icons.menu_book_rounded), label: t.tabSerd),
          3 => NavigationDestination(icon: const Icon(Icons.chat_bubble_outline_rounded), selectedIcon: const Icon(Icons.chat_bubble_rounded), label: t.tabChat),
          _ => NavigationDestination(
              icon: Badge(isLabelVisible: waiting > 0, label: Text('$waiting'), child: const Icon(Icons.grid_view_outlined)),
              selectedIcon: Badge(isLabelVisible: waiting > 0, label: Text('$waiting'), child: const Icon(Icons.grid_view_rounded)),
              label: t.tabMore,
            ),
        };

    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Color(0x141B2A22), blurRadius: 16, offset: Offset(0, -4))]),
        child: NavigationBar(
          selectedIndex: selected,
          destinations: [for (final b in branches) dest(b)],
          onDestinationSelected: (i) {
            final branch = branches[i];
            // tapping the open tab again goes back to its first screen
            shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
          },
        ),
      ),
    );
  }
}
