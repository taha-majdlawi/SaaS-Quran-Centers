import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import '../engagement/engagement_models.dart';
import '../engagement/engagement_repository.dart';

/// Admin: the points market. Items, orders (deliver / cancel - a cancel refunds
/// the balance and restores stock), student wallets, and the points -> currency
/// rate (which only affects points converted AFTER a change).
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _repository = EngagementRepository(AppSupabase.client);
  Future<MarketOverview>? _future;
  Future<List<WalletRow>>? _wallets;
  String? _orgId;
  int _tab = 0;

  void _load(String orgId) {
    _orgId = orgId;
    _future = _repository.marketOverview(orgId);
    _wallets = null;
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
        setState(() => _load(_orgId!));
      }
    } on PostgrestException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _editConfig(MarketOverview o) async {
    final ppu = TextEditingController(text: '${o.pointsPerUnit}');
    final value = TextEditingController(text: '${o.unitValue}');
    final symbol = TextEditingController(text: o.symbol);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سعر تحويل النقاط'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: ppu, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'كل (نقطة)')),
            const SizedBox(height: 10),
            TextField(controller: value, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '= (قيمة)')),
            const SizedBox(height: 10),
            TextField(controller: symbol, maxLength: 8, decoration: const InputDecoration(labelText: 'رمز العملة')),
            const SizedBox(height: 4),
            Text('يسري التغيير على النقاط التي تُحوَّل بعده فقط؛ ما تحوّل سابقًا يبقى بقيمته.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(minimumSize: const Size(90, 44)), child: const Text('حفظ')),
        ],
      ),
    );
    final v = (int.tryParse(ppu.text.trim()), num.tryParse(value.text.trim()), symbol.text.trim());
    ppu.dispose();
    value.dispose();
    symbol.dispose();
    if (ok != true) return;
    if (v.$1 == null || v.$2 == null || v.$3.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل أرقامًا صحيحة ورمز العملة')));
      return;
    }
    await _run(() => _repository.saveConfig(_orgId!, pointsPerUnit: v.$1!, unitValue: v.$2!, symbol: v.$3), 'تم حفظ السعر');
  }

  Future<void> _confirmCancel(Purchase p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الطلب'),
        content: const Text('يُعاد الرصيد والمخزون. متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('نعم')),
        ],
      ),
    );
    if (ok == true) await _run(() => _repository.setPurchaseStatus(p.id, 'cancelled'), 'أُلغي الطلب');
  }

  @override
  Widget build(BuildContext context) {
    final membership = context.watch<TenantController>().active;
    final orgId = membership?.organization.id;
    if (orgId != null && orgId != _orgId) _load(orgId);
    final isAdmin = membership?.role == OrgRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('سوق النقاط')),
      drawer: const AppDrawer(),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/market/new');
                if (mounted) setState(() => _load(_orgId!));
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('عنصر جديد'),
            )
          : null,
      body: !isAdmin
          ? const EmptyState(icon: Icons.lock_outline_rounded, title: 'إدارة السوق للمدير فقط')
          : _future == null
              ? const SizedBox.shrink()
              : AsyncBody<MarketOverview>(
                  future: _future!,
                  onRetry: () => setState(() => _load(_orgId!)),
                  builder: (context, o) {
                    final pending = o.purchases.where((p) => p.status == 'pending').length;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: SegmentedButton<int>(
                            segments: [
                              const ButtonSegment(value: 0, label: Text('العناصر')),
                              ButtonSegment(value: 1, label: Text(pending > 0 ? 'الطلبات ($pending)' : 'الطلبات')),
                              const ButtonSegment(value: 2, label: Text('الأرصدة')),
                            ],
                            selected: {_tab},
                            onSelectionChanged: (s) => setState(() {
                              _tab = s.first;
                              if (_tab == 2) _wallets ??= _repository.marketWallets(_orgId!);
                            }),
                          ),
                        ),
                        Expanded(child: RefreshIndicator(onRefresh: () async => setState(() => _load(_orgId!)), child: _body(o))),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _body(MarketOverview o) {
    switch (_tab) {
      case 1:
        return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 96), children: [
          if (o.purchases.isEmpty) const Padding(padding: EdgeInsets.only(top: 60), child: EmptyState(icon: Icons.receipt_long_outlined, title: 'لا توجد طلبات')),
          for (final p in o.purchases)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('${p.itemName} — ${p.studentName ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800))),
                    StatusChip(label: kPurchaseLabels[p.status] ?? p.status, color: kPurchaseColors[p.status] ?? Colors.grey),
                  ]),
                  const SizedBox(height: 4),
                  Text('${money(p.spent, o.symbol)}  ·  ${formatDate(p.createdAt)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                  if (p.status != 'cancelled')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(spacing: 8, children: [
                        if (p.status == 'pending')
                          FilledButton(
                            onPressed: () => _run(() => _repository.setPurchaseStatus(p.id, 'fulfilled'), 'تم التسليم'),
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
                            child: const Text('تم التسليم'),
                          ),
                        OutlinedButton(
                          onPressed: () => _confirmCancel(p),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, minimumSize: const Size(0, 38)),
                          child: const Text('إلغاء'),
                        ),
                      ]),
                    ),
                ]),
              ),
            ),
        ]);
      case 2:
        return FutureBuilder<List<WalletRow>>(
          future: _wallets,
          builder: (context, snap) {
            if (snap.hasError) return ErrorState(onRetry: () => setState(() => _wallets = _repository.marketWallets(_orgId!)));
            final rows = snap.data;
            if (rows == null) return const Center(child: CircularProgressIndicator());
            return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 96), children: [
              for (final w in rows)
                Card(
                  child: ListTile(
                    leading: InitialAvatar(w.name),
                    title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${w.wallet.earnedPoints} نقطة  ·  المصروف ${money(w.wallet.spent, o.symbol)}'),
                    trailing: Text(money(w.wallet.balance, o.symbol), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
            ]);
          },
        );
      default:
        return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 96), children: [
          if (!o.enabled) const MessageBanner(message: 'السوق معطّل حاليًا (يُفعَّل من إعدادات المركز)', isError: false),
          Card(
            child: ListTile(
              leading: const Icon(Icons.currency_exchange_rounded),
              title: Text('كل ${o.pointsPerUnit} نقطة = ${money(o.unitValue, o.symbol)}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('سعر تحويل النقاط إلى عملة'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editConfig(o),
            ),
          ),
          const SectionTitle('العناصر'),
          if (o.items.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('لا توجد عناصر بعد'))),
          for (final i in o.items)
            Card(
              child: ListTile(
                onTap: () async {
                  await context.push('/market/${i.id}');
                  if (mounted) setState(() => _load(_orgId!));
                },
                title: Text(i.name, style: TextStyle(fontWeight: FontWeight.w700, color: i.isActive ? null : Colors.grey)),
                subtitle: Text('${i.stock == null ? 'مخزون غير محدود' : 'المخزون: ${i.stock}'}${i.isActive ? '' : '  ·  غير فعّال'}'),
                trailing: Text(money(i.price, o.symbol), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
        ]);
    }
  }
}
