import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/accounts_api.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/credentials_dialog.dart';
import '../../core/widgets/ui.dart';

/// Creates a teacher's login directly (no invite link) - the same rules as the
/// web's members/new-teacher page, executed by the server behind /api/accounts.
class TeacherFormScreen extends StatefulWidget {
  const TeacherFormScreen({super.key});

  @override
  State<TeacherFormScreen> createState() => _TeacherFormScreenState();
}

class _TeacherFormScreenState extends State<TeacherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _identifier = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _identifier.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final org = context.read<TenantController>().active!.organization;
      final password = _password.text.trim();
      final created = await AccountsApi().createTeacher(
        orgId: org.id,
        fullName: _name.text.trim(),
        identifier: _identifier.text.trim(),
        password: password,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );
      if (!mounted) return;
      await showCredentialsDialog(
        context,
        title: 'تم إنشاء حساب المعلم',
        centerCode: org.slug,
        loginId: created.loginId,
        password: password,
      );
      if (mounted) context.pop();
    } on AccountsApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('معلم جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'يدخل المعلم برمز المركز + رقمه (أو بريده) + كلمة السر.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (_error != null) MessageBanner(message: _error!),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'الاسم الكامل'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _identifier,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'رقم الدخول أو البريد الإلكتروني'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'الجوال (اختياري)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'كلمة السر (8 أحرف على الأقل)'),
              validator: (v) => (v == null || v.trim().length < 8) ? '8 أحرف على الأقل' : null,
            ),
            const SizedBox(height: 20),
            LoadingButton(label: 'إنشاء الحساب', loading: _saving, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
