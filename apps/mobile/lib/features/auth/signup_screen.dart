import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/supabase/supabase_client.dart';
import 'auth_repository.dart';

final _slugPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
const _reservedSlugs = {'www', 'admin', 'api', 'app', 'platform'};

/// Self-serve org creation - mirrors apps/web's (marketing)/signup: one
/// submit creates the auth user AND the organization + admin membership
/// (create_organization_with_owner, migration 0010). Once signUp() leaves
/// the user authenticated, main.dart's auth-state listener loads memberships
/// on its own and the router's redirect sends them to /dashboard - same as
/// login_screen.dart, no manual navigation needed here either.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _repository = AuthRepository(AppSupabase.client);
  final _formKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _slugController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _orgNameController.dispose();
    _slugController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final slug = _slugController.text.trim().toLowerCase();
    if (!_slugPattern.hasMatch(slug) || _reservedSlugs.contains(slug)) {
      setState(() => _error = 'الرابط غير صالح - حروف إنجليزية صغيرة وأرقام وشرطات فقط، بدون كلمات محجوزة');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthController>();
      final response = await auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (response.session == null) {
        if (mounted) {
          setState(() => _error = 'تحقق من بريدك لتأكيد الحساب أولًا، ثم سجّل دخولك لإكمال إنشاء المركز');
        }
        return;
      }
      await _repository.createOrganizationWithOwner(orgName: _orgNameController.text.trim(), orgSlug: slug);
      // No navigation call needed - auth/tenant state just changed, and the
      // router's redirect (refreshListenable) reacts to that on its own.
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() => _error = e.code == '23505' ? 'هذا الرابط مستخدم من قبل، جرّب رابط آخر' : 'حدث خطأ - حاول مرة أخرى');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'حدث خطأ - حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجّل مركزك')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'دقيقة واحدة، وتقدر تبدأ فورًا بلوحة إدارة كاملة لمركزك',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(_error!, style: TextStyle(color: Colors.red.shade700), textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _orgNameController,
                    decoration: const InputDecoration(labelText: 'اسم المركز', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _slugController,
                    decoration: const InputDecoration(
                      labelText: 'رابط المركز',
                      hintText: 'alnoor',
                      suffixText: '.bustan-alquran.com',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'كلمة السر', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.length < 6) ? 'ستة أحرف على الأقل' : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('إنشاء المركز'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('عندك مركز مسجّل من قبل؟ سجّل دخولك'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
