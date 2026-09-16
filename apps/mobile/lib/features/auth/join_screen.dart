import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'auth_repository.dart';

const _roleLabels = {'admin': 'مدير', 'teacher': 'معلم', 'guardian': 'ولي أمر', 'student': 'طالب'};

/// Accepting an admin's invitation by token - mirrors apps/web's
/// [org]/join, adapted for mobile having no deep-link/subdomain routing:
/// the admin shares the raw token as a "join code" (see members_list_screen
/// .dart's share button) instead of a clickable link, and the invitee
/// pastes it here.
class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _repository = AuthRepository(AppSupabase.client);
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _checking = false;
  bool _submitting = false;
  String? _error;
  String? _checkedToken;
  InvitationPreview? _invitation;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;
    setState(() {
      _checking = true;
      _error = null;
      _invitation = null;
    });
    try {
      final invitation = await _repository.getInvitation(token);
      if (!mounted) return;
      setState(() {
        _checkedToken = token;
        _invitation = invitation;
        if (invitation == null) _error = 'هذي الدعوة منتهية أو تم استخدامها من قبل - اطلب دعوة جديدة';
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'حدث خطأ - حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _accept({required bool alreadySignedIn}) async {
    if (!alreadySignedIn && _passwordController.text.length < 6) {
      setState(() => _error = 'ستة أحرف على الأقل');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthController>();
      if (!alreadySignedIn) {
        final response = await auth.signUp(email: _invitation!.email, password: _passwordController.text);
        if (response.session == null) {
          if (mounted) setState(() => _error = 'تحقق من بريدك لتأكيد الحساب أولًا، ثم افتح رابط الدعوة من جديد');
          return;
        }
      }
      await _repository.acceptInvitation(_checkedToken!);
      // acceptInvitation doesn't change auth state, so - unlike sign in/up -
      // nothing else would trigger a membership reload on its own. And
      // unlike every other redirect case, /join stays reachable even with
      // an active org set (so a member can accept a second org's invite),
      // so nothing would auto-navigate away afterward either - do both
      // explicitly rather than lean on the redirect callback.
      if (!mounted) return;
      await context.read<TenantController>().loadMemberships();
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) setState(() => _error = 'حدث خطأ أثناء الانضمام - حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignedIn = context.watch<AuthController>().isAuthenticated;
    final invitation = _invitation;

    return Scaffold(
      appBar: AppBar(title: const Text('عندك دعوة؟')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(_error!, style: TextStyle(color: Colors.red.shade700), textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 16),
                ],
                if (invitation == null) ...[
                  const Text(
                    'أدخل كود الدعوة اللي أرسلّك إياه مدير المركز',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(labelText: 'كود الدعوة', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _checking ? null : _checkToken,
                    child: _checking
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('متابعة'),
                  ),
                ] else ...[
                  Text(
                    'دعوة من ${invitation.organizationName}',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'كـ ${_roleLabels[invitation.role] ?? invitation.role}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (isSignedIn) ...[
                    Text(
                      'مسجّل دخول بـ ${context.read<AuthController>().currentUser?.email ?? ""}. اضغط تأكيد للانضمام.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submitting ? null : () => _accept(alreadySignedIn: true),
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('تأكيد الانضمام'),
                    ),
                  ] else ...[
                    TextField(
                      enabled: false,
                      controller: TextEditingController(text: invitation.email),
                      decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'كلمة السر', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submitting ? null : () => _accept(alreadySignedIn: false),
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('إنشاء الحساب والانضمام'),
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                if (!isSignedIn)
                  TextButton(onPressed: () => context.go('/login'), child: const Text('عندك حساب؟ سجّل دخولك')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
