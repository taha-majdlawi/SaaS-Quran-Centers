import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The platform's Google "web" client (Google Cloud -> Google Auth Platform -> Clients -> "Bustan web"),
/// public by design: Google's ID token is issued for it, so Supabase's Google provider accepts it.
const kGoogleWebClientId = '1066589394283-l47fir4t102m9uim3786dgt6p9cp0n4n.apps.googleusercontent.com';
const _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://bustan-alquran.com');

/// Android only for now: it needs an "Android" client in Google Cloud (package + SHA-1, docs/GOOGLE_SIGNIN.md);
/// iOS needs its own client id and URL scheme first.
bool get googleSignInAvailable => Platform.isAndroid;

sealed class GoogleOutcome {}

class GoogleSignedIn extends GoogleOutcome {}

class GoogleCancelled extends GoogleOutcome {}

/// Not a teacher or admin of any center: signed out again (the web removed a stranger's new account).
class GoogleNotStaff extends GoogleOutcome {
  GoogleNotStaff(this.email);
  final String email;
}

class GoogleFailed extends GoogleOutcome {}

/// "Continue with Google" for teachers and admins: Google's own account picker on the phone, its ID
/// token (with a one-time nonce) handed to Supabase, then the web checks the account is staff
/// somewhere (/api/auth/google-check) - the same rule as the website.
class GoogleAuth {
  static bool _initialized = false;
  static String _rawNonce = '';

  static Future<GoogleOutcome> signIn(SupabaseClient client) async {
    try {
      final google = GoogleSignIn.instance;
      if (!_initialized) {
        // initialize() is once per app run: its nonce goes with every sign-in of this run
        final random = Random.secure();
        _rawNonce = base64UrlEncode(List<int>.generate(24, (_) => random.nextInt(256)));
        await google.initialize(serverClientId: kGoogleWebClientId, nonce: sha256.convert(utf8.encode(_rawNonce)).toString());
        _initialized = true;
      }
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return GoogleFailed();
      await client.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken, nonce: _rawNonce);

      final check = await _staffCheck(client.auth.currentSession?.accessToken ?? '');
      if (check.ok) return GoogleSignedIn();
      await client.auth.signOut();
      await google.signOut();
      return GoogleNotStaff(check.email ?? account.email);
    } on GoogleSignInException catch (e) {
      return e.code == GoogleSignInExceptionCode.canceled ? GoogleCancelled() : GoogleFailed();
    } on AuthException {
      return GoogleFailed();
    } on SocketException {
      return GoogleFailed();
    }
  }

  static Future<({bool ok, String? email})> _staffCheck(String accessToken) async {
    final http = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await http.postUrl(Uri.parse('$_baseUrl/api/auth/google-check'));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
      final response = await request.close();
      final body = jsonDecode(await response.transform(utf8.decoder).join()) as Map<String, dynamic>;
      return (ok: body['ok'] == true, email: body['email'] as String?);
    } finally {
      http.close();
    }
  }
}
