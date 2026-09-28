import 'package:flutter/material.dart';
import '../../core/widgets/ui.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/tenant/organization.dart';
import '../../core/widgets/app_drawer.dart';
import 'site_repository.dart';
import '../../core/i18n/i18n.dart';

/// Mirrors apps/web's /site page - the public marketing page content.
class SiteScreen extends StatefulWidget {
  const SiteScreen({super.key});

  @override
  State<SiteScreen> createState() => _SiteScreenState();
}

class _SiteScreenState extends State<SiteScreen> {
  final _repository = SiteRepository(AppSupabase.client);
  final _heroTitleController = TextEditingController();
  final _heroBodyController = TextEditingController();
  final _contactEmailController = TextEditingController();
  bool _publicSiteEnabled = false;

  String? _loadedForOrgId;
  bool _loading = true;
  bool _saving = false;
  String? _message;
  bool _isError = false;

  Future<void> _load(String orgId, String orgName) async {
    final settings = await _repository.fetchSettings(orgId);
    _heroTitleController.text = settings?.heroTitle ?? orgName;
    _heroBodyController.text = settings?.heroBody ?? '';
    _contactEmailController.text = settings?.contactEmail ?? '';
    _publicSiteEnabled = settings?.publicSiteEnabled ?? false;
  }

  void _reload(String orgId, String orgName) {
    _loadedForOrgId = orgId;
    _loading = true;
    _load(orgId, orgName).then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _heroTitleController.dispose();
    _heroBodyController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  Future<void> _save(String orgId) async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await _repository.updateSettings(
        organizationId: orgId,
        publicSiteEnabled: _publicSiteEnabled,
        heroTitle: _heroTitleController.text.trim().isEmpty ? null : _heroTitleController.text.trim(),
        heroBody: _heroBodyController.text.trim().isEmpty ? null : _heroBodyController.text.trim(),
        contactEmail: _contactEmailController.text.trim().isEmpty ? null : _contactEmailController.text.trim(),
      );
      if (mounted) setState(() { _message = tr(context).set.saved; _isError = false; });
    } catch (e) {
      if (mounted) setState(() { _message = tr(context).stu.saveError; _isError = true; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final org = tenant.active?.organization;
    final isAdmin = tenant.active?.role == OrgRole.admin;
    if (org != null && org.id != _loadedForOrgId) {
      _reload(org.id, org.name);
    }

    return Scaffold(
      appBar: AppBar(
        leading: DrawerLeading(),title: Text(tr(context).nav.items['/site']!)),
      drawer: const AppDrawer(),
      body: _loading || org == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr(context).org.siteIntro,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  if (_message != null) MessageBanner(message: _message!, isError: _isError),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr(context).org.siteEnable),
                    value: _publicSiteEnabled,
                    onChanged: isAdmin ? (v) => setState(() => _publicSiteEnabled = v) : null,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _heroTitleController,
                    enabled: isAdmin,
                    decoration: InputDecoration(labelText: tr(context).org.heroTitle),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _heroBodyController,
                    enabled: isAdmin,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: tr(context).org.heroBody),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contactEmailController,
                    enabled: isAdmin,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: tr(context).org.contactEmail),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _saving ? null : () => _save(org.id),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(tr(context).set.saveSettings),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(tr(context).org.siteAdminOnly, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
    );
  }
}
