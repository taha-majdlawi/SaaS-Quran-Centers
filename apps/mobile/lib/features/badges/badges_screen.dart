import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/ui.dart';
import '../engagement/engagement_models.dart';
import '../engagement/engagement_repository.dart';
import '../../core/i18n/i18n.dart';

class _BadgesData {
  const _BadgesData(this.badges, this.grades);
  final List<BadgeDef> badges;
  final Map<String, String> grades;
}

/// The center's badges: automatic rules (awarded the moment the condition is
/// met) and manual ones. Admin edits; a teacher can award to their own students.
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final _repository = EngagementRepository(AppSupabase.client);
  Future<_BadgesData>? _future;
  String? _orgId;

  void _load(String orgId) {
    _orgId = orgId;
    _future = Future.wait<dynamic>([_repository.badgeDefs(orgId), _repository.gradeLabels(orgId)])
        .then((r) => _BadgesData(r[0] as List<BadgeDef>, r[1] as Map<String, String>));
  }

  @override
  Widget build(BuildContext context) {
    final membership = context.watch<TenantController>().active;
    final orgId = membership?.organization.id;
    if (orgId != null && orgId != _orgId) _load(orgId);
    final isAdmin = membership?.role == OrgRole.admin;

    return Scaffold(
      appBar: AppBar(
        leading: const DrawerLeading(),
        title: Text(tr(context).nav.items['/badges']!),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: tr(context).badgesStaff.reevaluate,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () async {
                try {
                  await _repository.evaluateAll(_orgId!);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context).badgesStaff.reevaluated)));
                } on PostgrestException catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                }
              },
            ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/badges/new');
                if (mounted) setState(() => _load(_orgId!));
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(tr(context).badgesStaff.newTitle),
            )
          : null,
      body: _future == null
          ? const SizedBox.shrink()
          : AsyncBody<_BadgesData>(
              future: _future!,
              onRetry: () => setState(() => _load(_orgId!)),
              builder: (context, data) => RefreshIndicator(
                onRefresh: () async => setState(() => _load(_orgId!)),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  children: [
                    Text(tr(context).badgesStaff.intro, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 10),
                    if (data.badges.isEmpty) Padding(padding: EdgeInsets.only(top: 60), child: EmptyState(icon: Icons.emoji_events_outlined, title: tr(context).badgesStaff.empty)),
                    for (final b in data.badges)
                      Card(
                        child: ListTile(
                          onTap: () async {
                            await context.push('/badges/${b.id}');
                            if (mounted) setState(() => _load(_orgId!));
                          },
                          leading: CircleAvatar(radius: 24, backgroundColor: b.color.withValues(alpha: 0.15), child: Text(b.icon, style: const TextStyle(fontSize: 24))),
                          title: Text(b.name, style: TextStyle(fontWeight: FontWeight.w800, color: b.isActive ? null : Colors.grey)),
                          subtitle: Text([
                            ruleText(b.ruleType, b.threshold, b.param, data.grades),
                            if (b.durationDays != null) fmt(tr(context).badgesStaff.expiresAfter, {'durationDays': b.durationDays}),
                            if (!b.isActive) tr(context).badgesStaff.inactive,
                          ].join('  ·  ')),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
