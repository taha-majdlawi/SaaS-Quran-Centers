import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/tenant/tenant_controller.dart';

/// Shown when the signed-in user has zero or more than one active
/// organization membership - picking one sets TenantController.active,
/// which the router then lets through to /dashboard.
class OrgPickerScreen extends StatelessWidget {
  const OrgPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر المركز'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthController>().signOut(),
          ),
        ],
      ),
      body: tenant.loading
          ? const Center(child: CircularProgressIndicator())
          : tenant.memberships.isEmpty
              ? const Center(child: Text('حسابك غير مرتبط بأي مركز بعد'))
              : ListView.builder(
                  itemCount: tenant.memberships.length,
                  itemBuilder: (context, index) {
                    final membership = tenant.memberships[index];
                    return ListTile(
                      title: Text(membership.organization.name),
                      subtitle: Text(membership.role.name),
                      onTap: () => tenant.switchTo(membership),
                    );
                  },
                ),
    );
  }
}
