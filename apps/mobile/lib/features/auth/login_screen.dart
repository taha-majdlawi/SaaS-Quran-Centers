import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/org_avatar.dart';
import '../../core/widgets/ui.dart';
import 'login_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _repository = LoginRepository(AppSupabase.client);
  final _formKey = GlobalKey<FormState>();
  final _centerController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Timer? _debounce;
  CenterInfo? _center;
  bool _lookingUp = false;
  bool _centerNotFound = false;
  bool _showPassword = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restoreLastCenter();
  }

  Future<void> _restoreLastCenter() async {
    final slug = await _repository.lastCenterSlug();
    if (slug == null || !mounted) return;
    _centerController.text = slug;
    _lookupCenter(slug);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _centerController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onCenterChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _center = null;
      _centerNotFound = false;
    });
    if (value.trim().length < 2) return;
    _debounce = Timer(const Duration(milliseconds: 500), () => _lookupCenter(value));
  }

  Future<CenterInfo?> _lookupCenter(String slug) async {
    setState(() => _lookingUp = true);
    try {
      final center = await _repository.findCenter(slug);
      if (!mounted) return center;
      // Ignore a stale answer if the user kept typing.
      if (_centerController.text.trim().toLowerCase() != slug.trim().toLowerCase()) return center;
      setState(() {
        _center = center;
        _centerNotFound = center == null;
      });
      return center;
    } catch (_) {
      return null;
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final center = _center ?? await _lookupCenter(_centerController.text);
      if (center == null) {
        setState(() => _error = 'لم نجد مركزًا بهذا الرمز، تأكد من الرمز وحاول مرة أخرى');
        return;
      }
      await _repository.signInToCenter(
        center: center,
        identifier: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on WrongCredentialsException {
      setState(() => _error = 'رقم الدخول / البريد أو كلمة السر غير صحيحة');
    } on NotCenterMemberException {
      setState(() => _error = 'هذا الحساب غير مسجّل في ${_center?.name ?? 'هذا المركز'}');
    } catch (_) {
      setState(() => _error = 'تعذّر الاتصال بالخادم، تأكد من الإنترنت وحاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final brand = _center != null ? parseBrandColor(_center!.primaryColor) : primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Before a center is identified this is the app's own mark; once the
                    // center is known, its own identity (logo + name) replaces it.
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: brand.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: _center == null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(76 / 3.2),
                                child: Image.asset('assets/brand/icon-source.png', width: 76, height: 76),
                              )
                            : OrgAvatar(
                                name: _center!.name,
                                logoUrl: _center!.logoUrl,
                                brandColor: _center!.primaryColor,
                                size: 76,
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(_center?.name ?? 'بستان القرآن',
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('سجّل دخولك إلى مركزك',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                    const SizedBox(height: 28),
                    if (_error != null) MessageBanner(message: _error!),
                    Text('١. المركز', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _centerController,
                      onChanged: _onCenterChanged,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: 'رمز المركز',
                        hintText: 'eqraa',
                        prefixIcon: const Icon(Icons.location_city_outlined),
                        suffixIcon: _lookingUp
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : _center != null
                                ? Icon(Icons.check_circle, color: brand)
                                : null,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل رمز المركز' : null,
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _center != null
                          ? Container(
                              key: const ValueKey('found'),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: brand.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.verified_outlined, color: brand),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(_center!.name,
                                        style: TextStyle(fontWeight: FontWeight.w700, color: brand)),
                                  ),
                                ],
                              ),
                            )
                          : _centerNotFound
                              ? Padding(
                                  key: const ValueKey('missing'),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text('لا يوجد مركز بهذا الرمز',
                                      style: TextStyle(color: Colors.red.shade700)),
                                )
                              : Padding(
                                  key: const ValueKey('hint'),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    'رمز المركز هو أول جزء من رابط مركزك، مثال: eqraa من eqraa.bustan-alquran.com',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                                  ),
                                ),
                    ),
                    const SizedBox(height: 22),
                    Text('٢. حسابك', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'رقم الهوية / الطالب أو البريد',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل رقمك أو بريدك' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'كلمة السر',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'أدخل كلمة السر' : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: brand),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(_center != null ? 'دخول إلى ${_center!.name}' : 'دخول'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'الدخول للمعلمين والإدارة وأولياء الأمور والطلاب، كلٌّ حسب صلاحياته في المركز.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
