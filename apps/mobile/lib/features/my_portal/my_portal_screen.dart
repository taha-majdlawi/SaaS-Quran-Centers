import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/data/quran_data.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/org_avatar.dart';
import '../../core/widgets/ui.dart';
import '../recitation/recitation_repository.dart' show kAchievementTypes;
import '../serd/serd_widgets.dart';
import 'my_portal_repository.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          if (org != null) OrgAvatar(name: org.name, logoUrl: org.logoUrl, brandColor: org.primaryColor, size: 34),
          const SizedBox(width: 10),
          Flexible(child: Text(org?.name ?? 'بستان القرآن', overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'تسجيل خروج',
            onPressed: () => context.read<AuthController>().signOut(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.history_edu_outlined), selectedIcon: Icon(Icons.history_edu_rounded), label: 'سجلّي'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'حسابي'),
        ],
      ),
      body: _loadingStudents
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(onRetry: () => _loadStudents(org!.id))
              : _students.isEmpty
                  ? EmptyState(
                      icon: Icons.link_off_rounded,
                      title: isGuardian ? 'لا يوجد أبناء مرتبطون بحسابك' : 'حسابك غير مرتبط بملف طالب',
                      subtitle: 'تواصل مع إدارة المركز لربط الحساب',
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
                                    padding: const EdgeInsets.only(left: 8),
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
                                return const EmptyState(icon: Icons.link_off_rounded, title: 'تعذّر إيجاد ملف الطالب');
                              }
                              return RefreshIndicator(
                                onRefresh: () async => _reload(),
                                child: switch (_tab) {
                                  0 => _HomeTab(data: data),
                                  1 => _RecordTab(data: data),
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
    final firstName = data.fullName.split(' ').first;
    final change = data.thisWeek - data.lastWeek;
    final weekText = change > 0
        ? 'أفضل من الأسبوع الماضي (+$change)'
        : change < 0
            ? 'أقل من الأسبوع الماضي ($change)'
            : 'ثابت مقارنة بالأسبوع الماضي';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
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
                    Text('مرحبًا، $firstName', style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      data.circleName == null
                          ? 'لم تُسند إلى حلقة بعد'
                          : '${data.circleName}${data.teacherName == null ? '' : '  ·  الشيخ ${data.teacherName}'}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('${data.totalPoints}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                  Text('نقطة', style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ],
          ),
        ),
        const SectionTitle('تقدّم الحفظ'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${data.totalParts} من 30 جزءًا', style: const TextStyle(fontWeight: FontWeight.w700)),
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
                    child: Text('خطتك القادمة: ${data.nextPlan}'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SectionTitle('إحصائياتك'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _Stat(icon: Icons.menu_book_rounded, label: 'آيات هذا الأسبوع', value: '${data.ayahsThisWeek}', color: Colors.blue),
            _Stat(
              icon: Icons.how_to_reg_rounded,
              label: 'الحضور الأسبوعي',
              value: data.weeklyAttendance == null ? '—' : '${data.weeklyAttendance}%',
              color: Colors.green,
            ),
            _Stat(icon: Icons.mic_rounded, label: 'إجمالي التسميعات', value: '${data.totalRecitations}', color: Colors.purple),
            _Stat(icon: Icons.schedule_rounded, label: 'آخر تسميع', value: formatDate(data.lastRecitationAt), color: Colors.orange),
          ],
        ),
        const SectionTitle('أسبوعك'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data.thisWeek} تسميعات هذا الأسبوع', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(weekText, style: TextStyle(color: Colors.grey.shade600)),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange.shade400),
                    const SizedBox(width: 8),
                    Text('سلسلتك الحالية: ${data.currentStreak} يوم  ·  أطول سلسلة: ${data.longestStreak}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!context.watch<TenantController>().isDisabled('calendar'))
        Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_month_rounded),
            title: const Text('التقويم والفعاليات', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('الإجازات والرحلات والمسابقات والتسجيل فيها'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () => context.push('/calendar'),
          ),
        ),
        Row(children: [
          if (!context.watch<TenantController>().isDisabled('chat'))
          Expanded(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.chat_bubble_rounded),
                title: const Text('المحادثات', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => context.push('/chat'),
              ),
            ),
          ),
          if (!context.watch<TenantController>().isDisabled('announcements'))
          Expanded(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.campaign_rounded),
                title: const Text('الإعلانات', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => context.push('/announcements'),
              ),
            ),
          ),
        ]),
        if (!context.watch<TenantController>().isDisabled('reports'))
        Card(
          child: ListTile(
            leading: const Icon(Icons.insights_rounded),
            title: const Text('التقرير', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('التسميع والحضور والسرد لفترة تختارها'),
            onTap: () => context.push('/my/report'),
          ),
        ),
        if (!context.watch<TenantController>().isDisabled('certificates'))
        Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium_rounded),
            title: const Text('الشهادات', style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => context.push('/my/certificates'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.auto_stories_rounded),
            title: const Text('المصحف', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('قراءة واستماع وعلامات'),
            onTap: () => context.push('/quran'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.notifications_rounded),
            title: const Text('الإشعارات', style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => context.push('/notifications'),
          ),
        ),
        Row(children: [
          if (!context.watch<TenantController>().isDisabled('badges'))
          Expanded(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.emoji_events_rounded),
                title: const Text('الشارات', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => context.push('/my/badges'),
              ),
            ),
          ),
          if (!context.watch<TenantController>().isDisabled('market'))
          Expanded(
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.storefront_rounded),
                title: const Text('السوق', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => context.push('/my/market'),
              ),
            ),
          ),
        ]),
        const SectionTitle('السرد القرآني'),
        SerdSummaryCard(summary: data.serd),
        const SectionTitle('آخر التسميعات'),
        if (data.recent.isEmpty)
          const Padding(padding: EdgeInsets.all(12), child: Text('لا يوجد تسميعات بعد'))
        else
          for (final r in data.recent.take(5)) _RecitationTile(r: r),
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

class _RecitationTile extends StatelessWidget {
  const _RecitationTile({required this.r});
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

class _RecordTab extends StatelessWidget {
  const _RecordTab({required this.data});
  final PortalDashboard data;

  @override
  Widget build(BuildContext context) {
    if (data.recent.isEmpty) {
      return ListView(children: const [SizedBox(height: 80), EmptyState(icon: Icons.history_edu_outlined, title: 'لا يوجد تسميعات بعد')]);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Mini(label: 'تسميعات', value: '${data.totalRecitations}'),
                _Mini(label: 'الأسبوع', value: '${data.thisWeek}'),
                _Mini(label: 'نقاط', value: '${data.totalPoints}'),
              ],
            ),
          ),
        ),
        const SectionTitle('سجل التسميع'),
        for (final r in data.recent) _RecitationTile(r: r),
      ],
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ],
      );
}

class _AccountTab extends StatelessWidget {
  const _AccountTab({required this.data});
  final PortalDashboard data;

  @override
  Widget build(BuildContext context) {
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
              row(Icons.tag_rounded, 'رقم الطالب', data.studentCode),
              row(Icons.groups_rounded, 'الحلقة', data.circleName),
              row(Icons.stairs_rounded, 'المرحلة', data.stageName),
              row(Icons.school_rounded, 'الشيخ', data.teacherName),
              row(Icons.phone_outlined, 'الجوال', data.phone),
              row(Icons.home_outlined, 'العنوان', data.address),
            ],
          ),
        ),
      ],
    );
  }
}
