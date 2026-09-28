import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/i18n/i18n.dart';
import '../../core/offline/prefetch.dart';
import '../../core/offline/sync_service.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/garden.dart';
import '../../core/widgets/ui.dart' show forwardChevron;
import '../../core/widgets/org_avatar.dart';
import '../../app_shell.dart';

/// The staff "More" tab: who and where you are, whether the phone is in step
/// with the server, every other section of the app as a tile grid, and the
/// account settings (language, center, sign out).
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _sectionColors = <String?, Color>{
    null: Color(0xFF1E7A54),
    'teaching': Color(0xFF16835A),
    'motivation': Color(0xFFB26A00),
    'comms': Color(0xFF1877C9),
    'admin': Color(0xFF6D4AA8),
  };

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final tenant = context.watch<TenantController>();
    final membership = tenant.active;
    final org = membership?.organization;
    final email = context.watch<AuthController>().currentUser?.email ?? '';
    final tabs = shellTabPaths(tenant);
    final prefetch = context.watch<OfflinePrefetch>();
    final sync = context.watch<SyncService>();

    return Scaffold(
      body: ListView(padding: EdgeInsets.zero, children: [
        GardenHeader(
          leading: org == null ? null : OrgAvatar(name: org.name, logoUrl: org.logoUrl, brandColor: org.primaryColor, size: 34, onDark: true),
          greeting: t.labels.roles[membership?.role.name] ?? '',
          title: org?.name ?? t.common.appName,
          subtitle: email,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // in step with the server?
            GardenCard(
              onTap: () => context.push('/sync'),
              child: Row(children: [
                IconBubble(sync.online ? Icons.offline_pin_rounded : Icons.cloud_off_rounded, color: sync.online ? const Color(0xFF16835A) : const Color(0xFFB26A00)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.sync.offlineTitle, style: const TextStyle(fontWeight: FontWeight.w800, color: kInk)),
                    const SizedBox(height: 2),
                    Text(
                      prefetch.running
                          ? fmt(t.sync.offlineProgress, {'done': prefetch.done, 'total': prefetch.total})
                          : prefetch.lastRun == null
                              ? t.sync.offlineNever
                              : fmt(t.sync.offlineLast, {'time': formatDateTime(prefetch.lastRun!.toIso8601String())}),
                      style: const TextStyle(color: kInkMuted, fontSize: 12.5),
                    ),
                  ]),
                ),
                const ConnectionPill(onDark: false),
              ]),
            ),
            for (final section in kNavSections)
              ..._section(context, section, tenant, tabs),
            GardenSection(
              title: t.garden.account,
              icon: Icons.person_rounded,
              child: GardenCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(children: [
                  ListTile(
                    leading: const IconBubble(Icons.translate_rounded, size: 36),
                    title: Text(t.common.language, style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: Text(kLocaleNames[context.watch<LocaleController>().effective]!, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
                    onTap: () => pickLanguage(context),
                  ),
                  if (tenant.hasModule('notifications'))
                    ListTile(
                      leading: const IconBubble(Icons.notifications_active_rounded, size: 36, color: Color(0xFF1877C9)),
                      title: Text(t.garden.notificationPrefs, style: const TextStyle(fontWeight: FontWeight.w700)),
                      trailing: Icon(forwardChevron(context), color: kInkMuted),
                      onTap: () => context.push('/notifications/prefs'),
                    ),
                  if (tenant.hasMultipleOrganizations)
                    ListTile(
                      leading: const IconBubble(Icons.swap_horiz_rounded, size: 36, color: Color(0xFF6D4AA8)),
                      title: Text(t.nav.switchCenter, style: const TextStyle(fontWeight: FontWeight.w700)),
                      trailing: Icon(forwardChevron(context), color: kInkMuted),
                      onTap: () => context.go('/select-organization'),
                    ),
                  ListTile(
                    leading: const IconBubble(Icons.logout_rounded, size: 36, color: Color(0xFFC0392B)),
                    title: Text(t.common.signOut, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFC0392B))),
                    onTap: () => context.read<AuthController>().signOut(),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  List<Widget> _section(BuildContext context, NavSection section, TenantController tenant, Set<String> tabs) {
    final t = tr(context);
    final items = section.items.where((i) => navItemVisible(i, tenant) && !tabs.contains(i.path) && i.path != '/sync').toList();
    if (items.isEmpty) return const [];
    final color = _sectionColors[section.title] ?? Theme.of(context).colorScheme.primary;
    return [
      GardenSection(
        title: section.title == null ? t.garden.moreTitle : (t.nav.sections[section.title!] ?? section.title!),
        child: GardenGrid(children: [
          for (final item in items)
            GardenTile(icon: item.icon, label: t.nav.items[item.path] ?? item.path, color: color, onTap: () => context.push(item.path)),
        ]),
      ),
    ];
  }
}
