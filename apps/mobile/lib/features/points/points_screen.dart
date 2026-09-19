import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/ui.dart';
import 'points_repository.dart';

/// Recitation grades + points. Only the admin edits; a teacher with the
/// 'points' module can look. Editing never rewrites past recitations.
class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  final _repository = PointsRepository(AppSupabase.client);
  List<GradeRow> _grades = [];
  final _controllers = <String, (TextEditingController, TextEditingController)>{};
  final _newKey = TextEditingController();
  final _newLabel = TextEditingController();
  final _newPoints = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _disposeControllers() {
    for (final c in _controllers.values) {
      c.$1.dispose();
      c.$2.dispose();
    }
    _controllers.clear();
  }

  Future<void> _load() async {
    try {
      final orgId = context.read<TenantController>().active!.organization.id;
      _disposeControllers();
      _grades = await _repository.fetchGrades(orgId);
      for (final g in _grades) {
        _controllers[g.key] = (TextEditingController(text: g.label), TextEditingController(text: '${g.points}'));
      }
    } catch (_) {
      _message = 'تعذّر تحميل التقديرات';
      _isError = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _disposeControllers();
    _newKey.dispose();
    _newLabel.dispose();
    _newPoints.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newKey = _newKey.text.trim().toLowerCase();
    final newLabel = _newLabel.text.trim();
    if ((newKey.isNotEmpty || newLabel.isNotEmpty) &&
        (!RegExp(r'^[a-z0-9_]{1,40}$').hasMatch(newKey) || newLabel.isEmpty)) {
      setState(() {
        _message = 'المفتاح حروف إنجليزية صغيرة/أرقام/_ فقط، والاسم مطلوب';
        _isError = true;
      });
      return;
    }

    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final orgId = context.read<TenantController>().active!.organization.id;
      final rows = [
        for (final g in _grades)
          GradeRow(
            key: g.key,
            label: _controllers[g.key]!.$1.text,
            points: int.tryParse(_controllers[g.key]!.$2.text.trim()) ?? 0,
            sortOrder: g.sortOrder,
            isActive: g.isActive,
          ),
        if (newKey.isNotEmpty)
          GradeRow(
            key: newKey,
            label: newLabel,
            points: int.tryParse(_newPoints.text.trim()) ?? 0,
            sortOrder: _grades.length + 1,
            isActive: true,
          ),
      ];
      await _repository.saveGrades(orgId, rows);
      _newKey.clear();
      _newLabel.clear();
      _newPoints.clear();
      await _load();
      if (mounted) setState(() { _message = 'تم حفظ التقديرات'; _isError = false; });
    } catch (_) {
      if (mounted) setState(() { _message = 'حدث خطأ أثناء الحفظ'; _isError = true; });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<TenantController>().active?.role == OrgRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('تقديرات التسميع والنقاط')),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'أسماء التقديرات وعدد النقاط لكل تقدير. تُحفظ النقاط على كل تسميع لحظة تسجيله، فتغييرها يسري على التسميعات القادمة فقط.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (_message != null) MessageBanner(message: _message!, isError: _isError),
                for (final g in _grades)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _controllers[g.key]!.$1,
                                enabled: isAdmin,
                                decoration: const InputDecoration(labelText: 'الاسم'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _controllers[g.key]!.$2,
                                enabled: isAdmin,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'النقاط'),
                              ),
                            ),
                            Switch(
                              value: g.isActive,
                              onChanged: isAdmin ? (v) => setState(() => g.isActive = v) : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (isAdmin) ...[
                  const SectionTitle('إضافة تقدير جديد'),
                  TextField(
                    controller: _newKey,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(labelText: 'المفتاح (مثل outstanding)'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _newLabel,
                          decoration: const InputDecoration(labelText: 'الاسم (مثل متميز)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _newPoints,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'النقاط'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LoadingButton(label: 'حفظ التقديرات', loading: _saving, onPressed: _save),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('بس المدير يقدر يعدّل التقديرات والنقاط.', style: TextStyle(color: Colors.grey.shade600)),
                  ),
              ],
            ),
    );
  }
}
