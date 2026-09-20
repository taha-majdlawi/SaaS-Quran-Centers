import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'org_avatar.dart';

import '../auth/auth_controller.dart';
import '../tenant/organization.dart';
import '../tenant/tenant_controller.dart';

const _roleLabels = {
  OrgRole.admin: 'مدير',
  OrgRole.teacher: 'معلم',
  OrgRole.guardian: 'ولي أمر',
  OrgRole.student: 'طالب',
};

class _NavItem {
  const _NavItem(this.icon, this.label, this.path, {this.module, this.adminOnly = false});

  final IconData icon;
  final String label;
  final String path;
  final String? module;
  final bool adminOnly;
}

class _NavSection {
  const _NavSection(this.title, this.items);

  final String? title;
  final List<_NavItem> items;
}

/// Same modules and same visibility rules as apps/web's TenantSidebar:
/// admins see everything, teachers only the modules they were granted,
/// admin-only entries stay hidden from everyone else.
const _sections = [
  _NavSection(null, [
    _NavItem(Icons.space_dashboard_rounded, 'لوحة التحكم', '/dashboard'),
    _NavItem(Icons.sync_rounded, 'المزامنة', '/sync'),
  ]),
  _NavSection('التعليم', [
    _NavItem(Icons.people_alt_rounded, 'الطلاب', '/students', module: 'students'),
    _NavItem(Icons.groups_rounded, 'الحلقات', '/circles', module: 'circles'),
    _NavItem(Icons.fact_check_rounded, 'الحضور', '/attendance', module: 'attendance'),
    _NavItem(Icons.auto_stories_rounded, 'المصحف', '/quran'),
    _NavItem(Icons.menu_book_rounded, 'السرد القرآني', '/serd', module: 'serd'),
    _NavItem(Icons.stairs_rounded, 'المراحل', '/stages', adminOnly: true),
  ]),
  _NavSection('التحفيز', [
    _NavItem(Icons.stars_rounded, 'النقاط', '/points', module: 'points'),
    _NavItem(Icons.emoji_events_rounded, 'الشارات', '/badges', module: 'badges'),
    _NavItem(Icons.storefront_rounded, 'سوق النقاط', '/market', module: 'market'),
    _NavItem(Icons.leaderboard_rounded, 'منافسات الحلقات', '/circle-challenges', module: 'circle-challenges'),
  ]),
  _NavSection('التواصل', [
    _NavItem(Icons.event_note_rounded, 'الأنشطة', '/activities', module: 'activities'),
    _NavItem(Icons.campaign_rounded, 'الإعلانات', '/announcements', module: 'announcements'),
    _NavItem(Icons.calendar_month_rounded, 'التقويم', '/calendar', module: 'calendar'),
    _NavItem(Icons.chat_bubble_rounded, 'المحادثات', '/chat', module: 'chat'),
    _NavItem(Icons.notifications_rounded, 'الإشعارات', '/notifications', module: 'notifications'),
  ]),
  _NavSection('إدارة المركز', [
    _NavItem(Icons.admin_panel_settings_rounded, 'الأعضاء والأدوار', '/members', adminOnly: true),
    _NavItem(Icons.history_rounded, 'سجل العمليات', '/audit', adminOnly: true),
    _NavItem(Icons.public_rounded, 'الموقع العام', '/site', adminOnly: true),
    _NavItem(Icons.settings_rounded, 'إعدادات المركز', '/settings', adminOnly: true),
  ]),
];

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  bool _visible(_NavItem item, TenantController tenant) {
    if (item.adminOnly) return tenant.active?.role == OrgRole.admin;
    if (item.module != null) return tenant.hasModule(item.module!);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final membership = tenant.active;
    final org = membership?.organization;
    final email = context.watch<AuthController>().currentUser?.email ?? '';
    final currentPath = GoRouterState.of(context).matchedLocation;
    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 24, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [scheme.primary, Color.lerp(scheme.primary, Colors.black, 0.35)!],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrgAvatar(name: org?.name ?? 'ب', logoUrl: org?.logoUrl, brandColor: org?.primaryColor, size: 56, onDark: true),
                const SizedBox(height: 14),
                Text(org?.name ?? 'بستان القرآن',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(email,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _roleLabels[membership?.role] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: [
                for (final section in _sections)
                  ..._buildSection(context, section, tenant, currentPath, scheme),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Column(
              children: [
                if (tenant.hasMultipleOrganizations)
                  ListTile(
                    leading: const Icon(Icons.swap_horiz_rounded),
                    title: const Text('تبديل المركز'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/select-organization');
                    },
                  ),
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: Colors.red.shade600),
                  title: Text('تسجيل خروج', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                  onTap: () => context.read<AuthController>().signOut(),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  List<Widget> _buildSection(
    BuildContext context,
    _NavSection section,
    TenantController tenant,
    String currentPath,
    ColorScheme scheme,
  ) {
    final items = section.items.where((i) => _visible(i, tenant)).toList();
    if (items.isEmpty) return const [];

    return [
      if (section.title != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(section.title!,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      for (final item in items)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: ListTile(
            dense: true,
            selected: currentPath == item.path || currentPath.startsWith('${item.path}/'),
            selectedTileColor: scheme.primary.withValues(alpha: 0.1),
            selectedColor: scheme.primary,
            leading: Icon(item.icon, size: 22),
            title: Text(item.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              context.go(item.path);
            },
          ),
        ),
    ];
  }
}
