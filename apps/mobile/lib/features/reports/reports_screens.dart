import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/ui.dart';
import 'reports_repository.dart';

DateTime _monthStart() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, 1);
}

class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.from, required this.to, required this.onChanged});

  final DateTime from;
  final DateTime to;
  final void Function(DateTime from, DateTime to) onChanged;

  Future<void> _pick(BuildContext context, bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? from : to,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    isFrom ? onChanged(picked, to.isBefore(picked) ? picked : to) : onChanged(from.isAfter(picked) ? picked : from, picked);
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: OutlinedButton.icon(onPressed: () => _pick(context, true), icon: const Icon(Icons.event_rounded, size: 18), label: Text('من ${reportDate(from)}'))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton.icon(onPressed: () => _pick(context, false), icon: const Icon(Icons.event_rounded, size: 18), label: Text('إلى ${reportDate(to)}'))),
    ]);
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value);

  final String label;
  final Object value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 16 * 2 - 8) / 2,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
          ]),
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> _list(dynamic v) => [for (final e in (v as List? ?? const [])) e as Map<String, dynamic>];

// ---------------------------------------------------------------------------
// Center-wide report (staff with the "reports" module)
// ---------------------------------------------------------------------------

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _repository = ReportsRepository(AppSupabase.client);
  DateTime _from = _monthStart();
  DateTime _to = DateTime.now();
  Future<Map<String, dynamic>>? _future;
  String? _orgId;

  Future<Map<String, dynamic>> _load() => _repository.center(_orgId!, _from, _to);

  String _summary(Map<String, dynamic> r, String center) {
    final t = r['totals'] as Map<String, dynamic>;
    final b = StringBuffer()
      ..writeln('تقرير $center')
      ..writeln('${r['from']} → ${r['to']}')
      ..writeln('الطلاب النشطون: ${t['students_active']}')
      ..writeln('التسميعات: ${t['recitations']} (${t['reciting_students']} طالب)')
      ..writeln('النقاط: ${t['points']}')
      ..writeln('نسبة الحضور: ${reportPct(t['attendance_rate'])}')
      ..writeln('سرد معتمد: ${t['serd_approved']}');
    for (final c in _list(r['circles'])) {
      b.writeln('• ${c['name']}: ${c['recitations']} تسميع، حضور ${reportPct(c['attendance_rate'])}');
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final org = context.watch<TenantController>().active?.organization;
    if (org == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_orgId != org.id) {
      _orgId = org.id;
      _future = _load();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      drawer: const AppDrawer(),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _RangeBar(
          from: _from,
          to: _to,
          onChanged: (f, t) => setState(() {
            _from = f;
            _to = t;
            _future = _load();
          }),
        ),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              final e = snap.error;
              return ErrorState(message: e is PostgrestException ? e.message : 'تعذّر تحميل التقرير', onRetry: () => setState(() => _future = _load()));
            }
            final r = snap.data;
            if (r == null) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
            final t = r['totals'] as Map<String, dynamic>;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                _Kpi('الطلاب النشطون', t['students_active']),
                _Kpi('طلاب جدد', t['new_students']),
                _Kpi('التسميعات', t['recitations']),
                _Kpi('طلاب سمّعوا', t['reciting_students']),
                _Kpi('النقاط', t['points']),
                _Kpi('نسبة الحضور', reportPct(t['attendance_rate'])),
                _Kpi('سرد معتمد', '${t['serd_approved']}${t['serd_average'] != null ? ' · ${t['serd_average']}%' : ''}'),
                _Kpi('شهادات صدرت', t['certificates']),
              ]),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _summary(r, org.name)));
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نُسخ ملخص التقرير')));
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('نسخ الملخص'),
              ),
              const SectionTitle('أنواع التسميع'),
              for (final x in _list(r['by_type']))
                ListTile(dense: true, title: Text(kReportTypeLabels[x['type']] ?? '${x['type']}'), trailing: Text('${x['count']}', style: const TextStyle(fontWeight: FontWeight.w700))),
              const SectionTitle('الحضور'),
              for (final k in ['present', 'late', 'absent', 'excused'])
                ListTile(dense: true, title: Text(kReportAttendanceLabels[k]!), trailing: Text('${t['attendance_$k']}', style: const TextStyle(fontWeight: FontWeight.w700))),
              const SectionTitle('الحلقات'),
              for (final c in _list(r['circles']))
                Card(
                  child: ListTile(
                    title: Text('${c['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${c['teacher'] ?? '—'} · ${c['students']} طالب\nتسميعات ${c['recitations']} · نقاط ${c['points']} · حضور ${reportPct(c['attendance_rate'])}'),
                    isThreeLine: true,
                  ),
                ),
              const SectionTitle('المعلمون'),
              for (final x in _list(r['teachers']))
                ListTile(dense: true, title: Text('${x['name'] ?? '—'}'), trailing: Text('${x['recitations']} تسميع · ${x['points']} نقطة')),
              const SectionTitle('الأعلى نقاطًا'),
              for (final (i, s) in _list(r['top_students']).indexed)
                ListTile(
                  dense: true,
                  leading: CircleAvatar(radius: 14, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                  title: Text('${s['name']}'),
                  subtitle: Text('${s['circle'] ?? '—'}'),
                  trailing: Text('${s['points']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  onTap: () => context.push('/students/${s['id']}/report'),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// One student's report: staff (route /students/:id/report) and the family
// portal (/my/report, with a picker when a guardian has several children)
// ---------------------------------------------------------------------------

class StudentReportScreen extends StatefulWidget {
  const StudentReportScreen({super.key, this.studentId, this.portal = false});

  final String? studentId;
  final bool portal;

  @override
  State<StudentReportScreen> createState() => _StudentReportScreenState();
}

class _StudentReportScreenState extends State<StudentReportScreen> {
  final _repository = ReportsRepository(AppSupabase.client);
  DateTime _from = _monthStart();
  DateTime _to = DateTime.now();
  String? _orgId;
  String? _studentId;
  List<({String id, String name})> _students = const [];
  Future<Map<String, dynamic>?>? _future;

  Future<Map<String, dynamic>?> _load() async {
    if (widget.portal) {
      _students = await _repository.myStudents(_orgId!);
      if (_students.isEmpty) return null;
      _studentId ??= _students.first.id;
    } else {
      _studentId = widget.studentId;
    }
    return _repository.student(_orgId!, _studentId!, _from, _to);
  }

  @override
  Widget build(BuildContext context) {
    final org = context.watch<TenantController>().active?.organization;
    if (org == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_orgId != org.id) {
      _orgId = org.id;
      _future = _load();
    }
    void reload() => setState(() => _future = _load());

    return Scaffold(
      appBar: AppBar(title: const Text('تقرير الطالب')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _RangeBar(from: _from, to: _to, onChanged: (f, t) {
          _from = f;
          _to = t;
          reload();
        }),
        if (widget.portal && _students.length > 1) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _studentId,
            decoration: const InputDecoration(labelText: 'الطالب'),
            items: [for (final s in _students) DropdownMenuItem(value: s.id, child: Text(s.name))],
            onChanged: (v) {
              _studentId = v;
              reload();
            },
          ),
        ],
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>?>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              final e = snap.error;
              return ErrorState(message: e is PostgrestException ? e.message : 'تعذّر تحميل التقرير', onRetry: reload);
            }
            if (snap.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
            final r = snap.data;
            if (r == null) return const EmptyState(icon: Icons.person_off_rounded, title: 'لا يوجد طالب مرتبط بحسابك');
            return _StudentBody(r: r, portal: widget.portal);
          },
        ),
      ]),
    );
  }
}

