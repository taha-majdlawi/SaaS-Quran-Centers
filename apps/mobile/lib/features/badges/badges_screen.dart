import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import 'badges_repository.dart';

/// Mirrors apps/web's /badges page: catalog + edit links, an award-to-
/// student form, and a recent-awards feed, all on one screen.
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final _repository = BadgesRepository(AppSupabase.client);
  String? _loadedForOrgId;
  late Future<void> _dataFuture;

  List<BadgeSummary> _badges = [];
  List<BadgeStudentOption> _students = [];
  List<RecentAward> _recentAwards = [];

  String? _awardStudentId;
  String? _awardBadgeId;
  bool _awarding = false;
  String? _message;
  bool _isError = false;

  Future<void> _load(String orgId) async {
    final results = await Future.wait([
      _repository.fetchBadges(orgId),
      _repository.fetchActiveStudents(orgId),
      _repository.fetchRecentAwards(orgId),
    ]);
    _badges = results[0] as List<BadgeSummary>;
    _students = results[1] as List<BadgeStudentOption>;
    _recentAwards = results[2] as List<RecentAward>;
  }

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _dataFuture = _load(orgId);
  }

  Future<void> _award() async {
    if (_awardStudentId == null || _awardBadgeId == null) return;
    setState(() {
      _awarding = true;
      _message = null;
    });
    try {
      final userId = context.read<AuthController>().currentUser?.id;
      await _repository.awardBadge(badgeId: _awardBadgeId!, studentId: _awardStudentId!, awardedBy: userId);
      if (mounted) {
        setState(() {
          _message = 'تم منح الشارة بنجاح';
          _isError = false;
        });
        _reload(_loadedForOrgId!);
      }
    } catch (e) {
      final isDuplicate = e is PostgrestException && e.code == '23505';
      if (mounted) {
        setState(() {
          _message = isDuplicate ? 'الطالب حاصل على هذي الشارة من قبل' : 'حدث خطأ أثناء المنح';
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _awarding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الشارات')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/badges/new');
          if (orgId != null && mounted) setState(() => _reload(orgId));
        },
        child: const Icon(Icons.add),
      ),
      body: orgId == null
          ? const SizedBox.shrink()
          : FutureBuilder<void>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_message != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _message!,
                          style: TextStyle(color: _isError ? Colors.red.shade700 : Colors.green.shade700),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_badges.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('لا يوجد شارات بعد')),
                      )
                    else
                      ..._badges.map((b) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(b.name),
                              subtitle: Text(b.description ?? '—'),
                              trailing: TextButton(
                                onPressed: () async {
                                  await context.push('/badges/${b.id}');
                                  if (mounted) setState(() => _reload(orgId));
                                },
                                child: const Text('تعديل'),
                              ),
                            ),
                          )),
                    if (_badges.isNotEmpty && _students.isNotEmpty) ...[
                      const Divider(height: 32),
                      Text('منح شارة لطالب', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _awardStudentId,
                        decoration: const InputDecoration(labelText: 'الطالب', border: OutlineInputBorder()),
                        items: _students.map((s) => DropdownMenuItem(value: s.id, child: Text(s.fullName))).toList(),
                        onChanged: (v) => setState(() => _awardStudentId = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _awardBadgeId,
                        decoration: const InputDecoration(labelText: 'الشارة', border: OutlineInputBorder()),
                        items: _badges.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
                        onChanged: (v) => setState(() => _awardBadgeId = v),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _awarding ? null : _award,
                        child: _awarding
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('منح الشارة'),
                      ),
                    ],
                    if (_recentAwards.isNotEmpty) ...[
                      const Divider(height: 32),
                      Text('آخر الشارات الممنوحة', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._recentAwards.map((a) => Text('${a.studentName} — ${a.badgeName}')),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
