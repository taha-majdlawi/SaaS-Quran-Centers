import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/offline/offline_cache.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import 'my_portal_repository.dart';

const _attendanceLabels = {
  'present': 'حاضر',
  'absent': 'غائب',
  'excused': 'معذور',
  'late': 'متأخر',
};

String? _registrationIdFor(List<PortalRegistration> registrations, String eventId, String studentId) {
  for (final r in registrations) {
    if (r.eventId == eventId && r.studentId == studentId) return r.id;
  }
  return null;
}

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
    required this.consentEvents,
  });

  final PortalStudent student;
  final int walletBalance;
  final int badgeCount;
  final List<PortalAttendanceEntry> attendance;
  final List<PortalSerdEntry> serdSessions;
  final List<PortalAchievementEntry> achievements;
  final List<_ConsentEvent> consentEvents;

  // Consent isn't cached - see _PortalData.toJson's comment - so this
  // always round-trips with an empty consentEvents, same as fromJson below.
  Map<String, dynamic> toJson() => {
        'student': student.toJson(),
        'wallet_balance': walletBalance,
        'badge_count': badgeCount,
        'attendance': attendance.map((a) => a.toJson()).toList(),
        'serd_sessions': serdSessions.map((s) => s.toJson()).toList(),
        'achievements': achievements.map((a) => a.toJson()).toList(),
      };

  factory _StudentPortalData.fromJson(Map<String, dynamic> j) => _StudentPortalData(
        student: PortalStudent.fromJson(j['student'] as Map<String, dynamic>),
        walletBalance: j['wallet_balance'] as int,
        badgeCount: j['badge_count'] as int,
        attendance: (j['attendance'] as List).map((a) => PortalAttendanceEntry.fromJson(a as Map<String, dynamic>)).toList(),
        serdSessions: (j['serd_sessions'] as List).map((s) => PortalSerdEntry.fromJson(s as Map<String, dynamic>)).toList(),
        achievements:
            (j['achievements'] as List).map((a) => PortalAchievementEntry.fromJson(a as Map<String, dynamic>)).toList(),
        consentEvents: const [],
      );
}

/// An upcoming event that requires guardian consent, paired with this
/// student's registration id if consent was already given (null = pending).
class _ConsentEvent {
  const _ConsentEvent({required this.event, this.registrationId});
  final PortalUpcomingEvent event;
  final String? registrationId;
}

class _PortalData {
  const _PortalData({
    required this.students,
    required this.upcomingEvents,
    this.myMemberId,
    this.fromCache = false,
  });
  final List<_StudentPortalData> students;
  final List<PortalUpcomingEvent> upcomingEvents;
  final String? myMemberId;
  final bool fromCache;

  // No consent state (registrations, myMemberId) cached - it's only ever
  // useful live anyway, since giving/withdrawing consent needs a connection
  // regardless, so a cached "already consented" button would just be a
  // convincing lie while offline. Guardians still see everything else.
  Map<String, dynamic> toJson() => {
        'students': students.map((s) => s.toJson()).toList(),
        'upcoming_events': upcomingEvents.map((e) => e.toJson()).toList(),
      };

  factory _PortalData.fromJson(Map<String, dynamic> j) => _PortalData(
        students: (j['students'] as List).map((s) => _StudentPortalData.fromJson(s as Map<String, dynamic>)).toList(),
        upcomingEvents:
            (j['upcoming_events'] as List).map((e) => PortalUpcomingEvent.fromJson(e as Map<String, dynamic>)).toList(),
        fromCache: true,
      );
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
  String? _error;
  bool _consentBusy = false;

  // Same read-through pattern as dashboard_screen.dart: try live, cache on
  // success, fall back to the last cached value only if the live fetch
  // itself throws.
  Future<_PortalData> _load(String orgId, OrgRole role) async {
    final cacheKey = 'my_portal:$orgId';
    try {
      final data = await _loadLive(orgId, role);
      await OfflineCache.put(cacheKey, data.toJson());
      return data;
    } catch (e) {
      final cached = await OfflineCache.get(cacheKey);
      if (cached != null) return _PortalData.fromJson(cached as Map<String, dynamic>);
      rethrow;
    }
  }

