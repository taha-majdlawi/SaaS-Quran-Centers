import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'org_avatar.dart';

import '../auth/auth_controller.dart';
import '../tenant/organization.dart';
import '../tenant/tenant_controller.dart';
import '../../core/i18n/i18n.dart';

class _NavItem {
  const _NavItem(this.icon, this.path, {this.module, this.adminOnly = false});

  final IconData icon;
  final String path;
  final String? module;
  final bool adminOnly;
}

class _NavSection {
  const _NavSection(this.title, this.items);

  /// key into tr(context).nav.sections
  final String? title;
  final List<_NavItem> items;
}

/// Same modules and same visibility rules as apps/web's TenantSidebar:
/// admins see everything, teachers only the modules they were granted,
/// admin-only entries stay hidden from everyone else.
const _sections = [
  _NavSection(null, [
    _NavItem(Icons.space_dashboard_rounded, '/dashboard'),
    _NavItem(Icons.sync_rounded, '/sync'),
  ]),
  _NavSection('teaching', [
    _NavItem(Icons.people_alt_rounded, '/students', module: 'students'),
    _NavItem(Icons.groups_rounded, '/circles', adminOnly: true),
    _NavItem(Icons.fact_check_rounded, '/attendance', module: 'attendance'),
    _NavItem(Icons.groups_2_rounded, '/gatherings', module: 'attendance'),
    _NavItem(Icons.record_voice_over_rounded, '/external-recitations', module: 'students'),
    _NavItem(Icons.replay_circle_filled_rounded, '/reviews'),
    _NavItem(Icons.search_rounded, '/search'),
    _NavItem(Icons.auto_stories_rounded, '/quran'),
    _NavItem(Icons.menu_book_rounded, '/serd', module: 'serd'),
    _NavItem(Icons.stairs_rounded, '/stages', adminOnly: true),
  ]),
  _NavSection('motivation', [
    _NavItem(Icons.stars_rounded, '/points', module: 'points'),
    _NavItem(Icons.emoji_events_rounded, '/badges', module: 'badges'),
    _NavItem(Icons.storefront_rounded, '/market', module: 'market'),
    _NavItem(Icons.leaderboard_rounded, '/circle-challenges', module: 'circle-challenges'),
  ]),
  _NavSection('comms', [
    _NavItem(Icons.event_note_rounded, '/activities', module: 'activities'),
    _NavItem(Icons.campaign_rounded, '/announcements', module: 'announcements'),
    _NavItem(Icons.calendar_month_rounded, '/calendar', module: 'calendar'),
    _NavItem(Icons.chat_bubble_rounded, '/chat', module: 'chat'),
    _NavItem(Icons.notifications_rounded, '/notifications', module: 'notifications'),
    _NavItem(Icons.insights_rounded, '/reports', module: 'reports'),
    _NavItem(Icons.workspace_premium_rounded, '/certificates', module: 'certificates'),
  ]),
  _NavSection('admin', [
    _NavItem(Icons.admin_panel_settings_rounded, '/members', adminOnly: true),
    _NavItem(Icons.privacy_tip_rounded, '/deletion-requests', adminOnly: true),
    _NavItem(Icons.history_rounded, '/audit', adminOnly: true),
    _NavItem(Icons.public_rounded, '/site', adminOnly: true),
    _NavItem(Icons.settings_rounded, '/settings', adminOnly: true),
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
                Text(org?.name ?? tr(context).common.appName,
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
                    tr(context).labels.roles[membership?.role.name] ?? '',
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
                ListTile(
                  leading: const Icon(Icons.translate_rounded),
                  title: Text(tr(context).common.language),
                  trailing: Text(kLocaleNames[context.watch<LocaleController>().effective]!, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
                  onTap: () => _pickLanguage(context),
                ),
                if (tenant.hasMultipleOrganizations)
                  ListTile(
                    leading: const Icon(Icons.swap_horiz_rounded),
                    title: Text(tr(context).nav.switchCenter),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/select-organization');
                    },
                  ),
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: Colors.red.shade600),
                  title: Text(tr(context).common.signOut, style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
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

  Future<void> _pickLanguage(BuildContext context) async {
    final locale = context.read<LocaleController>();
    final lang = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(tr(c).common.language),
        children: [
          for (final l in kLocales)
            ListTile(
              title: Text(kLocaleNames[l]!),
              trailing: l == locale.effective ? Icon(Icons.check_rounded, color: Theme.of(c).colorScheme.primary) : null,
              onTap: () => Navigator.pop(c, l),
            ),
        ],
      ),
    );
    if (lang != null) await locale.choose(lang);
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
          child: Text(tr(context).nav.sections[section.title!] ?? section.title!,
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
            title: Text(tr(context).nav.items[item.path] ?? item.path, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              // the dashboard is the root; everything else opens ON TOP of it (so there is a back
              // button), and moving between drawer screens replaces the current one instead of
              // piling them up
              if (item.path == '/dashboard') {
                context.go('/dashboard');
              } else if (currentPath == '/dashboard') {
                context.push(item.path);
              } else {
                context.pushReplacement(item.path);
              }
            },
          ),
        ),
    ];
  }
}


/// The leading button of an app bar whose screen has the drawer: a BACK arrow when the
/// screen was opened on top of another (the normal case from the drawer), the menu button
/// on the root screen. Without a drawer it behaves like the default back button.
class DrawerLeading extends StatelessWidget {
  const DrawerLeading({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = GoRouter.of(context).canPop();
    if (canPop) return const BackButton();
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.hasDrawer) {
      return IconButton(icon: Icon(Icons.menu_rounded), tooltip: tr(context).nav.menu, onPressed: scaffold.openDrawer);
    }
    return const SizedBox.shrink();
  }
}
