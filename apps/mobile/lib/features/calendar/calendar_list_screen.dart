import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/ui.dart';
import 'calendar_models.dart';
import 'calendar_repository.dart';

/// The center calendar: a month grid (Sunday first, like the weekly pattern)
/// and the month's entries below. Grey days are non-working (weekly pattern or a
/// dated holiday/closure); a purple label marks serd days. Students and
/// guardians see the same screen, filtered to them by the server.
class CalendarListScreen extends StatefulWidget {
  const CalendarListScreen({super.key});

  @override
  State<CalendarListScreen> createState() => _CalendarListScreenState();
}

class _CalendarListScreenState extends State<CalendarListScreen> {
  final _repository = CalendarRepository(AppSupabase.client);
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Future<CalRange>? _future;
  String? _loadedForOrgId;
  String? _selectedDay;

  void _load(String orgId) {
    _loadedForOrgId = orgId;
    _future = _repository.fetchRange(orgId, _month, DateTime(_month.year, _month.month + 1, 0));
  }

  void _shift(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDay = null;
      _load(_loadedForOrgId!);
    });
  }

  Future<void> _editReminder() async {
    final orgId = _loadedForOrgId!;
    final messenger = ScaffoldMessenger.of(context);
    int current;
    try {
      current = await _repository.reminderHours(orgId);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('تعذّر تحميل الإعداد')));
      return;
    }
    if (!mounted) return;
    final controller = TextEditingController(text: '$current');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تذكير المسجّلين'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'قبل بدء الفعالية بـ (ساعة) — 0 = إيقاف', helperText: 'يصل التذكير لأولياء أمور الطلاب المسجّلين وللطلاب'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repository.setReminderHours(orgId, int.tryParse(controller.text.trim()) ?? 0);
      messenger.showSnackBar(const SnackBar(content: Text('حُفظ إعداد التذكير')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e is PostgrestException ? e.message : 'تعذّر الحفظ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final membership = context.watch<TenantController>().active;
    final orgId = membership?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) _load(orgId);
    final isAdmin = membership?.role == OrgRole.admin;
    final isStaff = membership?.role == OrgRole.admin || membership?.role == OrgRole.teacher;

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقويم والفعاليات'),
        actions: [
          if (isAdmin)
            IconButton(tooltip: 'التذكير قبل الفعالية', icon: const Icon(Icons.notifications_active_rounded), onPressed: _editReminder),
          if (isAdmin)
            IconButton(
              tooltip: 'أنواع العناصر',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () async {
                await context.push('/calendar/types');
                if (mounted) setState(() => _load(_loadedForOrgId!));
              },
            ),
        ],
      ),
      drawer: isStaff ? const AppDrawer() : null,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/calendar/new${_selectedDay == null ? '' : '?date=$_selectedDay'}');
                if (mounted) setState(() => _load(_loadedForOrgId!));
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة'),
            )
          : null,
      body: _future == null
          ? const SizedBox.shrink()
          : AsyncBody<CalRange>(
              future: _future!,
              onRetry: () => setState(() => _load(_loadedForOrgId!)),
              builder: (context, range) => RefreshIndicator(
                onRefresh: () async => setState(() => _load(_loadedForOrgId!)),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_right_rounded)),
                        Text('${kMonthNames[_month.month - 1]} ${_month.year}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_left_rounded)),
                      ],
                    ),
                    _MonthGrid(
                      month: _month,
                      range: range,
                      selectedDay: _selectedDay,
                      onSelect: (d) => setState(() => _selectedDay = _selectedDay == d ? null : d),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'أيام الدوام: ${range.workingDays} من ${range.totalDays}  ·  الرمادي = غير دوام  ·  «سرد» = يوم سرد',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                    SectionTitle(_selectedDay == null ? 'عناصر هذا الشهر' : 'عناصر يوم $_selectedDay'),
                    ..._entryList(range),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _entryList(CalRange range) {
    final entries = _selectedDay == null ? range.entries : range.entries.where((e) => e.covers(_selectedDay!)).toList();
    final serd = _selectedDay == null ? range.serd : range.serd.where((s) => s.date == _selectedDay).toList();
    if (entries.isEmpty && serd.isEmpty) {
      return const [Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا يوجد شيء')))];
    }
    return [
      for (final e in entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              onTap: () async {
                await context.push('/calendar/${e.id}');
                if (mounted) setState(() => _load(_loadedForOrgId!));
              },
              leading: Container(width: 6, height: 44, decoration: BoxDecoration(color: e.typeColor, borderRadius: BorderRadius.circular(4))),
              title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                [
                  formatDayRange(e.startDate, e.endDate),
                  e.typeName,
                  if (e.supportsRegistration) e.myRegistered ? 'أنت مسجّل ✓' : '${e.taken}${e.capacity == null ? '' : '/${e.capacity}'} مسجّل',
                ].join('  ·  '),
              ),
              trailing: e.isWorkingDay ? null : const StatusChip(label: 'غير دوام', color: Colors.grey),
            ),
          ),
        ),
      for (final s in serd)
        Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book_rounded, color: Colors.purple),
            title: Text('سرد مجدول: ${s.studentName}'),
            subtitle: Text(formatDayRange(s.date, s.date)),
          ),
        ),
    ];
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.range, required this.selectedDay, required this.onSelect});

  final DateTime month;
  final CalRange range;
  final String? selectedDay;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final lead = DateTime(month.year, month.month, 1).weekday % 7; // Sunday = 0
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = <int?>[...List<int?>.filled(lead, null), for (var d = 1; d <= days; d++) d];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final today = isoDate(DateTime.now());
    final scheme = Theme.of(context).colorScheme;

    Widget header(int dow) {
      final w = range.weekday(dow);
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: [
            Text(w?.label ?? '$dow', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            if (w?.isSerdDay ?? false) const Text('●', style: TextStyle(fontSize: 8, color: Colors.purple)),
          ]),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [for (var d = 0; d < 7; d++) header(d)]),
        for (var r = 0; r < cells.length ~/ 7; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(child: _cell(context, cells[r * 7 + c], c, today, scheme)),
            ],
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, int? day, int dow, String today, ColorScheme scheme) {
    if (day == null) return const SizedBox(height: 56);
    final iso = isoDate(DateTime(month.year, month.month, day));
    final entries = range.entries.where((e) => e.covers(iso)).toList();
    final closed = !(range.weekday(dow)?.isWorking ?? true) || entries.any((e) => !e.isWorkingDay);
    final serd = range.serd.any((s) => s.date == iso) || ((range.weekday(dow)?.isSerdDay ?? false) && !closed);
    final selected = selectedDay == iso;

    return InkWell(
      onTap: () => onSelect(iso),
      child: Container(
        height: 56,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withValues(alpha: 0.15) : (closed ? Colors.grey.shade200 : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: iso == today ? scheme.primary : Colors.grey.shade200, width: iso == today ? 2 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$day', style: TextStyle(fontWeight: FontWeight.w700, color: closed ? Colors.grey : null)),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final e in entries.take(3))
                  Container(width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: BoxDecoration(color: e.typeColor, shape: BoxShape.circle)),
                if (serd) const Text('سرد', style: TextStyle(fontSize: 8, color: Colors.purple)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
