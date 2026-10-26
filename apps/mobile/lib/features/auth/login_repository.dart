import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _loginDomain = 'id.bustan-alquran.com';

/// Same rule as apps/web/src/lib/accounts/login-id.ts: a number-style login
/// becomes a virtual email that carries the center code, so the same number
/// can exist in two centers; a real email is used as typed.
String toLoginEmail(String centerSlug, String identifier) {
  final id = identifier.trim().toLowerCase();
  if (id.contains('@')) return id;
  return '$id@${centerSlug.trim().toLowerCase()}.$_loginDomain';
}

class CenterInfo {
  const CenterInfo({required this.id, required this.name, required this.slug, this.primaryColor, this.logoUrl});

  final String id;
  final String name;
  final String slug;
  final String? primaryColor;
  final String? logoUrl;
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
        .select('id, name, slug, primary_color, logo_url')
        .eq('slug', slug.trim().toLowerCase())
        .maybeSingle();
    if (row == null) return null;
    return CenterInfo(
      id: row['id'] as String,
      name: row['name'] as String,
      slug: row['slug'] as String,
      primaryColor: row['primary_color'] as String?,
      logoUrl: row['logo_url'] as String?,
    );
  }

  /// The center's default language, readable before sign-in (get_public_site, 0069).
  Future<String?> publicDefaultLanguage(String slug) async {
    final res = await _client.rpc('get_public_site', params: {'p_slug': slug.trim().toLowerCase()});
    return res is Map ? res['default_language'] as String? : null;
  }

  Future<void> signInToCenter({required CenterInfo center, required String identifier, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    // Set before signing in so TenantController opens THIS center first.
    await prefs.setString(_activeOrgPrefKey, center.id);

    try {
      await _client.auth.signInWithPassword(email: toLoginEmail(center.slug, identifier), password: password);
    } on AuthException {
      // not the number at the center / the email: maybe the national ID (0095) - only the server
      // may look up whose it is, so it signs in there and hands back the session
      if (identifier.contains('@') || !await _signInWithNationalId(center.slug, identifier, password)) {
        throw const WrongCredentialsException();
      }
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

  static const _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://bustan-alquran.com');

  /// apps/web /api/auth/id-login: signs in with the ID and the password, returns the session.
  Future<bool> _signInWithNationalId(String center, String identifier, String password) async {
    final http = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await http.postUrl(Uri.parse('$_baseUrl/api/auth/id-login'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'center': center, 'identifier': identifier, 'password': password}));
      final response = await request.close();
      final body = jsonDecode(await response.transform(utf8.decoder).join());
      final refresh = body is Map ? body['refresh_token'] as String? : null;
      if (response.statusCode != 200 || refresh == null) return false;
      await _client.auth.setSession(refresh);
      return _client.auth.currentUser != null;
    } on SocketException {
      return false;
    } on FormatException {
      return false;
    } on AuthException {
      return false;
    } finally {
      http.close();
    }
  }
}
