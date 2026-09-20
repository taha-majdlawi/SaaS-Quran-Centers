import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';

const _roleLabels = {'admin': 'مدير', 'teacher': 'معلم', 'guardian': 'ولي أمر', 'student': 'طالب'};

/// Opened from an invitation link (`https://CENTER.bustan-alquran.com/join?token=...`):
/// shows who invited you, then either confirms (already signed in), signs in with the
/// invited e-mail, or creates the account - and accepts the invitation in one go.
class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key, required this.token});

  final String? token;

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _password = TextEditingController();
  Future<Map<String, dynamic>?>? _future;
  bool _haveAccount = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _load() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return null;
    final rows = await AppSupabase.client.rpc('get_invitation', params: {'invite_token': token}) as List;
    if (rows.isEmpty) return null;
    final inv = rows.first as Map<String, dynamic>;
    return inv['valid'] == true ? inv : null;
  }

  Future<void> _accept(Map<String, dynamic> inv, {required bool signedIn}) async {
    final client = AppSupabase.client;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!signedIn) {
        final email = inv['email'] as String;
        final password = _password.text;
        if (password.length < 8) throw StateError('كلمة السر 8 أحرف على الأقل');
        if (_haveAccount) {
          await client.auth.signInWithPassword(email: email, password: password);
        } else {
          final res = await client.auth.signUp(email: email, password: password);
          if (res.session == null) {
            throw StateError('تحقق من بريدك لتأكيد الحساب أولًا، ثم افتح رابط الدعوة من جديد لإكمال الانضمام');
          }
        }
      }
      await client.rpc('accept_invitation', params: {'invite_token': widget.token});
      if (!mounted) return;
      await context.read<TenantController>().loadMemberships();
      if (mounted) context.go('/dashboard');
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on StateError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر إكمال الانضمام، تأكد من الإنترنت وحاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = AppSupabase.client.auth.currentUser != null;
    return Scaffold(
      appBar: AppBar(title: const Text('الانضمام إلى مركز')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(onRetry: () => setState(() => _future = _load()));
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final inv = snap.data;
          if (inv == null) {
            return const EmptyState(
              icon: Icons.link_off_rounded,
              title: 'الدعوة غير صالحة',
              subtitle: 'منتهية أو استُخدمت من قبل. اطلب من مدير المركز دعوة جديدة.',
            );
          }
          final role = _roleLabels[inv['role']] ?? '${inv['role']}';
          return ListView(padding: const EdgeInsets.all(20), children: [
            const SizedBox(height: 12),
            Icon(Icons.mail_rounded, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('دعوة من ${inv['organization_name']}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text('للانضمام كـ $role', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            if (_error != null) MessageBanner(message: _error!),
            if (signedIn) ...[
              Text('مسجّل دخول بـ ${AppSupabase.client.auth.currentUser?.email ?? ''}', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              LoadingButton(label: 'تأكيد الانضمام', loading: _busy, onPressed: () => _accept(inv, signedIn: true)),
            ] else ...[
              TextField(
                controller: TextEditingController(text: '${inv['email']}'),
                readOnly: true,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني (من الدعوة)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(labelText: _haveAccount ? 'كلمة سر حسابك' : 'أنشئ كلمة سر (8 أحرف على الأقل)'),
              ),
              const SizedBox(height: 12),
              LoadingButton(
                label: _haveAccount ? 'دخول والانضمام' : 'إنشاء الحساب والانضمام',
                loading: _busy,
                onPressed: () => _accept(inv, signedIn: false),
              ),
              TextButton(
                onPressed: _busy ? null : () => setState(() => _haveAccount = !_haveAccount),
                child: Text(_haveAccount ? 'ليس لدي حساب' : 'لدي حساب بالفعل'),
              ),
            ],
          ]);
        },
      ),
    );
  }
}
