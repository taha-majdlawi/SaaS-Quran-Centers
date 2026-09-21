import '../push/push_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around Supabase's own auth state so widgets can watch it via
/// Provider like everything else, instead of listening to the SDK stream
/// directly in every screen.
class AuthController extends ChangeNotifier {
  AuthController(this._client) {
    _client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<void> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    // stop this phone receiving the account's pushes before the session goes away
    await PushService.instance.unregister(_client);
    await _client.auth.signOut();
  }
}
