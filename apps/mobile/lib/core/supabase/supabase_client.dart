import 'package:supabase_flutter/supabase_flutter.dart';

/// Single Supabase project shared by every tenant (organization).
/// Isolation between organizations is enforced entirely by Postgres RLS,
/// not by pointing at a different project per center as `eqraa_app` did -
/// see /docs/ARCHITECTURE.md section 1.
class AppSupabase {
  AppSupabase._();

  static Future<void> initialize({
    required String url,
    required String publishableKey,
  }) {
    return Supabase.initialize(url: url, publishableKey: publishableKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
