import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/org_avatar.dart';
import '../../core/widgets/ui.dart';
import '../../core/i18n/i18n.dart';

Map<String, String> get _roleLabels => currentStrings.labels.roles;

/// Shown when the signed-in user has zero or more than one active center -
/// picking one sets TenantController.active and continues to the app.
class OrgPickerScreen extends StatelessWidget {
  const OrgPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context).auth.pickCenter),
        actions: [
          IconButton(
            tooltip: tr(context).common.signOut,
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthController>().signOut(),
          ),
        ],
      ),
      body: tenant.loading
          ? const Center(child: CircularProgressIndicator())
          : tenant.loadFailed
              ? ErrorState(onRetry: tenant.loadMemberships)
              : tenant.memberships.isEmpty
                  ? EmptyState(
                      icon: Icons.location_city_outlined,
                      title: tr(context).auth.noCenters,
                      subtitle: tr(context).auth.noCentersHint,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: tenant.memberships.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final membership = tenant.memberships[index];
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            leading: OrgAvatar(
                              name: membership.organization.name,
                              logoUrl: membership.organization.logoUrl,
                              brandColor: membership.organization.primaryColor,
                              size: 46,
                            ),
                            title: Text(membership.organization.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(_roleLabels[membership.role.name] ?? ''),
                            ),
                            trailing: const Icon(Icons.chevron_left_rounded),
                            onTap: () async {
                              await tenant.switchTo(membership);
                              if (context.mounted) context.go('/dashboard');
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
