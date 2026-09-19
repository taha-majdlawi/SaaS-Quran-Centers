import 'package:flutter/material.dart';
import '../../core/widgets/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'circle_challenges_repository.dart';

/// Mirrors apps/web's circle-challenges/[id] page - the scoreboard, one
/// score per circle, saved as a single upsert batch.
class ChallengeDetailScreen extends StatefulWidget {
  const ChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final _repository = CircleChallengesRepository(AppSupabase.client);
  ChallengeSummary? _challenge;
  List<ChallengeCircleScore> _scores = [];
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = true;
  bool _saving = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orgId = context.read<TenantController>().active!.organization.id;
    final results = await Future.wait([
      _repository.fetchChallenge(widget.challengeId),
      _repository.fetchScoreboard(orgId, widget.challengeId),
    ]);
    _challenge = results[0] as ChallengeSummary?;
    _scores = results[1] as List<ChallengeCircleScore>;
    for (final s in _scores) {
      _controllers[s.circleId] = TextEditingController(text: s.score.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final scoreByCircle = {
        for (final entry in _controllers.entries) entry.key: num.tryParse(entry.value.text.trim()) ?? 0,
      };
      await _repository.saveScores(widget.challengeId, scoreByCircle);
      if (mounted) setState(() { _message = 'تم حفظ النتائج'; _isError = false; });
    } catch (e) {
      if (mounted) setState(() { _message = 'حدث خطأ أثناء الحفظ'; _isError = true; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنافسة'),
        content: Text('متأكد إنك بدك تحذف منافسة "${_challenge?.title}"؟'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => context.pop(true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.deleteChallenge(widget.challengeId);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_challenge?.title ?? 'المنافسة'),
        actions: [IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_challenge != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'المعيار: ${_challenge!.metric} — ${_challenge!.startsOn} إلى ${_challenge!.endsOn}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (_message != null) MessageBanner(message: _message!, isError: _isError),
                if (_scores.isEmpty)
                  const Center(child: Text('لا يوجد حلقات بعد'))
                else
                  ..._scores.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(child: Text(s.circleName)),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                controller: _controllers[s.circleId],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(isDense: true),
                              ),
                            ),
                          ],
                        ),
                      )),
                if (_scores.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('حفظ النتائج'),
                  ),
                ],
              ],
            ),
    );
  }
}
