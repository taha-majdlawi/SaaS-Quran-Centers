import 'package:supabase_flutter/supabase_flutter.dart';

import 'secure_local_storage.dart';

/// Single Supabase project shared by every tenant (organization).
/// Isolation between organizations is enforced entirely by Postgres RLS,
/// not by pointing at a different project per center as `eqraa_app` did -
/// see /docs/ARCHITECTURE.md section 1.
class AppSupabase {
  AppSupabase._();

  /// The project address and public key (a second, session-less client checks a password).
  static String url = '';
  static String publishableKey = '';

  static Future<void> initialize({
    required String url,
    required String publishableKey,
  }) {
    AppSupabase.url = url;
    AppSupabase.publishableKey = publishableKey;
    // Same key format supabase_flutter's own default storage would use
    // (sb-<project-ref>-auth-token) - only the storage backend changes, from
    // plain SharedPreferences to the OS keychain/keystore, so a signed-in
    // member's session survives app restarts without sitting in plaintext.
    final persistSessionKey = 'sb-${Uri.parse(url).host.split('.').first}-auth-token';
    return Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureLocalStorage(persistSessionKey: persistSessionKey),
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
