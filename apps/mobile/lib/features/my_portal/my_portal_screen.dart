import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/data/quran_data.dart';
import '../../core/i18n/i18n.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/org_avatar.dart';
import '../../core/widgets/ui.dart';
import '../engagement/engagement_repository.dart';
import '../recitation/recitation_repository.dart' show kAchievementTypes;
import '../serd/serd_models.dart';
import '../serd/serd_widgets.dart';
import 'home_extras.dart';
import 'my_portal_repository.dart';
import 'record_extras.dart';

/// The student's (or guardian's) whole app: home, record, account. Students
/// and guardians never reach the staff screens - the router sends them here.
class MyPortalScreen extends StatefulWidget {
  const MyPortalScreen({super.key});

  @override
  State<MyPortalScreen> createState() => _MyPortalScreenState();
}

class _MyPortalScreenState extends State<MyPortalScreen> {
  final _repository = MyPortalRepository(AppSupabase.client);
  int _tab = 0;
  String? _loadedForOrgId;
  List<PortalStudent> _students = [];
  String? _studentId;
  Future<PortalDashboard?>? _dashboard;
  Object? _error;
  bool _loadingStudents = true;

  Future<void> _loadStudents(String orgId) async {
    _loadedForOrgId = orgId;
    setState(() {
      _loadingStudents = true;
      _error = null;
    });
    try {
      final students = await _repository.fetchMyStudents(orgId);
      _students = students;
      _studentId = students.isEmpty ? null : students.first.id;
      if (_studentId != null) _dashboard = _repository.fetchDashboard(orgId, _studentId!);
    } catch (e) {
      _error = e;
    } finally {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  void _reload() {
    final orgId = _loadedForOrgId;
    if (orgId != null && _studentId != null) {
      setState(() => _dashboard = _repository.fetchDashboard(orgId, _studentId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final org = tenant.active?.organization;
    if (org != null && org.id != _loadedForOrgId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudents(org.id));
    }
    final isGuardian = tenant.active?.role == OrgRole.guardian;
    final t = tr(context);
    final p = t.portal;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          if (org != null) OrgAvatar(name: org.name, logoUrl: org.logoUrl, brandColor: org.primaryColor, size: 34),
          const SizedBox(width: 10),
          Flexible(child: Text(org?.name ?? t.common.appName, overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: t.common.signOut,
            onPressed: () => context.read<AuthController>().signOut(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: p.tabHome),
          NavigationDestination(icon: const Icon(Icons.history_edu_outlined), selectedIcon: const Icon(Icons.history_edu_rounded), label: p.tabRecord),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person_rounded), label: p.tabAccount),
        ],
      ),
      body: _loadingStudents
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(onRetry: () => _loadStudents(org!.id))
              : _students.isEmpty
                  ? EmptyState(
                      icon: Icons.link_off_rounded,
                      title: isGuardian ? p.noChildren : p.notLinked,
                      subtitle: p.askAdmin,
                    )
                  : Column(
                      children: [
                        if (_students.length > 1)
                          SizedBox(
                            height: 56,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              children: [
                                for (final s in _students)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(end: 8),
                                    child: ChoiceChip(
                                      label: Text(s.fullName),
                                      selected: s.id == _studentId,
                                      onSelected: (_) => setState(() {
                                        _studentId = s.id;
                                        _dashboard = _repository.fetchDashboard(org!.id, s.id);
                                      }),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: AsyncBody<PortalDashboard?>(
                            future: _dashboard!,
                            onRetry: _reload,
                            builder: (context, data) {
                              if (data == null) {
                                return EmptyState(icon: Icons.link_off_rounded, title: p.studentMissing);
                              }
                              return RefreshIndicator(
                                onRefresh: () async => _reload(),
                                child: switch (_tab) {
                                  0 => _HomeTab(data: data),
                                  1 => _RecordTab(key: ValueKey(_studentId), orgId: org!.id, studentId: _studentId!, serd: data.serd),
                                  _ => _AccountTab(data: data),
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.data});
  final PortalDashboard data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = tr(context);
    final p = t.portal;
    final firstName = data.fullName.split(' ').first;
    final change = data.thisWeek - data.lastWeek;
    final weekText = change > 0
        ? fmt(p.weekBetter, {'n': change})
        : change < 0
            ? fmt(p.weekWorse, {'n': change})
            : p.weekSame;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [scheme.primary, Color.lerp(scheme.primary, Colors.black, 0.35)!],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fmt(p.hello, {'name': firstName}), style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      data.circleName == null
                          ? p.noCircle
                          : '${data.circleName}${data.teacherName == null ? '' : '  ·  ${fmt(p.sheikh, {'name': data.teacherName})}'}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  ProgressRing(progress: (data.totalParts / 30).clamp(0.0, 1.0), centerText: '${data.totalParts}/30', size: 76, strokeWidth: 7),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 3),
                    Text('${data.currentStreak}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ]),
                ],
              ),
            ],
          ),
        ),
        AnnouncementsPreviewCard(announcements: data.announcements),
        SectionTitle(p.progressTitle),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(fmt(p.partsOf30, {'n': data.totalParts}), style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${data.progress.toStringAsFixed(data.progress % 1 == 0 ? 0 : 1)}%'),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: (data.totalParts / 30).clamp(0.0, 1.0).toDouble(), minHeight: 10),
                ),
                if (data.nextPlan != null && data.nextPlan!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Text(fmt(p.nextPlan, {'plan': data.nextPlan})),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        NextGoalsCard(goals: computeGoals(data.totalParts, data.totalPoints, p)),
        const SizedBox(height: 12),
        UpcomingEventsCard(entries: data.upcoming),
        const SizedBox(height: 12),
        const DailyInspirationCard(),
        Builder(builder: (context) {
          final today = computeTodayPrayers(data.prayerSettings);
          return today == null
              ? const SizedBox.shrink()
              : Padding(padding: const EdgeInsets.only(top: 12), child: PrayerTimesCard(today: today, names: p.prayers));
        }),
        SectionTitle(p.statsTitle),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _Stat(icon: Icons.menu_book_rounded, label: p.statAyahs, value: '${data.ayahsThisWeek}', color: Colors.blue),
            _Stat(
              icon: Icons.how_to_reg_rounded,
              label: p.statAttendance,
              value: data.weeklyAttendance == null ? '—' : '${data.weeklyAttendance}%',
              color: Colors.green,
            ),
            _Stat(icon: Icons.mic_rounded, label: p.statTotal, value: '${data.totalRecitations}', color: Colors.purple),
            _Stat(icon: Icons.schedule_rounded, label: p.statLast, value: formatDate(data.lastRecitationAt), color: Colors.orange),
          ],
        ),
        SectionTitle(p.weekTitle),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(
                    change > 0 ? Icons.trending_up_rounded : (change < 0 ? Icons.trending_down_rounded : Icons.trending_flat_rounded),
                    color: change > 0 ? Colors.green : (change < 0 ? Colors.red : Colors.grey),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(fmt(p.weekCount, {'n': data.thisWeek}), style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
                Text(weekText, style: TextStyle(color: Colors.grey.shade600)),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange.shade400),
                    const SizedBox(width: 8),
                    Expanded(child: Text(fmt(p.streak, {'n': data.currentStreak, 'best': data.longestStreak}))),
                  ],
                ),
                if (data.currentStreak > 0 && data.currentStreak == data.longestStreak) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.deepOrange.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Text(p.streakRecord, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        BadgesPreviewRow(badges: data.badges),
        const SizedBox(height: 12),
        if (!context.watch<TenantController>().isDisabled('calendar'))
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_month_rounded),
            title: Text(p.calendar, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(p.calendarSub),
            trailing: Icon(forwardChevron(context)),
            onTap: () => context.push('/calendar'),
          ),
        ),
        Row(children: [
          if (!context.watch<TenantController>().isDisabled('chat'))
          Expanded(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.chat_bubble_rounded),
                title: Text(p.chat, style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => context.push('/chat'),
              ),
            ),
          ),
          if (!context.watch<TenantController>().isDisabled('announcements'))
          Expanded(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.campaign_rounded),
                title: Text(p.announcementsLink, style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => context.push('/announcements'),
              ),
            ),
          ),
        ]),
        if (!context.watch<TenantController>().isDisabled('reports'))
        Card(
          child: ListTile(
            leading: const Icon(Icons.insights_rounded),
            title: Text(p.report, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(p.reportSub),
            onTap: () => context.push('/my/report'),
          ),
        ),
        if (!context.watch<TenantController>().isDisabled('certificates'))
        Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium_rounded),
            title: Text(p.certificates, style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => context.push('/my/certificates'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.auto_stories_rounded),
            title: Text(p.quran, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(p.quranSub),
            onTap: () => context.push('/quran'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.privacy_tip_rounded),
            title: Text(p.privacy, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(p.privacySub),
            onTap: () => context.push('/my/privacy'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_rounded),
            title: Text(p.notifications, style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => context.push('/notifications'),
          ),
        ),
        Row(children: [
          if (!context.watch<TenantController>().isDisabled('badges'))
          Expanded(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events_rounded),
                title: Text(p.badges, style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => context.push('/my/badges'),
              ),
            ),
          ),
          if (!context.watch<TenantController>().isDisabled('market'))
          Expanded(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.storefront_rounded),
                title: Text(p.market, style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => context.push('/my/market'),
              ),
            ),
          ),
        ]),
        SectionTitle(p.serd),
        SerdSummaryCard(summary: data.serd),
        SectionTitle(p.recent),
        if (data.recent.isEmpty)
          Padding(padding: const EdgeInsets.all(12), child: Text(p.noRecitations))
        else
          for (final r in data.recent.take(5)) RecitationTile(r: r),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final String value;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color.shade700, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecitationTile extends StatelessWidget {
  const RecitationTile({super.key, required this.r});
  final PortalRecitation r;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: const TileBadge(),
          title: Text('${surahName(r.surah)}  (${r.ayahFrom}–${r.ayahTo})', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${kAchievementTypes[r.type] ?? r.type}  ·  ${r.gradeLabel}  ·  ${formatDate(r.createdAt)}'
              '${r.notes == null ? '' : '\n${r.notes}'}',
            ),
          ),
          isThreeLine: r.notes != null,
          trailing: StatusChip(label: '+${r.points}', color: Colors.green),
        ),
      ),
    );
  }
}

