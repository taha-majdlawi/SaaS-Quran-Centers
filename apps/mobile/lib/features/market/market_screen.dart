import 'package:flutter/material.dart';
import '../../core/widgets/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import 'market_repository.dart';

/// Mirrors apps/web's /market page: item catalog + edit links, a purchase
/// form, and a manual balance-adjustment form.
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _repository = MarketRepository(AppSupabase.client);
  String? _loadedForOrgId;
  late Future<void> _dataFuture;

  List<MarketItemSummary> _items = [];
  List<MarketStudentOption> _students = [];

  String? _purchaseStudentId;
  String? _purchaseItemId;
  bool _purchasing = false;

  String? _adjustStudentId;
  final _amountController = TextEditingController(text: '10');
  bool _adjusting = false;

  String? _message;
  bool _isError = false;

  Future<void> _load(String orgId) async {
    final results = await Future.wait([
      _repository.fetchItems(orgId),
      _repository.fetchActiveStudentsWithBalance(orgId),
    ]);
    _items = results[0] as List<MarketItemSummary>;
    _students = results[1] as List<MarketStudentOption>;
  }

  void _reload(String orgId) {
    _loadedForOrgId = orgId;
    _dataFuture = _load(orgId);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _purchase() async {
    if (_purchaseStudentId == null || _purchaseItemId == null) return;
    setState(() {
      _purchasing = true;
      _message = null;
    });
    try {
      await _repository.recordPurchase(
        organizationId: _loadedForOrgId!,
        studentId: _purchaseStudentId!,
        itemId: _purchaseItemId!,
      );
      if (mounted) {
        setState(() { _message = 'تم تسجيل الشراء'; _isError = false; });
        _reload(_loadedForOrgId!);
      }
    } catch (e) {
      final isInsufficient = e is InsufficientBalanceException;
      if (mounted) {
        setState(() {
          _message = isInsufficient ? 'رصيد الطالب غير كافٍ لهذا العنصر' : 'حدث خطأ أثناء تسجيل الشراء';
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _adjust() async {
    if (_adjustStudentId == null) return;
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null) return;
    setState(() {
      _adjusting = true;
      _message = null;
    });
    try {
      await _repository.adjustPoints(organizationId: _loadedForOrgId!, studentId: _adjustStudentId!, amount: amount);
      if (mounted) {
        setState(() { _message = 'تم تعديل الرصيد'; _isError = false; });
        _reload(_loadedForOrgId!);
      }
    } catch (e) {
      if (mounted) setState(() { _message = 'حدث خطأ أثناء التعديل'; _isError = true; });
    } finally {
      if (mounted) setState(() => _adjusting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgId = context.watch<TenantController>().active?.organization.id;
    if (orgId != null && orgId != _loadedForOrgId) {
      _reload(orgId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('سوق النقاط')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/market/new');
          if (orgId != null && mounted) setState(() => _reload(orgId));
        },
        child: const Icon(Icons.add),
      ),
      body: orgId == null
          ? const SizedBox.shrink()
          : FutureBuilder<void>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final activeItems = _items.where((i) => i.isActive).toList();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_message != null) MessageBanner(message: _message!, isError: _isError),
                    if (_items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('لا يوجد عناصر بعد')),
                      )
                    else
                      ..._items.map((i) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(i.name),
                              subtitle: Text('${i.cost} نقطة · ${i.stock?.toString() ?? "غير محدود"} · ${i.isActive ? "مفعّل" : "متوقف"}'),
                              trailing: TextButton(
                                onPressed: () async {
                                  await context.push('/market/${i.id}');
                                  if (mounted) setState(() => _reload(orgId));
                                },
                                child: const Text('تعديل'),
                              ),
                            ),
                          )),
                    if (activeItems.isNotEmpty && _students.isNotEmpty) ...[
                      const Divider(height: 32),
                      Text('تسجيل عملية شراء', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _purchaseStudentId,
                        decoration: const InputDecoration(labelText: 'الطالب'),
                        items: _students
                            .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.fullName} (${s.balance} نقطة)')))
                            .toList(),
                        onChanged: (v) => setState(() => _purchaseStudentId = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _purchaseItemId,
                        decoration: const InputDecoration(labelText: 'العنصر'),
                        items: activeItems
                            .map((i) => DropdownMenuItem(value: i.id, child: Text('${i.name} (${i.cost} نقطة)')))
                            .toList(),
                        onChanged: (v) => setState(() => _purchaseItemId = v),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _purchasing ? null : _purchase,
                        child: _purchasing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('تسجيل الشراء'),
                      ),
                    ],
                    if (_students.isNotEmpty) ...[
                      const Divider(height: 32),
                      Text('تعديل رصيد يدويًا', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _adjustStudentId,
                        decoration: const InputDecoration(labelText: 'الطالب'),
                        items: _students
                            .map((s) => DropdownMenuItem(value: s.id, child: Text('${s.fullName} (${s.balance} نقطة)')))
                            .toList(),
                        onChanged: (v) => setState(() => _adjustStudentId = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(signed: true),
                        decoration: const InputDecoration(labelText: 'الكمية (بالسالب للخصم)'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _adjusting ? null : _adjust,
                        child: _adjusting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('تعديل الرصيد'),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}
