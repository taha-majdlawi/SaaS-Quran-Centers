import 'digest_tile.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/org_avatar.dart';
import '../../core/widgets/ui.dart';
import '../quran/quran_data.dart' show kReciters;
import 'settings_repository.dart';
import '../../core/i18n/i18n.dart';

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
      _message = currentStrings.set.loadSome;
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
      if (mounted) setState(() { _message = tr(context).set.saved; _isError = false; });
    } catch (e) {
      if (mounted) setState(() { _message = friendlyError(e, tr(context).stu.saveError); _isError = true; });
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  bool _uploadingLogo = false;

  /// Picks a logo, uploads it to this center's folder of the public `org-logos` bucket and fills the
  /// link field; "حفظ الإعدادات" then applies it everywhere (drawer, login, certificates, web).
  Future<void> _pickLogo(String orgId) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: Icon(Icons.photo_library_rounded), title: Text(tr(context).set.fromGallery), onTap: () => Navigator.pop(context, ImageSource.gallery)),
          ListTile(leading: Icon(Icons.photo_camera_rounded), title: Text(tr(context).set.takePhoto), onTap: () => Navigator.pop(context, ImageSource.camera)),
        ]),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker().pickImage(source: source, maxWidth: 512, imageQuality: 90);
    if (file == null) return;
    setState(() {
      _uploadingLogo = true;
      _message = null;
    });
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > 1024 * 1024) throw StateError(currentStrings.set.tooBig1);
      final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
      final clean = const {'jpg', 'jpeg', 'png', 'webp'}.contains(ext) ? (ext == 'jpeg' ? 'jpg' : ext) : 'jpg';
      final mime = clean == 'png' ? 'image/png' : (clean == 'webp' ? 'image/webp' : 'image/jpeg');
      final path = '$orgId/${const Uuid().v4()}.$clean';
      final storage = AppSupabase.client.storage.from('org-logos');
      await storage.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime));
      if (!mounted) return;
      setState(() {
        _logoController.text = storage.getPublicUrl(path);
        _message = tr(context).set.logoUploaded;
        _isError = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = e is StorageException && e.message.contains('row-level security') ? tr(context).set.logoAdminOnly : friendlyError(e, tr(context).set.logoFailed);
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _saveOrg(String orgId) async {
    final logo = _logoController.text.trim();
    if (logo.isNotEmpty && !(Uri.tryParse(logo)?.scheme == 'https')) {
      setState(() {
        _message = tr(context).set.logoHttps;
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
        _message = tr(context).set.backdateRange;
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
    // the fees switch shows / hides the fees screen in the menu
    if (mounted) await context.read<TenantController>().refreshSilently();
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
      appBar: AppBar(
        leading: DrawerLeading(),title: Text(tr(context).nav.items['/settings']!)),
      drawer: const AppDrawer(),
      body: org == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(tr(context).set.intro, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  if (_message != null) MessageBanner(message: _message!, isError: _isError),
                  SectionTitle(tr(context).set.identity),
                  _field(tr(context).set.name, _nameController, isAdmin),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    OrgAvatar(name: _nameController.text.isEmpty ? 'ب' : _nameController.text, logoUrl: _logoController.text.trim().isEmpty ? null : _logoController.text.trim(), size: 64),
                    const SizedBox(width: 12),
                    if (isAdmin)
                      Expanded(
                        child: Wrap(spacing: 8, runSpacing: 4, children: [
                          OutlinedButton.icon(onPressed: _uploadingLogo ? null : () => _pickLogo(org.id), icon: Icon(Icons.upload_rounded, size: 18), label: Text(_uploadingLogo ? tr(context).set.uploading : tr(context).set.uploadLogo)),
                          if (_logoController.text.trim().isNotEmpty)
                            TextButton(onPressed: () => setState(_logoController.clear), child: Text(tr(context).set.remove, style: TextStyle(color: Colors.red))),
                        ]),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  _field(tr(context).set.logoLink, _logoController, isAdmin, ltr: true),
                  _field(tr(context).set.primary, _primaryColorController, isAdmin, ltr: true),
                  _field(tr(context).set.secondary, _secondaryColorController, isAdmin, ltr: true),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      enabled: false,
                      controller: TextEditingController(text: '${org.slug}.bustan-alquran.com'),
                      decoration: InputDecoration(labelText: tr(context).set.link),
                    ),
                  ),
                  _field(tr(context).set.timezone, _timezoneController, isAdmin, ltr: true),
                  if (isAdmin)
                    LoadingButton(label: tr(context).set.saveIdentity, loading: _saving == 'org', onPressed: () => _saveOrg(org.id)),
                  SectionTitle(tr(context).set.workdays),
                  Text(
                    tr(context).set.workdaysHint,
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
                            Text(tr(context).set.working),
                            Switch(
                              value: d.isWorking,
                              onChanged: isAdmin
                                  ? (v) => setState(() {
                                        d.isWorking = v;
                                        if (!v) d.isSerdDay = false;
                                      })
                                  : null,
                            ),
                            Text(tr(context).set.serdDay),
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
                    LoadingButton(label: tr(context).set.saveWorkdays, loading: _saving == 'days', onPressed: () => _saveDays(org.id)),
                  ],
                  SectionTitle(tr(context).set.features),
                  _field(tr(context).set.backdate, _textSettings['backdate_days']!, isAdmin,
                      type: TextInputType.number),
                  _field(tr(context).set.countryCode, _textSettings['phone_country_code']!, isAdmin,
                      type: TextInputType.phone, ltr: true),
                  _field(tr(context).set.whatsapp, _textSettings['whatsapp_group_link']!, isAdmin, ltr: true),
                  _field(tr(context).set.locationLabel, _textSettings['center_location_label']!, isAdmin),
                  Row(
                    children: [
                      Expanded(child: _field(tr(context).set.lat, _textSettings['prayer_lat']!, isAdmin, ltr: true)),
                      const SizedBox(width: 10),
                      Expanded(child: _field(tr(context).set.lng, _textSettings['prayer_lng']!, isAdmin, ltr: true)),
                    ],
                  ),
                  _field(tr(context).set.method, _textSettings['prayer_calc_method']!, isAdmin, ltr: true),
                  _field(tr(context).set.madhab, _textSettings['prayer_madhab']!, isAdmin, ltr: true),
                  SectionTitle(tr(context).set.reciters),
                  Text(tr(context).set.recitersHint, style: Theme.of(context).textTheme.bodySmall),
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
                    decoration: InputDecoration(labelText: tr(context).set.defaultReciter),
                    items: [DropdownMenuItem(value: '', child: Text(tr(context).set.firstInList)), for (final r in kReciters) DropdownMenuItem(value: r.id, child: Text(r.name))],
                    onChanged: isAdmin ? (v) => setState(() => _textSettings['quran_default_reciter']!.text = v ?? '') : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: kLocales.contains(_textSettings['default_language']!.text) ? _textSettings['default_language']!.text : 'ar',
                    isExpanded: true,
                    decoration: InputDecoration(labelText: tr(context).set.language, helperText: tr(context).set.languageHint, helperMaxLines: 3),
                    items: [for (final l in kLocales) DropdownMenuItem(value: l, child: Text(kLocaleNames[l]!))],
                    onChanged: isAdmin ? (v) => setState(() => _textSettings['default_language']!.text = v ?? 'ar') : null,
                  ),
                  for (final f in [
                    ('flag_market_enabled', tr(context).set.market),
                    ('flag_leaderboard_enabled', tr(context).set.leaderboard),
                    ('flag_teacher_manage_students', tr(context).set.teacherStudents),
                    ('flag_fees_enabled', tr(context).set.fees),
                  ])
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(f.$2),
                      value: _flags[f.$1] ?? false,
                      onChanged: isAdmin ? (v) => setState(() => _flags[f.$1] = v) : null,
                    ),
                  if (isAdmin) ...[
                    const SizedBox(height: 8),
                    DigestTile(orgId: org.id),
                    AttendanceReminderTile(orgId: org.id),
                    LoadingButton(label: tr(context).set.saveSettings, loading: _saving == 'center', onPressed: () => _saveCenter(org.id)),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(tr(context).set.adminOnly, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
    );
  }
}