class TileBadge extends StatelessWidget {
  const TileBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(Icons.menu_book_rounded, color: c, size: 22),
    );
  }
}

class _RecordData {
  const _RecordData(this.detail, this.gradeLabels);
  final RecordDetail detail;
  final Map<String, String> gradeLabels;
}

/// سجلّي: recitations / attendance / serd, each its own segment (parity with
/// eqraa's record_tab.dart 3-way switch) - fetched lazily via
/// student_record_detail (0056), not from the home dashboard payload.
class _RecordTab extends StatefulWidget {
  const _RecordTab({super.key, required this.orgId, required this.studentId, required this.serd});
  final String orgId;
  final String studentId;
  final SerdSummary? serd;

  @override
  State<_RecordTab> createState() => _RecordTabState();
}

class _RecordTabState extends State<_RecordTab> {
  final _portal = MyPortalRepository(AppSupabase.client);
  final _engagement = EngagementRepository(AppSupabase.client);
  int _segment = 0;
  late Future<_RecordData> _future = _load();

  Future<_RecordData> _load() async {
    final results = await Future.wait<dynamic>([
      _portal.fetchRecordDetail(widget.orgId, widget.studentId),
      _engagement.gradeLabels(widget.orgId).catchError((_) => <String, String>{}),
    ]);
    return _RecordData(results[0] as RecordDetail, results[1] as Map<String, String>);
  }

