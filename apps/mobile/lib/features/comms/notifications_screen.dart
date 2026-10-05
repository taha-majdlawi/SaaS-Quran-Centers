import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/i18n.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/ui.dart';
import 'comms_repository.dart';

/// Icon + accent for each kind of notification (also used by the inbox rows).
({IconData icon, Color color}) notificationVisual(String eventKey) => switch (eventKey) {
      'announcement' => (icon: Icons.campaign_rounded, color: const Color(0xFF7B1FA2)),
      'calendar_entry' || 'event_reminder' || 'waitlist_promoted' => (icon: Icons.event_rounded, color: const Color(0xFF1976D2)),
      'center_closed' => (icon: Icons.event_busy_rounded, color: const Color(0xFFEF6C00)),
      'serd_assigned' => (icon: Icons.assignment_rounded, color: const Color(0xFF00897B)),
      'serd_reviewed' || 'serd_approved' => (icon: Icons.verified_rounded, color: const Color(0xFF2E7D32)),
      'serd_rejected' => (icon: Icons.report_problem_rounded, color: const Color(0xFFC62828)),
      'market_order' || 'market_fulfilled' || 'market_cancelled' => (icon: Icons.storefront_rounded, color: const Color(0xFFD84315)),
      'wird_reminder' => (icon: Icons.menu_book_rounded, color: const Color(0xFF16835A)),
      'recitation_submitted' || 'recitation_reviewed' => (icon: Icons.graphic_eq_rounded, color: const Color(0xFF1E6F5C)),
      'badge_awarded' => (icon: Icons.emoji_events_rounded, color: const Color(0xFFF9A825)),
      'weekly_digest' => (icon: Icons.insights_rounded, color: const Color(0xFF3949AB)),
      'attendance_reminder' => (icon: Icons.fact_check_rounded, color: const Color(0xFF00897B)),
      'student_idle' || 'student_idle_teacher' => (icon: Icons.notifications_active_rounded, color: const Color(0xFFEF6C00)),
      'student_absences' => (icon: Icons.person_off_rounded, color: const Color(0xFFC62828)),
      'teacher_checkin_reminder' => (icon: Icons.how_to_reg_rounded, color: const Color(0xFF00897B)),
      'deletion_request' || 'deletion_reviewed' => (icon: Icons.privacy_tip_rounded, color: const Color(0xFF546E7A)),
      'billing_reminder' || 'billing_reviewed' || 'billing_downgraded' || 'capacity_warning' => (icon: Icons.receipt_long_rounded, color: const Color(0xFF6A1B9A)),
      'manual' => (icon: Icons.mark_email_unread_rounded, color: const Color(0xFF6D4C41)),
      'test' => (icon: Icons.science_rounded, color: const Color(0xFF546E7A)),
      _ => (icon: Icons.notifications_rounded, color: const Color(0xFF546E7A)),
    };

