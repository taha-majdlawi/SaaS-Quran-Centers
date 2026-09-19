import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import 'market_repository.dart';

class MarketItemFormScreen extends StatefulWidget {
  const MarketItemFormScreen({super.key, this.itemId});

  final String? itemId;

  bool get isEditing => itemId != null;

  @override
  State<MarketItemFormScreen> createState() => _MarketItemFormScreenState();
}

class _MarketItemFormScreenState extends State<MarketItemFormScreen> {
  final _repository = MarketRepository(AppSupabase.client);
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();
  bool _isActive = true;

  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.isEditing) {
      final item = await _repository.fetchItem(widget.itemId!);
      if (item != null) {
        _nameController.text = item.name;
        _costController.text = item.cost.toString();
        _stockController.text = item.stock?.toString() ?? '';
        _isActive = item.isActive;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final cost = int.tryParse(_costController.text.trim()) ?? 0;
    final stock = _stockController.text.trim().isEmpty ? null : int.tryParse(_stockController.text.trim());

    try {
      if (widget.isEditing) {
        await _repository.updateItem(
          id: widget.itemId!,
          name: _nameController.text.trim(),
          cost: cost,
          stock: stock,
          isActive: _isActive,
        );
      } else {
        final orgId = context.read<TenantController>().active!.organization.id;
        await _repository.createItem(organizationId: orgId, name: _nameController.text.trim(), cost: cost, stock: stock);
      }
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = 'حدث خطأ أثناء الحفظ - حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العنصر'),
        content: const Text('متأكد إنك بدك تحذف هذا العنصر؟ لا يمكن التراجع.'),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('إلغاء')),
          TextButton(onPressed: () => context.pop(true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.deleteItem(widget.itemId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'تعديل العنصر' : 'إضافة عنصر'),
        actions: [
          if (widget.isEditing) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'اسم العنصر'),
                      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'التكلفة (نقاط)'),
                      validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المخزون (اتركه فاضي لغير محدود)',
                      ),
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('مفعّل'),
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(widget.isEditing ? 'حفظ التعديلات' : 'إضافة العنصر'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
