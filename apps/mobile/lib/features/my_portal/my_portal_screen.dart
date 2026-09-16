import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'my_portal_repository.dart';

const _attendanceLabels = {
  'present': 'حاضر',
  'absent': 'غائب',
  'excused': 'معذور',
  'late': 'متأخر',
};

String _achievementSummary(PortalAchievementEntry a) {
  final label = kAchievementTypeLabels[a.achievementType] ?? a.achievementType;
  if (a.surahFrom == null) return label;
  final range = a.surahFrom == a.surahTo
      ? 'سورة ${a.surahFrom}: ${a.ayahFrom}-${a.ayahTo}'
      : 'سورة ${a.surahFrom}:${a.ayahFrom} - سورة ${a.surahTo}:${a.ayahTo}';
  return '$label · $range';
}

class _StudentPortalData {
  const _StudentPortalData({
    required this.student,
    required this.walletBalance,
    required this.badgeCount,
    required this.attendance,
    required this.serdSessions,
    required this.achievements,
  });

  final PortalStudent student;
  final int walletBalance;
  final int badgeCount;
  final List<PortalAttendanceEntry> attendance;
  final List<PortalSerdEntry> serdSessions;
  final List<PortalAchievementEntry> achievements;
}

class _PortalData {
  const _PortalData({required this.students, required this.upcomingEvents});
  final List<_StudentPortalData> students;
  final List<PortalUpcomingEvent> upcomingEvents;
}

/// The one screen student/guardian accounts ever see - app_router.dart
/// bounces them here for every other path. Mirrors apps/web's /my page:
/// their own linked student(s) only, nothing org-wide, no staff drawer.
class MyPortalScreen extends StatefulWidget {
  const MyPortalScreen({super.key});

  @override
  State<MyPortalScreen> createState() => _MyPortalScreenState();
}

class _MyPortalScreenState extends State<MyPortalScreen> {
  final _repository = MyPortalRepository(AppSupabase.client);
  late Future<_PortalData> _dataFuture;
  String? _loadedForOrgId;

  Future<_PortalData> _load(String orgId) async {
    final results = await Future.wait([
      _repository.fetchMyStudents(orgId),
      _repository.fetchUpcomingEvents(orgId),
    ]);
    final students = results[0] as List<PortalStudent>;
    final upcomingEvents = results[1] as List<PortalUpcomingEvent>;

    final studentData = await Future.wait(students.map((student) async {
      final studentResults = await Future.wait([
        _repository.fetchWalletBalance(student.id),
        _repository.fetchBadgeCount(student.id),
        _repository.fetchRecentAttendance(student.id),
        _repository.fetchRecentSerdSessions(student.id),
        _repository.fetchRecentAchievements(student.id),
      ]);
      return _StudentPortalData(
        student: student,
        walletBalance: studentResults[0] as int,
        badgeCount: studentResults[1] as int,
        attendance: studentResults[2] as List<PortalAttendanceEntry>,
        serdSessions: studentResults[3] as List<PortalSerdEntry>,
        achievements: studentResults[4] as List<PortalAchievementEntry>,
      );
    }));

    return _PortalData(students: studentData, upcomingEvents: upcomingEvents);
  }

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _dataFuture = _load(orgId);
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final org = tenant.active?.organization;
    final orgId = org?.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(org?.name ?? 'بستان القرآن'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل خروج',
            onPressed: () => context.read<AuthController>().signOut(),
          ),
        ],
      ),
      body: orgId == null
          ? const SizedBox.shrink()
          : FutureBuilder<_PortalData>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final data = snapshot.data!;
                if (data.students.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'لا يوجد ملف طالب مرتبط بحسابك حاليًا.\nتواصل مع إدارة المركز إذا كنت تتوقع رؤية بيانات هنا.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (data.upcomingEvents.isNotEmpty) _UpcomingEventsCard(events: data.upcomingEvents),
                    ...data.students.map((s) => _StudentCard(data: s)),
                  ],
                );
              },
            ),
    );
  }
}

class _UpcomingEventsCard extends StatelessWidget {
  const _UpcomingEventsCard({required this.events});
  final List<PortalUpcomingEvent> events;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الفعاليات القادمة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...events.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.event, size: 18, color: Color(0xFF0F766E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title),
                          Text(
                            '${e.startsAt}${e.location != null ? ' · ${e.location}' : ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.data});
  final _StudentPortalData data;

  @override
  Widget build(BuildContext context) {
    final s = data.student;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.fullName, style: Theme.of(context).textTheme.titleMedium),
                    Text(s.studentCode, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                Row(
                  children: [
                    _StatChip(label: 'نقاط', value: '${data.walletBalance}'),
                    const SizedBox(width: 8),
                    _StatChip(label: 'شارات', value: '${data.badgeCount}'),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Text('آخر الحضور', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            if (data.attendance.isEmpty)
              const Text('لا يوجد سجل حضور بعد', style: TextStyle(color: Colors.grey))
            else
              ...data.attendance.map(
                (a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(a.sessionDate),
                      Text(_attendanceLabels[a.status] ?? a.status),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text('آخر إنجازات الحفظ', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            if (data.achievements.isEmpty)
              const Text('لا توجد إنجازات مسجلة بعد', style: TextStyle(color: Colors.grey))
            else
              ...data.achievements.map(
                (a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(_achievementSummary(a))),
                      Text(
                        '+${a.pointsAwarded}',
                        style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text('جلسات السرد', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            if (data.serdSessions.isEmpty)
              const Text('لا توجد جلسات سرد بعد', style: TextStyle(color: Colors.grey))
            else
              ...data.serdSessions.map(
                (se) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(se.sessionType == 'full' ? 'سرد كامل' : 'سرد جزئي'),
                      Text(se.status),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
