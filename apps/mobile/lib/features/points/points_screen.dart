import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/tenant/organization.dart';
import '../../core/widgets/app_drawer.dart';
import 'points_repository.dart';

/// Mirrors apps/web's /points page - only the admin can actually edit;
/// a teacher with the 'points' module granted can view it read-only.
class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  final _repository = PointsRepository(AppSupabase.client);
  final _newMemorizationController = TextEditingController();
  final _recentReviewController = TextEditingController();
  final _distantReviewController = TextEditingController();
  final _currencyNameController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orgId = context.read<TenantController>().active!.organization.id;
    final config = await _repository.fetchConfig(orgId);
    _newMemorizationController.text = config.newMemorization.toString();
    _recentReviewController.text = config.recentReview.toString();
    _distantReviewController.text = config.distantReview.toString();
    _currencyNameController.text = config.currencyName;
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _newMemorizationController.dispose();
    _recentReviewController.dispose();
    _distantReviewController.dispose();
    _currencyNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final orgId = context.read<TenantController>().active!.organization.id;
      await _repository.saveConfig(
        organizationId: orgId,
        newMemorization: int.tryParse(_newMemorizationController.text.trim()) ?? 0,
        recentReview: int.tryParse(_recentReviewController.text.trim()) ?? 0,
        distantReview: int.tryParse(_distantReviewController.text.trim()) ?? 0,
        currencyName: _currencyNameController.text.trim().isEmpty ? 'نقاط' : _currencyNameController.text.trim(),
      );
      if (mounted) setState(() { _message = 'تم حفظ الإعدادات'; _isError = false; });
    } catch (e) {
      if (mounted) setState(() { _message = 'حدث خطأ أثناء الحفظ'; _isError = true; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<TenantController>().active?.role == OrgRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('النقاط')),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'عدد النقاط الممنوحة لكل نوع تسميع، واسم عملة النقاط بالمركز.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  if (_message != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _message!,
                        style: TextStyle(color: _isError ? Colors.red.shade700 : Colors.green.shade700),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _newMemorizationController,
                    enabled: isAdmin,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'نقاط الحفظ الجديد', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _recentReviewController,
                    enabled: isAdmin,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'نقاط المراجعة القريبة', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _distantReviewController,
                    enabled: isAdmin,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'نقاط المراجعة البعيدة', border: OutlineInputBorder()),
                  ),
                  const Divider(height: 32),
                  TextField(
                    controller: _currencyNameController,
                    enabled: isAdmin,
                    decoration: const InputDecoration(labelText: 'اسم عملة النقاط', border: OutlineInputBorder()),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('حفظ الإعدادات'),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text('بس المدير يقدر يعدّل إعدادات النقاط.', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
    );
  }
}