  Future<_PortalData> _loadLive(String orgId, OrgRole role) async {
    final results = await Future.wait([
      _repository.fetchMyStudents(orgId),
      _repository.fetchUpcomingEvents(orgId),
    ]);
    final students = results[0] as List<PortalStudent>;
    final upcomingEvents = results[1] as List<PortalUpcomingEvent>;

    // Only a guardian acts on consent - a student's own login sees the
    // events (below, read-only) but can't give consent for themselves.
    final isGuardian = role == OrgRole.guardian;
    final consentRequiredEvents = upcomingEvents.where((e) => e.requiresGuardianConsent).toList();

    final results2 = await Future.wait([
      isGuardian && consentRequiredEvents.isNotEmpty
          ? _repository.fetchRegistrations(
              studentIds: students.map((s) => s.id).toList(),
              eventIds: consentRequiredEvents.map((e) => e.id).toList(),
            )
          : Future.value(const <PortalRegistration>[]),
      isGuardian ? _repository.fetchMyMemberId(orgId) : Future<String?>.value(null),
    ]);
    final registrations = results2[0] as List<PortalRegistration>;
    final myMemberId = results2[1] as String?;

    final studentData = await Future.wait(students.map((student) async {
      final studentResults = await Future.wait([
        _repository.fetchWalletBalance(student.id),
        _repository.fetchBadgeCount(student.id),
        _repository.fetchRecentAttendance(student.id),
        _repository.fetchRecentSerdSessions(student.id),
        _repository.fetchRecentAchievements(student.id),
      ]);
      final consentEvents = isGuardian
          ? consentRequiredEvents
              .map((e) => _ConsentEvent(event: e, registrationId: _registrationIdFor(registrations, e.id, student.id)))
              .toList()
          : const <_ConsentEvent>[];
      return _StudentPortalData(
        student: student,
        walletBalance: studentResults[0] as int,
        badgeCount: studentResults[1] as int,
        attendance: studentResults[2] as List<PortalAttendanceEntry>,
        serdSessions: studentResults[3] as List<PortalSerdEntry>,
        achievements: studentResults[4] as List<PortalAchievementEntry>,
        consentEvents: consentEvents,
      );
    }));

    return _PortalData(students: studentData, upcomingEvents: upcomingEvents, myMemberId: myMemberId);
  }

  void _reload(String orgId, OrgRole role) {
    _loadedForOrgId = orgId;
    _dataFuture = _load(orgId, role);
  }

  Future<void> _giveConsent(String orgId, OrgRole role, String eventId, String studentId, String? myMemberId) async {
    setState(() {
      _consentBusy = true;
      _error = null;
    });
    try {
      await _repository.giveConsent(eventId: eventId, studentId: studentId, guardianMemberId: myMemberId);
      if (mounted) setState(() => _reload(orgId, role));
    } catch (e) {
      if (mounted) setState(() => _error = 'حدث خطأ أثناء تسجيل الموافقة - حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _consentBusy = false);
    }
  }

  Future<void> _withdrawConsent(String orgId, OrgRole role, String registrationId) async {
    setState(() {
      _consentBusy = true;
      _error = null;
    });
    try {
      await _repository.withdrawConsent(registrationId);
      if (mounted) setState(() => _reload(orgId, role));
    } catch (e) {
      if (mounted) setState(() => _error = 'حدث خطأ أثناء إلغاء الموافقة - حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _consentBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final org = tenant.active?.organization;
    final orgId = org?.id;
    final role = tenant.active?.role;
    if (orgId != null && role != null && orgId != _loadedForOrgId) {
      _reload(orgId, role);
    }
    final isGuardian = role == OrgRole.guardian;

    return Scaffold(
      appBar: AppBar(
        title: Text(org?.name ?? 'بستان القرآن'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'المحادثات',
            onPressed: () => context.push('/chat'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل خروج',
            onPressed: () => context.read<AuthController>().signOut(),
          ),
        ],
      ),
      body: orgId == null || role == null
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
                // Consent-required events already get an actionable per-student
                // slot in _StudentCard below - showing them again here too would
                // just be noise for the guardian who's the one who can act on them.
                final generalEvents =
                    isGuardian ? data.upcomingEvents.where((e) => !e.requiresGuardianConsent).toList() : data.upcomingEvents;
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (data.fromCache)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                        child: const Text(
                          'غير متصل - هاي آخر بيانات محفوظة',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                      ),
                    if (generalEvents.isNotEmpty) _UpcomingEventsCard(events: generalEvents),
                    ...data.students.map((s) => _StudentCard(
                          data: s,
                          busy: _consentBusy,
                          onGiveConsent: (eventId) => _giveConsent(orgId, role, eventId, s.student.id, data.myMemberId),
                          onWithdrawConsent: (registrationId) => _withdrawConsent(orgId, role, registrationId),
                        )),
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
                    Icon(Icons.event, size: 18, color: Theme.of(context).colorScheme.primary),
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
  const _StudentCard({
    required this.data,
    required this.busy,
    required this.onGiveConsent,
    required this.onWithdrawConsent,
  });
  final _StudentPortalData data;
  final bool busy;
  final void Function(String eventId) onGiveConsent;
  final void Function(String registrationId) onWithdrawConsent;

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
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            if (data.consentEvents.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('فعاليات تحتاج موافقتك', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              ...data.consentEvents.map(
                (c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.event.title),
                            Text(
                              c.event.startsAt,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (c.registrationId != null)
                        TextButton(
                          onPressed: busy ? null : () => onWithdrawConsent(c.registrationId!),
                          child: const Text('إلغاء الموافقة', style: TextStyle(color: Colors.red)),
                        )
                      else
                        FilledButton(
                          onPressed: busy ? null : () => onGiveConsent(c.event.id),
                          child: const Text('الموافقة على الحضور'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
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
