import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import '../tenant/tenant_controller.dart';

/// Same module list as apps/web's TenantSidebar, trimmed to the ones with a
/// mobile screen so far - add an entry here as each new feature lands.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final org = tenant.active?.organization;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(org?.name ?? 'بستان القرآن', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('لوحة التحكم'),
              onTap: () {
                Navigator.pop(context);
                context.go('/dashboard');
              },
            ),
            if (tenant.hasModule('students'))
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('الطلاب'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/students');
                },
              ),
            if (tenant.hasModule('circles'))
              ListTile(
                leading: const Icon(Icons.groups),
                title: const Text('الحلقات'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/circles');
                },
              ),
            if (tenant.hasModule('attendance'))
              ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text('الحضور'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/attendance');
                },
              ),
            if (tenant.hasModule('serd'))
              ListTile(
                leading: const Icon(Icons.menu_book),
                title: const Text('السرد القرآني'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/serd');
                },
              ),
            if (tenant.hasModule('points'))
              ListTile(
                leading: const Icon(Icons.stars),
                title: const Text('النقاط'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/points');
                },
              ),
            if (tenant.hasModule('badges'))
              ListTile(
                leading: const Icon(Icons.emoji_events),
                title: const Text('الشارات'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/badges');
                },
              ),
            if (tenant.hasModule('market'))
              ListTile(
                leading: const Icon(Icons.storefront),
                title: const Text('سوق النقاط'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/market');
                },
              ),
            if (tenant.hasModule('circle-challenges'))
              ListTile(
                leading: const Icon(Icons.leaderboard),
                title: const Text('منافسات الحلقات'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/circle-challenges');
                },
              ),
            if (tenant.hasMultipleOrganizations)
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('تبديل المركز'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/select-organization');
                },
              ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('تسجيل خروج'),
              onTap: () => context.read<AuthController>().signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
