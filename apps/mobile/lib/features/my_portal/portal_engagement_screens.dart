import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import '../engagement/engagement_models.dart';
import '../engagement/engagement_repository.dart';
import 'my_portal_repository.dart';
import '../../core/widgets/net_image.dart';

/// Chips to switch between a guardian's children (nothing shown for one child).
Widget _childChips(List<PortalStudent> students, String? selected, ValueChanged<String> onSelect) {
  if (students.length < 2) return const SizedBox.shrink();
  return SizedBox(
    height: 52,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        for (final s in students)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(label: Text(s.fullName), selected: s.id == selected, onSelected: (_) => onSelect(s.id)),
          ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------

class PortalMarketScreen extends StatefulWidget {
  const PortalMarketScreen({super.key});

  @override
  State<PortalMarketScreen> createState() => _PortalMarketScreenState();
}

class _PortalMarketScreenState extends State<PortalMarketScreen> {
  final _engagement = EngagementRepository(AppSupabase.client);
  final _portal = MyPortalRepository(AppSupabase.client);
  late final Future<List<PortalStudent>> _studentsFuture = _portal.fetchMyStudents(_orgId);
  String? _studentId;
  Future<StudentMarket>? _market;

  String get _orgId => context.read<TenantController>().active!.organization.id;

  void _select(String id) => setState(() {
        _studentId = id;
        _market = _engagement.studentMarket(_orgId, id);
      });

  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
        _select(_studentId!);
      }
    } on PostgrestException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final k = t.market;
    return Scaffold(
      appBar: AppBar(title: Text(k.title)),
      body: AsyncBody<List<PortalStudent>>(
        future: _studentsFuture,
        builder: (context, students) {
          if (students.isEmpty) return EmptyState(icon: Icons.link_off_rounded, title: t.portal.noStudent);
          if (_studentId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _select(students.first.id));
            return const Center(child: CircularProgressIndicator());
          }
          return Column(children: [
            _childChips(students, _studentId, _select),
            Expanded(
              child: AsyncBody<StudentMarket>(
                future: _market!,
                onRetry: () => _select(_studentId!),
                builder: (context, m) {
                  if (!m.enabled) return EmptyState(icon: Icons.storefront_outlined, title: k.disabled);
                  final scheme = Theme.of(context).colorScheme;
                  return RefreshIndicator(
                    onRefresh: () async => _select(_studentId!),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(gradient: LinearGradient(begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd, colors: [scheme.primary, Color.lerp(scheme.primary, Colors.black, 0.35)!]), borderRadius: BorderRadius.circular(20)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(k.balance, style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                            Text(money(m.wallet.balance, m.symbol), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                              '${fmt(k.earned, {'n': m.wallet.earnedPoints, 'spent': money(m.wallet.spent, m.symbol)})}${m.wallet.pendingPoints > 0 ? fmt(k.pending, {'n': m.wallet.pendingPoints}) : ''}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                            ),
                          ]),
                        ),
                        SectionTitle(k.available),
                        if (m.items.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(k.empty)),
                        for (final i in m.items)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (i.imageUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: NetImage(i.imageUrl!, height: 150, width: double.infinity, error: const SizedBox.shrink()),
                                    ),
                                  ),
                                Row(children: [
                                  Expanded(child: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                                  Text(money(i.price, m.symbol), style: TextStyle(fontWeight: FontWeight.w800, color: scheme.primary)),
                                ]),
                                if (i.description != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(i.description!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5))),
                                if (i.stock != null) Text(fmt(k.stock, {'n': i.stock}), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                const SizedBox(height: 10),
                                Builder(builder: (context) {
                                  final out = i.stock != null && i.stock! <= 0;
                                  final afford = m.wallet.balance >= i.price;
                                  return FilledButton(
                                    onPressed: out || !afford ? null : () => _run(() => _engagement.buy(_orgId, _studentId!, i.id), k.bought),
                                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                                    child: Text(out ? k.soldOut : (afford ? k.buy : k.tooPoor)),
                                  );
                                }),
                              ]),
                            ),
                          ),
                        SectionTitle(k.orders),
                        if (m.purchases.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(k.noOrders)),
                        for (final p in m.purchases)
                          Card(
                            child: ListTile(
                              title: Text(p.itemName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text('${money(p.spent, m.symbol)}  ·  ${formatDate(p.createdAt)}'),
                              trailing: p.status == 'pending'
                                  ? TextButton(onPressed: () => _run(() => _engagement.cancelPurchase(p.id), k.cancelled), child: Text(t.common.cancel, style: const TextStyle(color: Colors.red)))
                                  : StatusChip(label: kPurchaseLabels[p.status] ?? p.status, color: kPurchaseColors[p.status] ?? Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _BadgesPortalData {
  const _BadgesPortalData(this.badges, this.leaderboard, this.grades, this.board, this.challenge);
  final List<BadgeProgress> badges;
  final Leaderboard leaderboard;
  final Map<String, String> grades;
  final ChallengeBoard? board;
  final Challenge? challenge;
}

class PortalBadgesScreen extends StatefulWidget {
  const PortalBadgesScreen({super.key});

  @override
  State<PortalBadgesScreen> createState() => _PortalBadgesScreenState();
}

class _PortalBadgesScreenState extends State<PortalBadgesScreen> {
  final _engagement = EngagementRepository(AppSupabase.client);
  final _portal = MyPortalRepository(AppSupabase.client);
  late final Future<List<PortalStudent>> _studentsFuture = _portal.fetchMyStudents(_orgId);
  String? _studentId;
  Future<_BadgesPortalData>? _data;

  String get _orgId => context.read<TenantController>().active!.organization.id;

  void _select(String id) => setState(() {
        _studentId = id;
        _data = _load(id);
      });

  Future<_BadgesPortalData> _load(String studentId) async {
    final orgId = _orgId;
    final results = await Future.wait<dynamic>([
      _engagement.studentBadges(orgId, studentId),
      _engagement.leaderboard(orgId),
      _engagement.gradeLabels(orgId),
      _engagement.challenges(orgId),
    ]);
    final challenges = results[3] as List<Challenge>;
    final running = challenges.where((c) => c.status == 'active').firstOrNull ?? challenges.firstOrNull;
    final board = running == null ? null : await _engagement.challengeBoard(orgId, running.id);
    return _BadgesPortalData(results[0] as List<BadgeProgress>, results[1] as Leaderboard, results[2] as Map<String, String>, board, running);
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final b0 = t.badges;
    return Scaffold(
      appBar: AppBar(title: Text(b0.title)),
      body: AsyncBody<List<PortalStudent>>(
        future: _studentsFuture,
        builder: (context, students) {
          if (students.isEmpty) return EmptyState(icon: Icons.link_off_rounded, title: t.portal.noStudent);
          if (_studentId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _select(students.first.id));
            return const Center(child: CircularProgressIndicator());
          }
          return Column(children: [
            _childChips(students, _studentId, _select),
            Expanded(
              child: AsyncBody<_BadgesPortalData>(
                future: _data!,
                onRetry: () => _select(_studentId!),
                builder: (context, d) => RefreshIndicator(
                  onRefresh: () async => _select(_studentId!),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SectionTitle(b0.mine),
                      if (d.badges.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(b0.none)),
                      for (final b in d.badges)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Opacity(
                                opacity: b.earned ? 1 : 0.45,
                                child: CircleAvatar(radius: 26, backgroundColor: b.color.withValues(alpha: 0.18), child: Text(b.icon, style: const TextStyle(fontSize: 26))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(b.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  Text(b.description ?? ruleText(b.ruleType, b.threshold, b.param, d.grades), style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                                  const SizedBox(height: 6),
                                  if (b.earned)
                                    Text('${fmt(b0.earned, {'date': formatDate(b.awardedAt)})}${b.expiresAt == null ? '' : fmt(b0.expires, {'date': formatDate(b.expiresAt)})}', style: const TextStyle(color: Colors.green, fontSize: 12))
                                  else if (b.ruleType == 'manual')
                                    Text(b0.manual, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))
                                  else ...[
                                    ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: b.fraction, minHeight: 8, color: b.color)),
                                    const SizedBox(height: 2),
                                    Text('${b.progress} / ${b.goal}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
                                  ],
                                ]),
                              ),
                            ]),
                          ),
                        ),
                      if (d.leaderboard.enabled && d.leaderboard.rows.isNotEmpty) ...[
                        SectionTitle(fmt(b0.board, {'circle': d.leaderboard.circleName ?? ''})),
                        for (final r in d.leaderboard.rows)
                          Card(
                            color: r.isMe ? Colors.green.shade50 : null,
                            child: ListTile(
                              dense: true,
                              leading: Text(r.rank == 1 ? '🥇' : (r.rank == 2 ? '🥈' : (r.rank == 3 ? '🥉' : '${r.rank}')), style: const TextStyle(fontSize: 20)),
                              title: Text(r.name, style: TextStyle(fontWeight: r.isMe ? FontWeight.w800 : FontWeight.w600)),
                              trailing: Text(fmt(b0.points, {'n': r.points}), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ],
                      if (d.board != null && d.challenge != null) ...[
                        SectionTitle(fmt(b0.challenge, {'title': d.challenge!.title})),
                        Text('${kMetricLabels[d.challenge!.metric]}  ·  ${kChallengeStatus[d.challenge!.status]}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                        const SizedBox(height: 6),
                        for (final r in d.board!.rows)
                          Card(
                            color: r.mine ? Colors.green.shade50 : null,
                            child: ListTile(
                              dense: true,
                              leading: Text(r.rank == 1 ? '🥇' : (r.rank == 2 ? '🥈' : (r.rank == 3 ? '🥉' : '${r.rank}')), style: const TextStyle(fontSize: 20)),
                              title: Text(r.circleName, style: TextStyle(fontWeight: r.mine ? FontWeight.w800 : FontWeight.w600)),
                              trailing: Text('${r.average}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
