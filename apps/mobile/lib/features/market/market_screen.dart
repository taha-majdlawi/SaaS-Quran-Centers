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
import '../../core/i18n/i18n.dart';
import '../../core/widgets/net_image.dart';

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
        title: Text(tr(context).mkt.rateTitle),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: ppu, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr(context).mkt.perPoints)),
            const SizedBox(height: 10),
            TextField(controller: value, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: tr(context).mkt.equals)),
            const SizedBox(height: 10),
            TextField(controller: symbol, maxLength: 8, decoration: InputDecoration(labelText: tr(context).mkt.currency)),
            const SizedBox(height: 4),
            Text(tr(context).mkt.rateHint, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).common.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(minimumSize: Size(90, 44)), child: Text(tr(context).common.save)),
        ],
      ),
    );
    final v = (int.tryParse(ppu.text.trim()), num.tryParse(value.text.trim()), symbol.text.trim());
    ppu.dispose();
    value.dispose();
    symbol.dispose();
    if (ok != true) return;
    if (v.$1 == null || v.$2 == null || v.$3.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context).mkt.rateInvalid)));
      return;
    }
    await _run(() => _repository.saveConfig(_orgId!, pointsPerUnit: v.$1!, unitValue: v.$2!, symbol: v.$3), currentStrings.mkt.rateSaved);
  }

  Future<void> _confirmCancel(Purchase p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).mkt.cancelOrder),
        content: Text(tr(context).mkt.cancelOrderBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).mkt.no)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(context).mkt.yes)),
        ],
      ),
    );
    if (ok == true) await _run(() => _repository.setPurchaseStatus(p.id, 'cancelled'), currentStrings.mkt.orderCancelled);
  }

  @override
  Widget build(BuildContext context) {
    final membership = context.watch<TenantController>().active;
    final orgId = membership?.organization.id;
    if (orgId != null && orgId != _orgId) _load(orgId);
    final isAdmin = membership?.role == OrgRole.admin;

    return Scaffold(
      appBar: AppBar(
        leading: DrawerLeading(),title: Text(tr(context).nav.items['/market']!)),
      drawer: const AppDrawer(),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/market/new');
                if (mounted) setState(() => _load(_orgId!));
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(tr(context).mkt.newItem),
            )
          : null,
      body: !isAdmin
          ? EmptyState(icon: Icons.lock_outline_rounded, title: tr(context).mkt.adminOnly)
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
                              ButtonSegment(value: 0, label: Text(tr(context).mkt.items)),
                              ButtonSegment(value: 1, label: Text(pending > 0 ? fmt(tr(context).mkt.ordersN, {'pending': pending}) : tr(context).mkt.orders)),
                              ButtonSegment(value: 2, label: Text(tr(context).mkt.balances)),
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
          if (o.purchases.isEmpty) Padding(padding: EdgeInsets.only(top: 60), child: EmptyState(icon: Icons.receipt_long_outlined, title: tr(context).mkt.noOrders)),
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
                            onPressed: () => _run(() => _repository.setPurchaseStatus(p.id, 'fulfilled'), tr(context).mkt.delivered),
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
                            child: Text(tr(context).mkt.delivered),
                          ),
                        OutlinedButton(
                          onPressed: () => _confirmCancel(p),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, minimumSize: const Size(0, 38)),
                          child: Text(tr(context).common.cancel),
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
                    subtitle: Text(fmt(tr(context).mkt.walletLine, {'earnedPoints': w.wallet.earnedPoints, 'v': money(w.wallet.spent, o.symbol)})),
                    trailing: Text(money(w.wallet.balance, o.symbol), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
            ]);
          },
        );
      default:
        return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 96), children: [
          if (!o.enabled) MessageBanner(message: tr(context).mkt.disabled, isError: false),
          Card(
            child: ListTile(
              leading: const Icon(Icons.currency_exchange_rounded),
              title: Text(fmt(tr(context).mkt.rateLine, {'pointsPerUnit': o.pointsPerUnit, 'v': money(o.unitValue, o.symbol)}), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(tr(context).mkt.rateSub),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editConfig(o),
            ),
          ),
          SectionTitle(tr(context).mkt.items),
          if (o.items.isEmpty) Padding(padding: EdgeInsets.all(20), child: Center(child: Text(tr(context).mkt.noItems))),
          for (final i in o.items)
            Card(
              child: ListTile(
                leading: i.imageUrl == null
                    ? null
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: NetImage(i.imageUrl!, width: 48, height: 48),
                      ),
                onTap: () async {
                  await context.push('/market/${i.id}');
                  if (mounted) setState(() => _load(_orgId!));
                },
                title: Text(i.name, style: TextStyle(fontWeight: FontWeight.w700, color: i.isActive ? null : Colors.grey)),
                subtitle: Text('${i.stock == null ? tr(context).mkt.unlimited : fmt(tr(context).mkt.stockN, {'n': i.stock})}${i.isActive ? '' : tr(context).mkt.inactiveSuffix}'),
                trailing: Text(money(i.price, o.symbol), style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
        ]);
    }
  }
}
