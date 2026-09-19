import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';

const _roleLabels = {
  OrgRole.admin: 'مدير',
  OrgRole.teacher: 'معلم',
  OrgRole.guardian: 'ولي أمر',
  OrgRole.student: 'طالب',
};

/// Shown when the signed-in user has zero or more than one active center -
/// picking one sets TenantController.active and continues to the app.
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
            tooltip: 'تسجيل خروج',
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
                  ? const EmptyState(
                      icon: Icons.location_city_outlined,
                      title: 'حسابك غير مرتبط بأي مركز بعد',
                      subtitle: 'اطلب من مدير المركز دعوتك، أو سجّل الدخول بحساب آخر',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: tenant.memberships.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final membership = tenant.memberships[index];
                        final brand = parseBrandColor(membership.organization.primaryColor);
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            leading: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(color: brand, borderRadius: BorderRadius.circular(14)),
                              alignment: Alignment.center,
                              child: Text(
                                membership.organization.name.characters.first,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                            ),
                            title: Text(membership.organization.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(_roleLabels[membership.role] ?? ''),
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