class _StudentBody extends StatelessWidget {
  const _StudentBody({required this.r, required this.portal});

  final Map<String, dynamic> r;
  final bool portal;

  @override
  Widget build(BuildContext context) {
    final s = r['student'] as Map<String, dynamic>;
    final rec = r['recitations'] as Map<String, dynamic>;
    final att = r['attendance'] as Map<String, dynamic>;
    final certs = _list(r['certificates']);
    final badges = _list(r['badges']);
    final serd = _list(r['serd']);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${s['name']}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      Text('${s['code']}${s['circle'] != null ? ' · ${s['circle']}' : ''}${s['teacher'] != null ? ' · المعلم: ${s['teacher']}' : ''}', style: TextStyle(color: Colors.grey.shade600)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _Kpi('تسميعات الفترة', rec['count']),
        _Kpi('نقاط الفترة', rec['points']),
        _Kpi('الحضور', reportPct(att['rate'])),
        _Kpi('مجموع النقاط', s['total_points']),
      ]),
      const SectionTitle('التقدّم'),
      ListTile(dense: true, title: const Text('الأجزاء المحفوظة'), trailing: Text('${s['parts_count'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700))),
      for (final x in _list(rec['by_type']))
        ListTile(dense: true, title: Text(kReportTypeLabels[x['type']] ?? '${x['type']}'), trailing: Text('${x['count']}')),
      const SectionTitle('الحضور'),
      for (final k in ['present', 'late', 'absent', 'excused'])
        ListTile(dense: true, title: Text(kReportAttendanceLabels[k]!), trailing: Text('${att[k]}')),
      if (serd.isNotEmpty) ...[
        const SectionTitle('السرد القرآني'),
        for (final q in serd)
          ListTile(
            dense: true,
            title: Text('${reportDay(q['date'])} · جزء ${(q['juz'] as List).join('، ')}'),
            trailing: Text('${q['score'] != null ? '${q['score']}%' : '—'} · ${q['status'] == 'approved' ? 'معتمد' : q['status'] == 'rejected' ? 'مرفوض' : 'بانتظار'}'),
          ),
      ],
      if (badges.isNotEmpty) ...[
        const SectionTitle('الشارات'),
        Wrap(spacing: 6, children: [for (final b in badges) Chip(label: Text('${b['name']}'))]),
      ],
      if (certs.isNotEmpty) ...[
        const SectionTitle('الشهادات'),
        for (final c in certs)
          ListTile(
            dense: true,
            leading: const Icon(Icons.workspace_premium_rounded),
            title: Text('${c['title']}'),
            onTap: () => context.push(portal ? '/my/certificates/${c['id']}' : '/certificates/${c['id']}'),
          ),
      ],
      const SectionTitle('سجل التسميع'),
      if (_list(rec['rows']).isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('لا تسميعات في هذه الفترة')),
      for (final x in _list(rec['rows']))
        ListTile(
          dense: true,
          title: Text('${kReportTypeLabels[x['type']] ?? x['type']} · سورة ${x['surah_from'] ?? ''} (${x['ayah_from'] ?? ''}–${x['ayah_to'] ?? ''})'),
          subtitle: Text('${reportDay(x['at'])}${x['grade'] != null ? ' · ${x['grade']}' : ''}'),
          trailing: Text('+${x['points']}'),
        ),
    ]);
  }
}
