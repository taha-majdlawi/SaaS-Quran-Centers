import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/widgets/ui.dart';

/// An account that signs in with a number has a made-up address that receives no mail
/// (same rule as the web's lib/accounts/login-id.ts).
bool hasRealEmail(String? email) => email != null && email.isNotEmpty && !email.toLowerCase().endsWith('.id.bustan-alquran.com');

/// The teacher's / admin's own sign-in details: email (the change waits for the link mailed
/// to the new address) and password (after the current one). Students and guardians never
/// reach it: the center makes and changes their accounts.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _newEmail = TextEditingController();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _sendingEmail = false, _savingPassword = false;
  ({bool ok, String text})? _emailNote, _passwordNote;

  @override
  void dispose() {
    for (final c in [_newEmail, _current, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _changeEmail() async {
    final a = tr(context).myAccount;
    final user = AppSupabase.client.auth.currentUser;
    final email = _newEmail.text.trim().toLowerCase();
    String? error;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) || !hasRealEmail(email)) error = a.emailInvalid;
    if (email == user?.email?.toLowerCase()) error = a.emailSame;
    if (error != null) return setState(() => _emailNote = (ok: false, text: error!));
    setState(() => _sendingEmail = true);
    try {
      await AppSupabase.client.auth.updateUser(UserAttributes(email: email), emailRedirectTo: 'https://bustan-alquran.com/confirm');
      if (mounted) setState(() => _emailNote = (ok: true, text: fmt(a.emailSent, {'email': email})));
    } on AuthException catch (e) {
      final text = e.code == 'email_exists' || e.message.contains('already')
          ? a.emailTaken
          : e.code == 'over_email_send_rate_limit' || e.code == 'over_request_rate_limit'
              ? a.tooMany
              : fmt(a.failed, {'error': e.message});
      if (mounted) setState(() => _emailNote = (ok: false, text: text));
    } finally {
      if (mounted) setState(() => _sendingEmail = false);
    }
  }

  Future<void> _changePassword() async {
    final a = tr(context).myAccount;
    final email = AppSupabase.client.auth.currentUser?.email;
    if (_password.text.length < 8) return setState(() => _passwordNote = (ok: false, text: a.short));
    if (_password.text != _confirm.text) return setState(() => _passwordNote = (ok: false, text: a.mismatch));
    if (email == null) return;
    setState(() => _savingPassword = true);
    // the current password, on a second client that keeps no session: the app's own sign-in stays as it is
    final check = SupabaseClient(AppSupabase.url, AppSupabase.publishableKey, authOptions: const AuthClientOptions(autoRefreshToken: false));
    try {
      try {
        await check.auth.signInWithPassword(email: email, password: _current.text);
        await check.auth.signOut(scope: SignOutScope.local);
      } on AuthException catch (e) {
        if (mounted) setState(() => _passwordNote = (ok: false, text: e.code == 'over_request_rate_limit' ? a.tooMany : a.wrongCurrent));
        return;
      }
      await AppSupabase.client.auth.updateUser(UserAttributes(password: _password.text));
      for (final c in [_current, _password, _confirm]) {
        c.clear();
      }
      if (mounted) setState(() => _passwordNote = (ok: true, text: a.passwordChanged));
    } on AuthException catch (e) {
      final text = switch (e.code) {
        'same_password' => a.same,
        'weak_password' => a.weak,
        'insufficient_aal' => a.needCode,
        _ => fmt(a.failed, {'error': e.message}),
      };
      if (mounted) setState(() => _passwordNote = (ok: false, text: text));
    } finally {
      await check.dispose();
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Widget _note(({bool ok, String text})? n) => n == null
      ? const SizedBox.shrink()
      : Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: n.ok ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
          child: Text(n.text, style: TextStyle(color: n.ok ? Colors.green.shade800 : Colors.red.shade700)),
        );

  @override
  Widget build(BuildContext context) {
    final a = tr(context).myAccount;
    final user = AppSupabase.client.auth.currentUser;
    final email = user?.email ?? '';
    final real = hasRealEmail(email);
    final google = (user?.identities ?? const []).any((i) => i.provider == 'google');
    return Scaffold(
      appBar: AppBar(title: Text(a.title)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        SectionTitle(a.emailSection),
        if (!real)
          Text(a.noEmail)
        else ...[
          Text(fmt(a.currentEmail, {'email': email}), style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          _note(_emailNote),
          TextField(
            controller: _newEmail,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: a.newEmail),
          ),
          const SizedBox(height: 12),
          LoadingButton(label: a.sendLink, loading: _sendingEmail, onPressed: _changeEmail),
        ],
        SectionTitle(a.passwordSection),
        _note(_passwordNote),
        TextField(controller: _current, obscureText: true, decoration: InputDecoration(labelText: a.currentPassword)),
        const SizedBox(height: 10),
        TextField(controller: _password, obscureText: true, decoration: InputDecoration(labelText: a.newPassword)),
        const SizedBox(height: 10),
        TextField(controller: _confirm, obscureText: true, decoration: InputDecoration(labelText: a.confirmPassword)),
        const SizedBox(height: 12),
        LoadingButton(label: a.savePassword, loading: _savingPassword, onPressed: _changePassword),
        if (real) ...[
          SectionTitle(a.google),
          Text(google ? a.googleLinked : a.googleHint, style: const TextStyle(color: Colors.black54)),
        ],
      ]),
    );
  }
}
