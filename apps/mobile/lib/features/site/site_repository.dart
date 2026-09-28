import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/offline/sync_service.dart';

class SiteSettingsData {
  const SiteSettingsData({required this.publicSiteEnabled, this.heroTitle, this.heroBody, this.contactEmail});
  final bool publicSiteEnabled;
  final String? heroTitle;
  final String? heroBody;
  final String? contactEmail;
}

/// Mirrors apps/web's site/actions.ts - the public marketing page content
/// shown to unauthenticated visitors on the org's own subdomain.
class SiteRepository {
  SiteRepository(this._client);

  final SupabaseClient _client;

  Future<SiteSettingsData?> fetchSettings(String organizationId) async {
    final row = (await SyncService.instance.raw('site.fetchSettings:$organizationId', () => _client
        .from('site_settings')
        .select('public_site_enabled, hero_title, hero_body, contact_email')
        .eq('organization_id', organizationId)
        .maybeSingle())) as Map<String, dynamic>?;
    if (row == null) return null;
    return SiteSettingsData(
      publicSiteEnabled: row['public_site_enabled'] as bool,
      heroTitle: row['hero_title'] as String?,
      heroBody: row['hero_body'] as String?,
      contactEmail: row['contact_email'] as String?,
    );
  }

  Future<void> updateSettings({
    required String organizationId,
    required bool publicSiteEnabled,
    String? heroTitle,
    String? heroBody,
    String? contactEmail,
  }) {
    return _client.from('site_settings').upsert({
      'organization_id': organizationId,
      'public_site_enabled': publicSiteEnabled,
      'hero_title': heroTitle,
      'hero_body': heroBody,
      'contact_email': contactEmail,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
