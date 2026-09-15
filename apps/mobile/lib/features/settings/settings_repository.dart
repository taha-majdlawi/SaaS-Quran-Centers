import 'package:supabase_flutter/supabase_flutter.dart';

/// Mirrors apps/web's settings/actions.ts - org name/branding/timezone.
class SettingsRepository {
  SettingsRepository(this._client);

  final SupabaseClient _client;

  Future<void> updateOrgSettings({
    required String organizationId,
    required String name,
    required String primaryColor,
    required String secondaryColor,
    required String timezone,
  }) {
    return _client.from('organizations').update({
      'name': name,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'timezone': timezone,
    }).eq('id', organizationId);
  }
}
