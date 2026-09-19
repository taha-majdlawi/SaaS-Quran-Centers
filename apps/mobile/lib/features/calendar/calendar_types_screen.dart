import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import 'calendar_models.dart';
import 'calendar_repository.dart';

const _palette = ['#ef4444', '#f97316', '#eab308', '#22c55e', '#14b8a6', '#3b82f6', '#a855f7', '#ec4899', '#64748b'];

/// Admin: the per-center catalogue of entry types. A type decides whether its
/// entries are working days (they count in attendance %), whether students can
/// register, and whether a guardian must consent.
class CalendarTypesScreen extends StatefulWidget {
  const CalendarTypesScreen({super.key});

  @override
  State<CalendarTypesScreen> createState() => _CalendarTypesScreenState();
}

class _CalendarTypesScreenState extends State<CalendarTypesScreen> {
  final _repository = CalendarRepository(AppSupabase.client);
  late Future<CalRange> _future = _load();
  String? _message;
  bool _isError = false;

  String get _orgId => context.read<TenantController>().active!.organization.id;

  Future<CalRange> _load() => _repository.fetchRange(_orgId, DateTime.now(), DateTime.now());

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) setState(() { _message = 'تم الحفظ'; _isError = false; _future = _load(); });
    } on PostgrestException catch (e) {
      if (mounted) setState(() { _message = e.message; _isError = true; });
    }
  }

  Future<void> _edit(CalType? t, int nextOrder) async {
    final name = TextEditingController(text: t?.name ?? '');
    var color = t?.color ?? '#64748b';
    var working = t?.defaultIsWorking ?? true;
    var registration = t?.supportsRegistration ?? false;
    var consent = t?.requiresConsent ?? false;
    var active = t?.isActive ?? true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(t == null ? 'نوع جديد' : 'تعديل النوع'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم')),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in _palette)
                  GestureDetector(
                    onTap: () => setLocal(() => color = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: parseHexColor(c), shape: BoxShape.circle, border: Border.all(width: 3, color: color == c ? Colors.black87 : Colors.transparent)),
                    ),
                  ),
              ]),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('يوم دوام'), value: working, onChanged: (v) => setLocal(() => working = v)),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('يُسجَّل فيه'), value: registration, onChanged: (v) => setLocal(() => registration = v)),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('يحتاج موافقة ولي الأمر'), value: consent, onChanged: (v) => setLocal(() => consent = v)),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('فعّال'), value: active, onChanged: (v) => setLocal(() => active = v)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(minimumSize: const Size(90, 44)), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    final n = name.text.trim();
    name.dispose();
    if (ok != true) return;
    if (n.isEmpty) {
      setState(() { _message = 'اسم النوع مطلوب'; _isError = true; });
      return;
    }
    await _run(() => _repository.saveType(_orgId, id: t?.id, name: n, defaultIsWorking: working, color: color, sortOrder: t?.sortOrder ?? nextOrder, isActive: active, supportsRegistration: registration, requiresConsent: consent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أنواع عناصر التقويم')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final range = await _future;
          if (mounted) _edit(null, range.types.length + 1);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('نوع جديد'),
      ),
      body: AsyncBody<CalRange>(
        future: _future,
        onRetry: () => setState(() => _future = _load()),
        builder: (context, range) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Text('العناصر السابقة تحتفظ بإعداد نوعها وقت إضافتها، فتعديل النوع لا يغيّر نسب الحضور القديمة.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 10),
            if (_message != null) MessageBanner(message: _message!, isError: _isError),
            for (final t in range.types)
              Card(
                child: ListTile(
                  onTap: () => _edit(t, range.types.length + 1),
                  leading: CircleAvatar(backgroundColor: parseHexColor(t.color), radius: 12),
                  title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text([t.defaultIsWorking ? 'دوام' : 'غير دوام', if (t.supportsRegistration) 'يُسجَّل فيه', if (t.requiresConsent) 'موافقة ولي الأمر', if (!t.isActive) 'غير فعّال'].join('  ·  ')),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () => _run(() => _repository.deleteType(_orgId, t.id))),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
