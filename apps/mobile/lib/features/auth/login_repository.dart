import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CenterInfo {
  const CenterInfo({required this.id, required this.name, required this.slug, this.primaryColor});

  final String id;
  final String name;
  final String slug;
  final String? primaryColor;
}

class WrongCredentialsException implements Exception {
  const WrongCredentialsException();
}

class NotCenterMemberException implements Exception {
  const NotCenterMemberException();
}

/// Same rule as apps/web's signInToTenant: the account must belong to the
/// center whose code was typed, otherwise the user is signed straight back
/// out - a login is always "to a specific center".
class LoginRepository {
  LoginRepository(this._client);

  final SupabaseClient _client;

  static const lastCenterPrefKey = 'last_center_slug';
  static const _activeOrgPrefKey = 'active_organization_id';

  Future<String?> lastCenterSlug() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastCenterPrefKey);
  }

  /// Organizations are publicly readable (only name/branding), so this works
  /// before anyone is signed in.
  Future<CenterInfo?> findCenter(String slug) async {
    final row = await _client
        .from('organizations')
        .select('id, name, slug, primary_color')
        .eq('slug', slug.trim().toLowerCase())
        .maybeSingle();
    if (row == null) return null;
    return CenterInfo(
      id: row['id'] as String,
      name: row['name'] as String,
      slug: row['slug'] as String,
      primaryColor: row['primary_color'] as String?,
    );
  }

  Future<void> signInToCenter({required CenterInfo center, required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    // Set before signing in so TenantController opens THIS center first.
    await prefs.setString(_activeOrgPrefKey, center.id);

    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException {
      throw const WrongCredentialsException();
    }

    final userId = _client.auth.currentUser?.id;
    final membership = await _client
        .from('organization_members')
        .select('id')
        .eq('organization_id', center.id)
        .eq('user_id', userId ?? '')
        .eq('status', 'active')
        .maybeSingle();

    if (membership == null) {
      await _client.auth.signOut();
      throw const NotCenterMemberException();
    }

    await prefs.setString(lastCenterPrefKey, center.slug);
  }
}
