import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import 'calendar_models.dart';
import 'calendar_repository.dart';

class _FormData {
  const _FormData({required this.types, required this.circles, required this.stages, this.entry});
  final List<CalType> types;
  final List<({String id, String name})> circles;
  final List<({String id, String name})> stages;
  final CalEntry? entry;
}

/// Admin: create / edit one calendar entry. The type decides the defaults
/// (working day? registration? consent?) - the entry keeps its own copy.
class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, this.entryId, this.initialDate});

  final String? entryId;
  final String? initialDate;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _repository = CalendarRepository(AppSupabase.client);
  late final Future<_FormData> _future = _load();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _capacity = TextEditingController();
  String? _typeId;
  String _audience = 'all';
  String? _circleId;
  String? _stageId;
  DateTime _start = DateTime.now();
  DateTime? _end;
  TimeOfDay? _time;
  DateTime? _deadline;
  bool _registrationOpen = true;
  bool _overrideWorking = false;
  bool _isWorking = true;
  bool _saving = false;
  String? _error;

  String get _orgId => context.read<TenantController>().active!.organization.id;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) _start = parseIsoDate(widget.initialDate!);
  }

  Future<_FormData> _load() async {
    final results = await Future.wait<dynamic>([
      _repository.fetchRange(_orgId, DateTime.now(), DateTime.now()),
      _repository.fetchCircles(_orgId),
      _repository.fetchStages(_orgId),
      if (widget.entryId != null) _repository.fetchDetails(_orgId, widget.entryId!),
    ]);
    final entry = widget.entryId != null ? results[3] as CalEntry : null;
    if (entry != null) {
      _title.text = entry.title;
      _description.text = entry.description ?? '';
      _location.text = entry.location ?? '';
      _capacity.text = entry.capacity?.toString() ?? '';
      _typeId = entry.typeId;
      _audience = entry.audience;
      _circleId = entry.circleId;
      _stageId = entry.stageId;
      _start = parseIsoDate(entry.startDate);
      _end = entry.endDate == entry.startDate ? null : parseIsoDate(entry.endDate);
      if (entry.startsAt != null) {
        final p = entry.startsAt!.split(':');
        _time = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
      _deadline = entry.registrationDeadline == null ? null : parseIsoDate(entry.registrationDeadline!);
      _registrationOpen = entry.registrationOpen;
      _isWorking = entry.isWorkingDay;
    }
    return _FormData(types: (results[0] as CalRange).types, circles: results[1] as List<({String id, String name})>, stages: results[2] as List<({String id, String name})>, entry: entry);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      );

  Future<void> _save() async {
    if (_typeId == null || _title.text.trim().isEmpty) {
      setState(() => _error = 'اختر النوع واكتب العنوان');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = await _repository.saveEntry(
        _orgId,
        id: widget.entryId,
        typeId: _typeId!,
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        start: _start,
        end: _end,
        isWorkingDay: _overrideWorking ? _isWorking : null,
        audience: _audience,
        circleId: _circleId,
        stageId: _stageId,
        startsAt: _time == null ? null : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        capacity: int.tryParse(_capacity.text.trim()),
        registrationOpen: _registrationOpen,
        deadline: _deadline,
      );
      if (!mounted) return;
      if (widget.entryId == null) {
        context.pushReplacement('/calendar/$id');
      } else {
        context.pop();
      }
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف'),
        content: const Text('سيُحذف هذا العنصر مع كل التسجيلات عليه. متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repository.deleteEntry(_orgId, widget.entryId!);
      if (mounted) context.go('/calendar');
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entryId == null ? 'إضافة إلى التقويم' : 'تعديل'),
        actions: [if (widget.entryId != null) IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete)],
      ),
      body: AsyncBody<_FormData>(
        future: _future,
        builder: (context, data) {
          final selected = data.types.where((t) => t.id == _typeId).firstOrNull;
          String d(DateTime? v) => v == null ? '—' : '${v.year}/${v.month}/${v.day}';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null) MessageBanner(message: _error!),
              DropdownButtonFormField<String>(
                initialValue: _typeId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'النوع'),
                items: [
                  for (final t in data.types.where((t) => t.isActive || t.id == _typeId))
                    DropdownMenuItem(value: t.id, child: Text('${t.name}${t.supportsRegistration ? ' — بتسجيل' : ''}${t.defaultIsWorking ? '' : ' — ليس دوامًا'}')),
                ],
                onChanged: (v) => setState(() => _typeId = v),
              ),
              const SizedBox(height: 12),
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'العنوان')),
              const SizedBox(height: 12),
              TextField(controller: _description, maxLines: 3, decoration: const InputDecoration(labelText: 'الوصف')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final p = await _pickDate(_start);
                      if (p != null) setState(() => _start = p);
                    },
                    child: Text('من: ${d(_start)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final p = await _pickDate(_end ?? _start);
                      if (p != null) setState(() => _end = p);
                    },
                    child: Text('إلى: ${d(_end)}'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final t = await showTimePicker(context: context, initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0));
                  if (t != null) setState(() => _time = t);
                },
                icon: const Icon(Icons.schedule_rounded, size: 18),
                label: Text(_time == null ? 'الساعة (اختياري)' : _time!.format(context)),
              ),
              const SizedBox(height: 12),
              TextField(controller: _location, decoration: const InputDecoration(labelText: 'المكان')),
              const SectionTitle('من يراها'),
              DropdownButtonFormField<String>(
                initialValue: _audience,
                decoration: const InputDecoration(labelText: 'الجمهور'),
                items: [for (final e in kAudienceLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setState(() => _audience = v ?? 'all'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _circleId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'حلقة محددة'),
                items: [const DropdownMenuItem<String?>(value: null, child: Text('كل الحلقات')), for (final c in data.circles) DropdownMenuItem<String?>(value: c.id, child: Text(c.name))],
                onChanged: (v) => setState(() => _circleId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _stageId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'مرحلة محددة'),
                items: [const DropdownMenuItem<String?>(value: null, child: Text('كل المراحل')), for (final s in data.stages) DropdownMenuItem<String?>(value: s.id, child: Text(s.name))],
                onChanged: (v) => setState(() => _stageId = v),
              ),
              const SectionTitle('الدوام'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تجاوز إعداد النوع'),
                subtitle: Text(selected == null ? '' : 'النوع يجعله ${selected.defaultIsWorking ? 'يوم دوام' : 'غير دوام'}'),
                value: _overrideWorking,
                onChanged: (v) => setState(() => _overrideWorking = v),
              ),
              if (_overrideWorking)
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('يوم دوام'), value: _isWorking, onChanged: (v) => setState(() => _isWorking = v)),
              Text('الأيام غير الدوام لا تُحتسب في نسبة حضور الطلاب.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              if (selected?.supportsRegistration ?? false) ...[
                const SectionTitle('التسجيل'),
                TextField(controller: _capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'عدد المقاعد (فارغ = بلا حد)')),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final p = await _pickDate(_deadline ?? _start);
                    if (p != null) setState(() => _deadline = p);
                  },
                  child: Text('إغلاق التسجيل في: ${d(_deadline)}'),
                ),
                if (_deadline != null) TextButton(onPressed: () => setState(() => _deadline = null), child: const Text('إزالة الموعد')),
                SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('التسجيل مفتوح'), value: _registrationOpen, onChanged: (v) => setState(() => _registrationOpen = v)),
              ],
              const SizedBox(height: 16),
              LoadingButton(label: 'حفظ', loading: _saving, onPressed: _save),
            ],
          );
        },
      ),
    );
  }
}
