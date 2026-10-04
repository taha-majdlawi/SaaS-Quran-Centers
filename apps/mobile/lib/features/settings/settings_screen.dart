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
import '../quran/quran_data.dart' show AyahReciter, QuranAudioData;
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
  // the uploaded ayah reciters (the built-in list until it has loaded)
  List<AyahReciter> _reciters = QuranAudioData.instance.current;

  @override
  void initState() {
    super.initState();
    QuranAudioData.instance.reciters().then((list) {
      if (mounted) setState(() => _reciters = list);
    });
  }

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
    _timezoneController.text = org.timezone ?? 'Asia/Amman';
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
      // same default as the server (org_setting(..., 'true')): on unless switched off -
      // except fees, which stay off until the admin turns them on (0081)
      for (final k in _flags.keys) {
        _flags[k] = k == 'flag_fees_enabled' ? settings[k] == 'true' : settings[k] != 'false';
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
    setState(() => _saving = section);
    try {
      await action();
      if (mounted) {
        setState(() => _isError = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context).set.saved)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isError = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e, tr(context).stu.saveError)), backgroundColor: Colors.red.shade700));
      }
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
    setState(() => _uploadingLogo = true);
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
      setState(() => _logoController.text = storage.getPublicUrl(path));
      _toast(tr(context).set.logoUploaded);
    } catch (e) {
      if (mounted) {
        _toast(e is StorageException && e.message.contains('row-level security') ? tr(context).set.logoAdminOnly : friendlyError(e, tr(context).set.logoFailed), error: true);
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  void _toast(String text, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? Colors.red.shade700 : null));

  Future<void> _saveOrg(String orgId) async {
    final logo = _logoController.text.trim();
    if (logo.isNotEmpty && !(Uri.tryParse(logo)?.scheme == 'https')) {
      _toast(tr(context).set.logoHttps, error: true);
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
      _toast(tr(context).set.backdateRange, error: true);
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

  static const _tabs = ['identity', 'workdays', 'features', 'contact', 'quran', 'notif'];
  static const _prayerMethods = ['umm_al_qura', 'muslim_world_league', 'egyptian', 'karachi', 'dubai', 'qatar', 'kuwait', 'moon_sighting_committee', 'singapore', 'turkey', 'tehran', 'north_america'];

  /// One tab: its fields, then its own save button (admins) or the read-only note.
  Widget _tab(List<Widget> children, {String? saveLabel, String? section, VoidCallback? onSave, required bool isAdmin}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (_message != null) MessageBanner(message: _message!, isError: _isError),
        ...children,
        const SizedBox(height: 12),
        if (isAdmin && saveLabel != null)
          LoadingButton(label: saveLabel, loading: _saving == section, onPressed: onSave)
        else if (!isAdmin)
          Text(tr(context).set.adminOnly, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  /// A dropdown over fixed values whose current text may be anything (kept as-is if unknown).
  Widget _choice(String label, String key, List<(String, String)> options, bool enabled) {
    final current = _textSettings[key]!.text;
    final items = [
      if (current.isNotEmpty && !options.any((o) => o.$1 == current)) (current, current),
      ...options,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: current.isEmpty ? options.first.$1 : current,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [for (final o in items) DropdownMenuItem(value: o.$1, child: Text(o.$2))],
        onChanged: enabled ? (v) => setState(() => _textSettings[key]!.text = v ?? '') : null,
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
    final t = tr(context).set;

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          leading: DrawerLeading(),
          title: Text(tr(context).nav.items['/settings']!),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final k in _tabs) Tab(text: t.tabs[k] ?? k)],
          ),
        ),
        drawer: const AppDrawer(),
        body: org == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [
                // identity
                _tab([
                  _field(t.name, _nameController, isAdmin),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    OrgAvatar(name: _nameController.text.isEmpty ? 'ب' : _nameController.text, logoUrl: _logoController.text.trim().isEmpty ? null : _logoController.text.trim(), size: 64),
                    const SizedBox(width: 12),
                    if (isAdmin)
                      Expanded(
                        child: Wrap(spacing: 8, runSpacing: 4, children: [
                          OutlinedButton.icon(onPressed: _uploadingLogo ? null : () => _pickLogo(org.id), icon: const Icon(Icons.upload_rounded, size: 18), label: Text(_uploadingLogo ? t.uploading : t.uploadLogo)),
                          if (_logoController.text.trim().isNotEmpty)
                            TextButton(onPressed: () => setState(_logoController.clear), child: Text(t.remove, style: const TextStyle(color: Colors.red))),
                        ]),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  _field(t.logoLink, _logoController, isAdmin, ltr: true),
                  _field(t.primary, _primaryColorController, isAdmin, ltr: true),
                  _field(t.secondary, _secondaryColorController, isAdmin, ltr: true),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      enabled: false,
                      controller: TextEditingController(text: '${org.slug}.bustan-alquran.com'),
                      decoration: InputDecoration(labelText: t.link),
                    ),
                  ),
                  _field(t.timezone, _timezoneController, isAdmin, ltr: true),
                ], saveLabel: t.saveIdentity, section: 'org', onSave: () => _saveOrg(org.id), isAdmin: isAdmin),

                // working days
                _tab([
                  Text(t.workdaysHint, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  for (final d in _weekdays)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(children: [
                          Expanded(child: Text(tr(context).labels.weekdays[d.dow], style: const TextStyle(fontWeight: FontWeight.w700))),
                          Text(t.working),
                          Switch(
                            value: d.isWorking,
                            onChanged: isAdmin
                                ? (v) => setState(() {
                                      d.isWorking = v;
                                      if (!v) d.isSerdDay = false;
                                    })
                                : null,
                          ),
                          Text(t.serdDay),
                          Switch(value: d.isSerdDay, onChanged: isAdmin && d.isWorking ? (v) => setState(() => d.isSerdDay = v) : null),
                        ]),
                      ),
                    ),
                ], saveLabel: t.saveWorkdays, section: 'days', onSave: () => _saveDays(org.id), isAdmin: isAdmin),

                // features
                _tab([
                  _field(t.backdate, _textSettings['backdate_days']!, isAdmin, type: TextInputType.number),
                  for (final f in [
                    ('flag_market_enabled', t.market),
                    ('flag_leaderboard_enabled', t.leaderboard),
                    ('flag_teacher_manage_students', t.teacherStudents),
                    ('flag_fees_enabled', t.fees),
                  ])
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(f.$2),
                      value: _flags[f.$1] ?? false,
                      onChanged: isAdmin ? (v) => setState(() => _flags[f.$1] = v) : null,
                    ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: kLocales.contains(_textSettings['default_language']!.text) ? _textSettings['default_language']!.text : 'ar',
                    isExpanded: true,
                    decoration: InputDecoration(labelText: t.language, helperText: t.languageHint, helperMaxLines: 3),
                    items: [for (final l in kLocales) DropdownMenuItem(value: l, child: Text(kLocaleNames[l]!))],
                    onChanged: isAdmin ? (v) => setState(() => _textSettings['default_language']!.text = v ?? 'ar') : null,
                  ),
                ], saveLabel: t.saveSettings, section: 'center', onSave: () => _saveCenter(org.id), isAdmin: isAdmin),

                // contact & prayer
                _tab([
                  _field(t.countryCode, _textSettings['phone_country_code']!, isAdmin, type: TextInputType.phone, ltr: true),
                  _field(t.whatsapp, _textSettings['whatsapp_group_link']!, isAdmin, ltr: true),
                  _field(t.locationLabel, _textSettings['center_location_label']!, isAdmin),
                  Row(children: [
                    Expanded(child: _field(t.lat, _textSettings['prayer_lat']!, isAdmin, ltr: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(t.lng, _textSettings['prayer_lng']!, isAdmin, ltr: true)),
                  ]),
                  _choice(t.method, 'prayer_calc_method', [for (final m in _prayerMethods) (m, t.prayerMethods[m] ?? m)], isAdmin),
                  _choice(t.madhab, 'prayer_madhab', [('shafi', t.majority), ('hanafi', t.hanafi)], isAdmin),
                ], saveLabel: t.saveSettings, section: 'center', onSave: () => _saveCenter(org.id), isAdmin: isAdmin),

                // mushaf
                _tab([
                  Text(t.reciters, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(t.recitersHint, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    for (final r in _reciters)
                      FilterChip(
                        label: Text(r.label),
                        selected: _reciterSet.contains(r.id),
                        onSelected: isAdmin
                            ? (v) => setState(() {
                                  v ? _reciterSet.add(r.id) : _reciterSet.remove(r.id);
                                  _textSettings['quran_reciters']!.text = _reciterSet.join(',');
                                })
                            : null,
                      ),
                  ]),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _reciters.any((r) => r.id == _textSettings['quran_default_reciter']!.text) ? _textSettings['quran_default_reciter']!.text : '',
                    isExpanded: true,
                    decoration: InputDecoration(labelText: t.defaultReciter),
                    items: [DropdownMenuItem(value: '', child: Text(t.firstInList)), for (final r in _reciters) DropdownMenuItem(value: r.id, child: Text(r.label))],
                    onChanged: isAdmin ? (v) => setState(() => _textSettings['quran_default_reciter']!.text = v ?? '') : null,
                  ),
                ], saveLabel: t.saveSettings, section: 'center', onSave: () => _saveCenter(org.id), isAdmin: isAdmin),

                // notifications (each tile saves itself)
                _tab([
                  if (isAdmin) ...[
                    DigestTile(orgId: org.id),
                    AttendanceReminderTile(orgId: org.id),
                  ],
                ], isAdmin: isAdmin),
              ]),
      ),
    );
  }
}
