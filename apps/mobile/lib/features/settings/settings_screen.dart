import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/ui.dart';
import '../quran/quran_data.dart' show kReciters;
import 'settings_repository.dart';

/// Mirrors apps/web's /settings page - admin-editable org name, branding
/// colors (hex text), timezone, working days and the per-center switches that
/// eqraa hard-codes (back-date window, feature flags, prayer times).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repository = SettingsRepository(AppSupabase.client);
  final _nameController = TextEditingController();
  final _logoController = TextEditingController();
  final _primaryColorController = TextEditingController();
  final _secondaryColorController = TextEditingController();
  final _timezoneController = TextEditingController(text: 'Asia/Amman');
  final _textSettings = {for (final k in kTextSettingKeys) k: TextEditingController()};
  final _flags = {for (final k in kFlagSettingKeys) k: false};
  List<WeekdayRow> _weekdays = [];
  final Set<String> _reciterSet = {};

  String? _loadedForOrgId;
  String? _saving; // 'org' | 'days' | 'center'
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _logoController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    _timezoneController.dispose();
    for (final c in _textSettings.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load(Organization org) async {
    _loadedForOrgId = org.id;
    _nameController.text = org.name;
    _logoController.text = org.logoUrl ?? '';
    _primaryColorController.text = org.primaryColor;
    _secondaryColorController.text = org.secondaryColor;
    try {
      final results = await Future.wait<dynamic>([
        _repository.fetchWeekdays(org.id),
        _repository.fetchCenterSettings(org.id),
      ]);
      final settings = results[1] as Map<String, String>;
      _weekdays = results[0] as List<WeekdayRow>;
      for (final e in _textSettings.entries) {
        e.value.text = settings[e.key] ?? '';
      }
      for (final k in _flags.keys) {
        _flags[k] = settings[k] == 'true';
      }
      _reciterSet
        ..clear()
        ..addAll((settings['quran_reciters'] ?? '').split(',').where((e) => e.trim().isNotEmpty));
    } catch (_) {
      _message = 'تعذّر تحميل بعض الإعدادات';
      _isError = true;
    }
    if (mounted) setState(() {});
  }

  Future<void> _run(String section, Future<void> Function() action) async {
    setState(() {
      _saving = section;
      _message = null;
    });
    try {
      await action();
      if (mounted) setState(() { _message = 'تم حفظ الإعدادات'; _isError = false; });
    } catch (_) {
      if (mounted) setState(() { _message = 'حدث خطأ أثناء الحفظ'; _isError = true; });
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  Future<void> _saveOrg(String orgId) async {
    final logo = _logoController.text.trim();
    if (logo.isNotEmpty && !(Uri.tryParse(logo)?.scheme == 'https')) {
      setState(() {
        _message = 'رابط الشعار يجب أن يبدأ بـ https';
        _isError = true;
      });
      return;
    }
    await _run('org', () {
        return _repository.updateOrgSettings(
          organizationId: orgId,
          name: _nameController.text.trim(),
          logoUrl: logo.isEmpty ? null : logo,
          primaryColor: _primaryColorController.text.trim(),
          secondaryColor: _secondaryColorController.text.trim(),
          timezone: _timezoneController.text.trim(),
        );
      });
    if (mounted && _isError == false) await context.read<TenantController>().refreshSilently();
  }

  Future<void> _saveDays(String orgId) => _run('days', () => _repository.saveWeekdays(orgId, _weekdays));

  Future<void> _saveCenter(String orgId) async {
    final backdate = int.tryParse(_textSettings['backdate_days']!.text.trim());
    if (backdate == null || backdate < 0 || backdate > 365) {
      setState(() {
        _message = 'مدة الرجوع بتاريخ التسميع بين 0 و365 يومًا';
        _isError = true;
      });
      return;
    }
    await _run('center', () {
      return _repository.saveCenterSettings(orgId, {
        for (final e in _textSettings.entries) e.key: e.value.text.trim(),
        for (final e in _flags.entries) e.key: e.value ? 'true' : 'false',
      });
    });
  }

  Widget _field(String label, TextEditingController c, bool enabled, {TextInputType? type, bool ltr = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        enabled: enabled,
        keyboardType: type,
        textDirection: ltr ? TextDirection.ltr : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final org = tenant.active?.organization;
    final isAdmin = tenant.active?.role == OrgRole.admin;
    if (org != null && org.id != _loadedForOrgId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load(org));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات المركز')),
      drawer: const AppDrawer(),
      body: org == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('كل ما يخص مركزك يمكن تخصيصه من هنا.', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  if (_message != null) MessageBanner(message: _message!, isError: _isError),
                  const SectionTitle('الهوية'),
                  _field('اسم المركز', _nameController, isAdmin),
                  _field('رابط الشعار (https)', _logoController, isAdmin, ltr: true),
                  _field('اللون الأساسي (hex)', _primaryColorController, isAdmin, ltr: true),
                  _field('اللون الثانوي (hex)', _secondaryColorController, isAdmin, ltr: true),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      enabled: false,
                      controller: TextEditingController(text: '${org.slug}.bustan-alquran.com'),
                      decoration: const InputDecoration(labelText: 'رابط المركز'),
                    ),
                  ),
                  _field('المنطقة الزمنية', _timezoneController, isAdmin, ltr: true),
                  if (isAdmin)
                    LoadingButton(label: 'حفظ الهوية', loading: _saving == 'org', onPressed: () => _saveOrg(org.id)),
                  const SectionTitle('أيام الدوام'),
                  Text(
                    'تُحسب نسبة الحضور على أيام الدوام فقط، ويمكن تحديد أيام السرد.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  for (final d in _weekdays)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(d.label, style: const TextStyle(fontWeight: FontWeight.w700))),
                            const Text('دوام'),
                            Switch(
                              value: d.isWorking,
                              onChanged: isAdmin
                                  ? (v) => setState(() {
                                        d.isWorking = v;
                                        if (!v) d.isSerdDay = false;
                                      })
                                  : null,
                            ),
                            const Text('سرد'),
                            Switch(
                              value: d.isSerdDay,
                              onChanged: isAdmin && d.isWorking ? (v) => setState(() => d.isSerdDay = v) : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (isAdmin) ...[
                    const SizedBox(height: 8),
                    LoadingButton(label: 'حفظ أيام الدوام', loading: _saving == 'days', onPressed: () => _saveDays(org.id)),
                  ],
                  const SectionTitle('إعدادات التسميع والمزايا'),
                  _field('عدد الأيام المسموح الرجوع إليها بتاريخ التسميع', _textSettings['backdate_days']!, isAdmin,
                      type: TextInputType.number),
                  _field('مفتاح الدولة للجوال (مثل 962)', _textSettings['phone_country_code']!, isAdmin,
                      type: TextInputType.phone, ltr: true),
                  _field('رابط مجموعة واتساب', _textSettings['whatsapp_group_link']!, isAdmin, ltr: true),
                  _field('اسم الموقع (للصلاة والتقويم)', _textSettings['center_location_label']!, isAdmin),
                  Row(
                    children: [
                      Expanded(child: _field('خط العرض', _textSettings['prayer_lat']!, isAdmin, ltr: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _field('خط الطول', _textSettings['prayer_lng']!, isAdmin, ltr: true)),
                    ],
                  ),
                  _field('طريقة حساب الصلاة', _textSettings['prayer_calc_method']!, isAdmin, ltr: true),
                  _field('المذهب (shafi / hanafi)', _textSettings['prayer_madhab']!, isAdmin, ltr: true),
                  const SectionTitle('القرّاء في المصحف'),
                  Text('اترك الاختيار فارغًا لإتاحة كل القرّاء.', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final r in kReciters)
                        FilterChip(
                          label: Text(r.name),
                          selected: _reciterSet.contains(r.id),
                          onSelected: isAdmin
                              ? (v) => setState(() {
                                    v ? _reciterSet.add(r.id) : _reciterSet.remove(r.id);
                                    _textSettings['quran_reciters']!.text = _reciterSet.join(',');
                                  })
                              : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: kReciters.any((r) => r.id == _textSettings['quran_default_reciter']!.text) ? _textSettings['quran_default_reciter']!.text : '',
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'القارئ الافتراضي'),
                    items: [const DropdownMenuItem(value: '', child: Text('الأول في القائمة')), for (final r in kReciters) DropdownMenuItem(value: r.id, child: Text(r.name))],
                    onChanged: isAdmin ? (v) => setState(() => _textSettings['quran_default_reciter']!.text = v ?? '') : null,
                  ),
                  for (final f in const [
                    ('flag_market_enabled', 'تفعيل متجر النقاط'),
                    ('flag_leaderboard_enabled', 'تفعيل لوحة الصدارة'),
                    ('flag_teacher_manage_students', 'السماح للمعلم بإدارة طلاب حلقته'),
                  ])
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(f.$2),
                      value: _flags[f.$1] ?? false,
                      onChanged: isAdmin ? (v) => setState(() => _flags[f.$1] = v) : null,
                    ),
                  if (isAdmin) ...[
                    const SizedBox(height: 8),
                    LoadingButton(label: 'حفظ الإعدادات', loading: _saving == 'center', onPressed: () => _saveCenter(org.id)),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text('بس المدير يقدر يعدّل إعدادات المركز.', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
    );
  }
}
