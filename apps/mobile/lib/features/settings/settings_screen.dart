import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/tenant/organization.dart';
import '../../core/widgets/app_drawer.dart';
import 'settings_repository.dart';

/// Mirrors apps/web's /settings page - admin-editable org name, branding
/// colors (as hex text - no color-picker package in this app yet), and
/// timezone.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _repository = SettingsRepository(AppSupabase.client);
  final _nameController = TextEditingController();
  final _primaryColorController = TextEditingController();
  final _secondaryColorController = TextEditingController();
  final _timezoneController = TextEditingController(text: 'Asia/Amman');

  bool _initialized = false;
  bool _saving = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  void _initializeFrom(Organization org) {
    if (_initialized) return;
    _nameController.text = org.name;
    _primaryColorController.text = org.primaryColor;
    _secondaryColorController.text = org.secondaryColor;
    _initialized = true;
  }

  Future<void> _save(String orgId) async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await _repository.updateOrgSettings(
        organizationId: orgId,
        name: _nameController.text.trim(),
        primaryColor: _primaryColorController.text.trim(),
        secondaryColor: _secondaryColorController.text.trim(),
        timezone: _timezoneController.text.trim(),
      );
      if (mounted) setState(() { _message = 'تم حفظ الإعدادات'; _isError = false; });
    } catch (e) {
      if (mounted) setState(() { _message = 'حدث خطأ أثناء الحفظ'; _isError = true; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final org = tenant.active?.organization;
    final isAdmin = tenant.active?.role == OrgRole.admin;
    if (org != null) _initializeFrom(org);

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
                  Text(
                    'الاسم والألوان اللي تظهر بلوحة مركزك.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  if (_message != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _message!,
                        style: TextStyle(color: _isError ? Colors.red.shade700 : Colors.green.shade700),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _nameController,
                    enabled: isAdmin,
                    decoration: const InputDecoration(labelText: 'اسم المركز'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _primaryColorController,
                    enabled: isAdmin,
                    decoration: const InputDecoration(labelText: 'اللون الأساسي (hex)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _secondaryColorController,
                    enabled: isAdmin,
                    decoration: const InputDecoration(labelText: 'اللون الثانوي (hex)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: '${org.slug}.bustan-alquran.com'),
                    decoration: const InputDecoration(labelText: 'رابط المركز'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _timezoneController,
                    enabled: isAdmin,
                    decoration: const InputDecoration(labelText: 'المنطقة الزمنية'),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _saving ? null : () => _save(org.id),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('حفظ الإعدادات'),
                    ),
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