  bool _isThisMonth(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return AsyncBody<_RecordData>(
      future: _future,
      onRetry: () => setState(() => _future = _load()),
      builder: (context, rd) {
        final monthly = rd.detail.recitations.where((r) => _isThisMonth(r.createdAt)).toList();
        final monthlyAyahs = monthly.where((r) => r.type == 'new_memorization').fold<int>(0, (sum, r) => sum + (r.ayahTo - r.ayahFrom + 1));
        final monthlyAttendance = rd.detail.attendance.where((a) => _isThisMonth(a.date)).toList();
        final monthlyAttendanceRate =
            monthlyAttendance.isEmpty ? null : monthlyAttendance.where((a) => a.status == 'present').length / monthlyAttendance.length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 0, label: Text(t.record.tabRecitations)),
                  ButtonSegment(value: 1, label: Text(t.record.tabAttendance)),
                  ButtonSegment(value: 2, label: Text(t.record.tabSerd)),
                ],
                selected: {_segment},
                onSelectionChanged: (s) => setState(() => _segment = s.first),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: switch (_segment) {
                  0 => [
                      MonthlySummaryCard(
                        recitations: monthly.length,
                        ayahs: monthlyAyahs,
                        attendanceRate: monthlyAttendanceRate,
                        points: rd.detail.monthlyPoints,
                      ),
                      const SizedBox(height: 12),
                      PointsBreakdownCard(rows: rd.detail.pointsBreakdown, gradeLabels: rd.gradeLabels),
                      const SizedBox(height: 12),
                      if (rd.detail.recitations.isEmpty)
                        Padding(padding: const EdgeInsets.all(24), child: EmptyState(icon: Icons.history_edu_outlined, title: t.portal.noRecitations))
                      else
                        RecitationsSearchList(recitations: rd.detail.recitations),
                    ],
                  1 => [AttendanceListSection(rows: rd.detail.attendance)],
                  _ => [SerdSummaryCard(summary: widget.serd)],
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AccountTab extends StatelessWidget {
  const _AccountTab({required this.data});
  final PortalDashboard data;

  @override
  Widget build(BuildContext context) {
    final p = tr(context).portal;
    Widget row(IconData icon, String label, String? value) => ListTile(
          leading: Icon(icon),
          title: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          subtitle: Text(value == null || value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(child: InitialAvatar(data.fullName, radius: 38)),
        const SizedBox(height: 12),
        Text(data.fullName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              row(Icons.tag_rounded, p.studentCode, data.studentCode),
              row(Icons.groups_rounded, p.circle, data.circleName),
              row(Icons.stairs_rounded, p.stage, data.stageName),
              row(Icons.school_rounded, p.teacher, data.teacherName),
              row(Icons.phone_outlined, p.phone, data.phone),
              row(Icons.home_outlined, p.address, data.address),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const LanguagePicker(),
      ],
    );
  }
}

/// The app language picker (the portal's account tab; staff have it in the drawer).
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          const Icon(Icons.translate_rounded),
          const SizedBox(width: 12),
          Expanded(child: Text(tr(context).portal.languageHint, style: const TextStyle(fontWeight: FontWeight.w700))),
          SegmentedButton<String>(
            segments: [for (final l in kLocales) ButtonSegment(value: l, label: Text(kLocaleNames[l]!))],
            selected: {locale.effective},
            showSelectedIcon: false,
            onSelectionChanged: (s) => locale.choose(s.first),
          ),
        ]),
      ),
    );
  }
}
