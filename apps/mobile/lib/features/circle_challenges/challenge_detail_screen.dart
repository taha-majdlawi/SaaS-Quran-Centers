import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import '../engagement/engagement_models.dart';
import '../engagement/engagement_repository.dart';
import 'challenge_form_screen.dart';

/// The live board of one challenge: circles ranked by average per student.
class ChallengeDetailScreen extends StatefulWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final _repository = EngagementRepository(AppSupabase.client);
  late Future<ChallengeBoard> _future = _load();

  String get _orgId => context.read<TenantController>().active!.organization.id;

  Future<ChallengeBoard> _load() => _repository.challengeBoard(_orgId, widget.challengeId);

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنافسة'),
        content: const Text('متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repository.deleteChallenge(_orgId, widget.challengeId);
      if (mounted) context.pop();
    } on PostgrestException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<TenantController>().active?.role == OrgRole.admin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنافسة'),
        actions: [
          if (isAdmin)
            FutureBuilder<ChallengeBoard>(
              future: _future,
              builder: (context, snap) => snap.data == null
                  ? const SizedBox.shrink()
                  : Row(children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () async {
                          final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ChallengeFormScreen(challenge: snap.data!.challenge)));
                          if (changed == true && mounted) setState(() => _future = _load());
                        },
                      ),
                      IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete),
                    ]),
            ),
        ],
      ),
      body: AsyncBody<ChallengeBoard>(
        future: _future,
        onRetry: () => setState(() => _future = _load()),
        builder: (context, b) => RefreshIndicator(
          onRefresh: () async => setState(() => _future = _load()),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(b.challenge.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${kMetricLabels[b.challenge.metric]}\n${formatDate(b.challenge.startsOn)} — ${formatDate(b.challenge.endsOn)}  ·  ${kChallengeStatus[b.challenge.status]}', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 14),
              if (b.rows.isEmpty) const EmptyState(icon: Icons.groups_outlined, title: 'لا توجد حلقات فيها طلاب بعد'),
              for (final r in b.rows)
                Card(
                  color: r.mine ? Colors.green.shade50 : null,
                  child: ListTile(
                    leading: Text(r.rank == 1 ? '🥇' : (r.rank == 2 ? '🥈' : (r.rank == 3 ? '🥉' : '${r.rank}')), style: const TextStyle(fontSize: 24)),
                    title: Text(r.circleName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${r.students} طالب  ·  المجموع ${r.total}'),
                    trailing: Text('${r.average}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