String _ago(String iso) {
  final t = DateTime.tryParse(iso)?.toLocal();
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return currentStrings.notif.now;
  if (d.inMinutes < 60) return fmt(currentStrings.notif.minutesAgo, {'n': d.inMinutes});
  if (d.inHours < 24) return fmt(currentStrings.notif.hoursAgo, {'n': d.inHours});
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

String _dayLabel(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return currentStrings.notif.today;
  if (diff == 1) return currentStrings.notif.yesterday;
  return '${t.day}/${t.month}/${t.year}';
}

/// The person's own inbox, grouped by day. Each row leads to what it is about; the tune icon opens
/// the per-type switches.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repository = CommsRepository(AppSupabase.client);
  Future<List<NotificationItem>>? _future;
  String? _orgId;

  static const _deepLinks = {
    'announcements': ['/announcements', '/announcements'],
    'calendar': ['/calendar', '/calendar'],
    'market': ['/market', '/my/market'],
    'chat': ['/chat', '/chat'],
    'badges': ['/badges', '/my/badges'],
  };

  String? _routeFor(NotificationItem n, bool portal) {
    final link = _deepLinks[n.deepLink];
    if (link != null) return link[portal ? 1 : 0];
    if (n.refId == null) return null;
    switch (n.eventKey) {
      case 'weekly_digest':
        return n.refId == null ? '/my/report' : '/weekly/${n.refId}';
      case 'calendar_entry':
      case 'center_closed':
      case 'event_reminder':
      case 'waitlist_promoted':
        return '/calendar/${n.refId}';
      case 'attendance_reminder':
        return portal ? null : '/attendance';
      case 'deletion_request':
        return portal ? null : '/deletion-requests';
      case 'deletion_reviewed':
        return portal ? '/my/privacy' : null;
      case 'announcement':
        return '/announcements';
      case 'serd_assigned':
        return '/serd/new?session=${n.refId}';
      case 'serd_reviewed':
      case 'serd_approved':
      case 'serd_rejected':
        return portal ? '/my' : '/serd';
      case 'student_idle':
        return portal ? '/my' : null;
      case 'student_idle_teacher':
      case 'student_absences':
        return portal ? null : '/students/${n.refId}/file';
      case 'teacher_checkin_reminder':
        return portal ? null : '/dashboard';
      case 'market_order':
      case 'market_fulfilled':
      case 'market_cancelled':
        return portal ? '/my/market' : '/market';
      case 'badge_awarded':
        return portal ? '/my/badges' : '/badges/${n.refId}';
      case 'wird_reminder':
        return portal ? '/my' : null;
      case 'recitation_submitted':
        return portal ? null : '/recitations';
      case 'recitation_reviewed':
        return portal ? '/my/recitations' : '/recitations';
    }
    return null;
  }

  void _reload() => setState(() => _future = _repository.notifications(_orgId!));

  Future<void> _open(NotificationItem n, bool portal) async {
    if (!n.read) _repository.markAllRead(_orgId!).then((_) => mounted ? _reload() : null);
    final route = _routeFor(n, portal);
    if (route != null && mounted) await context.push(route);
  }

  Widget _row(NotificationItem n, bool portal) {
    final scheme = Theme.of(context).colorScheme;
    final v = notificationVisual(n.eventKey);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: n.read ? null : scheme.primary.withValues(alpha: 0.06),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _open(n, portal),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: v.color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(v.icon, color: v.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w600 : FontWeight.w800, fontSize: 14.5))),
                  if (!n.read) Container(width: 9, height: 9, decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle)),
                ]),
                if ((n.body ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(n.body!, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.4)),
                ],
                const SizedBox(height: 6),
                Text(_ago(n.createdAt), style: TextStyle(fontSize: 11.5, color: scheme.outline)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  List<Widget> _grouped(List<NotificationItem> list, bool portal) {
    final out = <Widget>[];
    String? last;
    for (final n in list) {
      final t = DateTime.tryParse(n.createdAt)?.toLocal();
      final label = t == null ? '' : _dayLabel(t);
      if (label != last) {
        out.add(Padding(
          padding: EdgeInsets.only(top: last == null ? 0 : 10, bottom: 8),
          child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.outline)),
        ));
        last = label;
      }
      out.add(_row(n, portal));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final orgId = tenant.active?.organization.id;
    if (orgId != null && orgId != _orgId) {
      _orgId = orgId;
      _future = _repository.notifications(orgId);
    }
    final role = tenant.active?.role;
    final isStaff = role == OrgRole.admin || role == OrgRole.teacher;

    return Scaffold(
      appBar: AppBar(
        leading: const DrawerLeading(),
        title: Text(tr(context).notif.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: tr(context).notif.markAll,
            onPressed: () async {
              await _repository.markAllRead(_orgId!);
              if (mounted) _reload();
            },
          ),
          IconButton(icon: Icon(Icons.tune_rounded), tooltip: tr(context).notif.prefs, onPressed: () => context.push('/notifications/prefs')),
        ],
      ),
      drawer: isStaff ? const AppDrawer() : null,
      body: _future == null
          ? const SizedBox.shrink()
          : AsyncBody<List<NotificationItem>>(
              future: _future!,
              onRetry: _reload,
              builder: (context, list) => RefreshIndicator(
                onRefresh: () async => _reload(),
                child: list.isEmpty
                    ? ListView(children: [SizedBox(height: 80), EmptyState(icon: Icons.notifications_none_rounded, title: tr(context).notif.none)])
                    : Builder(builder: (context) {
                        // built lazily: only the rows on screen are laid out
                        final rows = _grouped(list, !isStaff);
                        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: rows.length, itemBuilder: (_, i) => rows[i]);
                      }),
              ),
            ),
    );
  }
}
