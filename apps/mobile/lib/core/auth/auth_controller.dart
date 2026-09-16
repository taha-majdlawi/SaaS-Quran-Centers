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

  /// Response's `.session` is null when the project has "confirm email" on -
  /// the caller (signup_screen.dart / join_screen.dart) has to check that
  /// before doing anything that needs auth.uid(), same as apps/web does.
  Future<AuthResponse> signUp({required String email, required String password}) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }
}
