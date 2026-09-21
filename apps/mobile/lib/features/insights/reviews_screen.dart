import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/data/quran_data.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import 'insights_repository.dart';

/// Spaced-review schedule: the surahs each student should review today (interval grows with good grades).
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _repository = InsightsRepository(AppSupabase.client);
  Future<List<DueReview>>? _future;
  String? _orgId;

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _orgId) {
      _orgId = orgId;
      _future = _repository.dueReviews(orgId);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('المراجعة المقترحة اليوم')),
      body: _future == null
          ? const SizedBox.shrink()
          : AsyncBody<List<DueReview>>(
              future: _future!,
              onRetry: () => setState(() => _future = _repository.dueReviews(_orgId!)),
              builder: (context, list) {
                final byStudent = <String, List<DueReview>>{};
                for (final r in list) {
                  byStudent.putIfAbsent(r.studentId, () => []).add(r);
                }
                return RefreshIndicator(
                  onRefresh: () async => setState(() => _future = _repository.dueReviews(_orgId!)),
                  child: list.isEmpty
                      ? ListView(children: const [SizedBox(height: 80), EmptyState(icon: Icons.task_alt_rounded, title: 'لا مراجعات مستحقة اليوم ✓')])
                      : ListView(padding: const EdgeInsets.all(16), children: [
                          Text('كل سورة تُقترح بعد فاصل يكبر مع التقدير الجيد ويعود ليوم واحد مع الضعيف.',
                              style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.outline)),
                          const SizedBox(height: 10),
                          for (final e in byStudent.entries)
                            Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: Text(e.value.first.studentName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Wrap(spacing: 6, runSpacing: 4, children: [
                                    if (e.value.first.circleName != null) Text(e.value.first.circleName!, style: const TextStyle(fontSize: 12)),
                                    for (final r in e.value)
                                      Chip(
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        side: BorderSide.none,
                                        backgroundColor: (r.daysOverdue > 3 ? Colors.red : Colors.amber).withValues(alpha: 0.15),
                                        label: Text('${surahName(r.surah)}${r.daysOverdue > 0 ? ' · متأخرة ${r.daysOverdue}' : ''}', style: const TextStyle(fontSize: 11.5)),
                                      ),
                                  ]),
                                ),
                                onTap: () => context.push('/students/${e.key}/file'),
                              ),
                            ),
                        ]),
                );
              },
            ),
    );
  }
}
