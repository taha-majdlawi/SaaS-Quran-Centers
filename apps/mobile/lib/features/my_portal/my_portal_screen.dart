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

class _StudentPortalData {
  const _StudentPortalData({
    required this.student,
    required this.walletBalance,
    required this.badgeCount,
    required this.attendance,
    required this.serdSessions,
  });

  final PortalStudent student;
  final int walletBalance;
  final int badgeCount;
  final List<PortalAttendanceEntry> attendance;
  final List<PortalSerdEntry> serdSessions;
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
  late Future<List<_StudentPortalData>> _dataFuture;
  String? _loadedForOrgId;

  Future<List<_StudentPortalData>> _load(String orgId) async {
    final students = await _repository.fetchMyStudents(orgId);

    return Future.wait(students.map((student) async {
      final results = await Future.wait([
        _repository.fetchWalletBalance(student.id),
        _repository.fetchBadgeCount(student.id),
        _repository.fetchRecentAttendance(student.id),
        _repository.fetchRecentSerdSessions(student.id),
      ]);
      return _StudentPortalData(
        student: student,
        walletBalance: results[0] as int,
        badgeCount: results[1] as int,
        attendance: results[2] as List<PortalAttendanceEntry>,
        serdSessions: results[3] as List<PortalSerdEntry>,
      );
    }));
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
          : FutureBuilder<List<_StudentPortalData>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final data = snapshot.data!;
                if (data.isEmpty) {
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
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: data.length,
                  itemBuilder: (context, index) => _StudentCard(data: data[index]),
                );
              },
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
