import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/i18n/i18n.dart';
import '../../core/offline/sync_service.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/widgets/garden.dart';
import '../../core/widgets/ui.dart';

// Student fees (0081) - an optional feature, off unless the admin turns it on.
// The admin sees every student's balance and records payments (offline too:
// a payment carries a client_ref, so a replay never records it twice); the
// family sees its own child's account and receipts. Plans, assigning them and
// the report live on the website dashboard.

const kFeeMethods = ['cash', 'transfer', 'card', 'wallet', 'other'];

num _n(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;

/// "12.5 JD" - no trailing zeros, the center's currency after it.
String feeMoney(dynamic v, String currency) {
  final x = _n(v);
  final s = x == x.roundToDouble() ? x.toInt().toString() : x.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  return currency.isEmpty ? s : '$s $currency';
}

String _day(dynamic iso) {
  final d = DateTime.tryParse('${iso ?? ''}');
  return d == null ? '—' : DateFormat('yyyy/MM/dd').format(d);
}

/// The admin's list: totals, then every active student with their balance.
class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  static Future<Map<String, dynamic>> load(SupabaseClient client, String orgId) async =>
      Map<String, dynamic>.from(await SyncService.instance.raw('fees:$orgId', () => client.rpc('fees_overview', params: {'p_org': orgId})) as Map);

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  late Future<Map<String, dynamic>> _future;
  String _filter = 'all';
  String _query = '';

  String get _orgId => context.read<TenantController>().active!.organization.id;

  @override
  void initState() {
    super.initState();
    _future = FeesScreen.load(Supabase.instance.client, _orgId);
  }

  void _reload() => setState(() => _future = FeesScreen.load(Supabase.instance.client, _orgId));

  @override
  Widget build(BuildContext context) {
    final F = tr(context).fees;
    return Scaffold(
      appBar: AppBar(title: Text(F.title)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(onRetry: _reload);
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final o = snap.data!;
          final cur = '${o['currency'] ?? ''}';
          final all = ((o['students'] as List?) ?? const []).cast<Map<String, dynamic>>();
          final owing = all.where((s) => _n(s['balance']) > 0).toList();
          final outstanding = owing.fold<num>(0, (sum, s) => sum + _n(s['balance']));
          final q = _query.trim().toLowerCase();
          final rows = all.where((s) {
            if (_filter == 'owing' && _n(s['balance']) <= 0) return false;
            if (_filter == 'noPlan' && (s['plan_id'] != null || s['exempt'] == true)) return false;
            if (q.isEmpty) return true;
            return '${s['name']}'.toLowerCase().contains(q) || '${s['code'] ?? ''}'.toLowerCase().contains(q);
          }).toList();
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
              Row(children: [
                Expanded(child: _Stat(F.collectedMonth, feeMoney(o['collected_month'], cur))),
                const SizedBox(width: 8),
                Expanded(child: _Stat(F.outstanding, feeMoney(outstanding, cur), color: outstanding > 0 ? Colors.red.shade700 : null)),
                const SizedBox(width: 8),
                Expanded(child: _Stat(F.owingN, '${owing.length}')),
              ]),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: F.search, isDense: true),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final f in ['all', 'owing', 'noPlan'])
                  ChoiceChip(label: Text(F.filter[f] ?? f), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
              ]),
              const SizedBox(height: 8),
              if (rows.isEmpty) Padding(padding: const EdgeInsets.only(top: 40), child: Center(child: Text(F.none, style: const TextStyle(color: kInkMuted)))),
              for (final s in rows) _row(context, s, cur),
              const SizedBox(height: 12),
              Text(F.manageOnWeb, style: const TextStyle(color: kInkMuted, fontSize: 12)),
            ]),
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, Map<String, dynamic> s, String cur) {
    final F = tr(context).fees;
    final bal = _n(s['balance']);
    final sub = s['exempt'] == true
        ? F.exempt
        : s['plan'] == null
            ? F.noPlan
            : '${s['plan']}${_n(s['discount']) > 0 ? ' · ${fmt(F.discountV, {'n': _n(s['discount'])})}' : ''}';
    return GardenCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () async {
        await context.push('/fees/${s['id']}');
        if (mounted) _reload();
      },
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${s['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
            Text([if (s['circle'] != null) '${s['circle']}', sub].join(' · '), style: const TextStyle(color: kInkMuted, fontSize: 12)),
          ]),
        ),
        Text(
          bal > 0 ? feeMoney(bal, cur) : (bal < 0 ? '${F.credit} ${feeMoney(-bal, cur)}' : '✓'),
          style: TextStyle(fontWeight: FontWeight.w800, color: bal > 0 ? Colors.red.shade700 : TeacherStyle.success),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => GardenCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: kInkMuted, fontSize: 11.5)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: color ?? Theme.of(context).colorScheme.primary)),
          ),
        ]),
      );
}

/// One student's account - the admin (record / void / waive) or the family (read only).
class FeeStudentScreen extends StatefulWidget {
  const FeeStudentScreen({super.key, required this.studentId});

  final String studentId;

  static Future<Map<String, dynamic>> load(SupabaseClient client, String orgId, String studentId) async => Map<String, dynamic>.from(
      await SyncService.instance.raw('fees:$orgId:$studentId', () => client.rpc('student_fees', params: {'p_org': orgId, 'p_student': studentId})) as Map);

  @override
  State<FeeStudentScreen> createState() => _FeeStudentScreenState();
}

class _FeeStudentScreenState extends State<FeeStudentScreen> {
  late Future<Map<String, dynamic>> _future;

  String get _orgId => context.read<TenantController>().active!.organization.id;

  @override
  void initState() {
    super.initState();
    _future = FeeStudentScreen.load(Supabase.instance.client, _orgId, widget.studentId);
  }

  void _reload() => setState(() => _future = FeeStudentScreen.load(Supabase.instance.client, _orgId, widget.studentId));

  List<Map<String, dynamic>> get _pending =>
      SyncService.instance.pendingOf('fee_payment').where((i) => i.payload['p_student'] == widget.studentId).map((i) => i.payload).toList();

  Future<void> _rpc(String fn, Map<String, dynamic> params) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = tr(context).common.loadFailed;
    try {
      await Supabase.instance.client.rpc(fn, params: params);
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e, failed))));
    }
  }

  Future<bool> _confirm(String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr(c).common.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr(c).common.confirm)),
          ],
        ),
      ) ??
      false;

  Future<void> _void(Map<String, dynamic> p) async {
    final F = tr(context).fees;
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(F.voidPayment),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(F.voidConfirm),
          const SizedBox(height: 8),
          TextField(controller: reason, decoration: InputDecoration(labelText: F.voidReason)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr(c).common.cancel)),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600), onPressed: () => Navigator.pop(c, true), child: Text(F.voidPayment)),
        ],
      ),
    );
    if (ok == true) await _rpc('void_fee_payment', {'p_org': _orgId, 'p_payment': p['id'], 'p_reason': reason.text.trim()});
  }

  @override
  Widget build(BuildContext context) {
    final F = tr(context).fees;
    context.watch<SyncService>();
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        final a = snap.data;
        final isAdmin = a?['is_admin'] == true;
        final student = a?['student'] as Map?;
        return Scaffold(
          appBar: AppBar(title: Text(student == null ? F.title : '${student['name']}')),
          floatingActionButton: isAdmin
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final saved = await showFeePaymentSheet(context, orgId: _orgId, account: a!);
                    if (saved == true && mounted) _reload();
                  },
                  icon: const Icon(Icons.add_card_rounded),
                  label: Text(F.recordTitle),
                )
              : null,
          body: snap.hasError
              ? ErrorState(onRetry: _reload)
              : a == null
                  ? const Center(child: CircularProgressIndicator())
                  : a['enabled'] != true
                      ? Center(child: Text(F.noCharges, style: const TextStyle(color: kInkMuted)))
                      : RefreshIndicator(
                          onRefresh: () async {
                            _reload();
                            await _future;
                          },
                          child: _body(context, a, isAdmin),
                        ),
        );
      },
    );
  }

  Widget _body(BuildContext context, Map<String, dynamic> a, bool isAdmin) {
    final F = tr(context).fees;
    final cur = '${a['currency'] ?? ''}';
    final b = Map<String, dynamic>.from(a['balance'] as Map);
    final bal = _n(b['balance']);
    final plan = a['plan'] as Map?;
    final today = '${a['today'] ?? ''}';
    final charges = ((a['charges'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final payments = ((a['payments'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final pending = _pending;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 96), children: [
      GardenCard(
        color: bal > 0 ? Colors.red.shade50 : Colors.green.shade50,
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(bal > 0 ? F.owes : (bal < 0 ? F.credit : F.settled), style: const TextStyle(color: kInkMuted)),
              if (bal != 0)
                Text(feeMoney(bal.abs(), cur),
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: bal > 0 ? Colors.red.shade700 : Colors.green.shade700)),
            ]),
          ),
          Icon(bal > 0 ? Icons.error_outline_rounded : Icons.check_circle_rounded, size: 36, color: bal > 0 ? Colors.red.shade400 : Colors.green.shade500),
        ]),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _Stat(F.dueSoFar, feeMoney(b['due'], cur))),
        const SizedBox(width: 8),
        Expanded(child: _Stat(F.paidTotal, feeMoney(b['paid'], cur))),
        const SizedBox(width: 8),
        Expanded(child: _Stat(F.upcoming, feeMoney(b['upcoming'], cur))),
      ]),
      if (plan != null) ...[
        const SizedBox(height: 10),
        Text(
          plan['exempt'] == true
              ? F.exempt
              : plan['name'] == null
                  ? F.noPlan
                  : [
                      fmt(F.plan, {'name': plan['name']}),
                      feeMoney(plan['amount'], cur),
                      F.periods['${plan['period']}'] ?? '',
                      if (_n(plan['discount']) > 0) fmt(F.discountV, {'n': _n(plan['discount'])}),
                    ].join(' · '),
          style: const TextStyle(color: kInkMuted),
        ),
      ],
      const SizedBox(height: 16),
      SectionTitle(F.payments),
      for (final p in pending)
        GardenCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Expanded(child: Text(feeMoney(p['p_amount'], cur), style: const TextStyle(fontWeight: FontWeight.w800))),
            GardenChip(F.pendingUpload, color: TeacherStyle.warning, icon: Icons.cloud_upload_rounded),
          ]),
        ),
      if (payments.isEmpty && pending.isEmpty) Text(F.noPayments, style: const TextStyle(color: kInkMuted)),
      for (final p in payments)
        GardenCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          onTap: () => showFeeReceipt(context, orgId: _orgId, paymentId: '${p['id']}'),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(feeMoney(p['amount'], cur),
                    style: TextStyle(fontWeight: FontWeight.w800, decoration: p['voided'] == true ? TextDecoration.lineThrough : null)),
                Text('${_day(p['paid_on'])} · ${F.methods['${p['method']}'] ?? p['method']} · ${fmt(F.receiptNo, {'n': p['receipt_no']})}',
                    style: const TextStyle(color: kInkMuted, fontSize: 12)),
              ]),
            ),
            if (p['voided'] == true) GardenChip(F.voided, color: Colors.red.shade600),
            if (isAdmin && p['voided'] != true)
              IconButton(tooltip: F.voidPayment, icon: Icon(Icons.block_rounded, color: Colors.red.shade400), onPressed: () => _void(p)),
          ]),
        ),
      const SizedBox(height: 16),
      SectionTitle(F.charges),
      if (charges.isEmpty) Text(F.noCharges, style: const TextStyle(color: kInkMuted)),
      for (final c in charges)
        GardenCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${c['title']}', style: TextStyle(fontWeight: FontWeight.w700, color: c['status'] == 'open' ? kInk : kInkMuted)),
                Text(
                  '${feeMoney(c['amount'], cur)} · ${_day(c['due_date'])}'
                  '${c['status'] != 'open' ? ' · ${F.status['${c['status']}']}' : ('${c['due_date']}'.compareTo(today) > 0 ? ' · ${F.notYetDue}' : '')}',
                  style: const TextStyle(color: kInkMuted, fontSize: 12),
                ),
              ]),
            ),
            if (isAdmin)
              PopupMenuButton<String>(
                onSelected: (st) async {
                  if (st == 'cancelled' && !await _confirm(F.cancelChargeConfirm)) return;
                  await _rpc('set_fee_charge_status', {'p_org': _orgId, 'p_charge': c['id'], 'p_status': st});
                },
                itemBuilder: (_) => [
                  if (c['status'] == 'open') ...[
                    PopupMenuItem(value: 'waived', child: Text(F.waive)),
                    PopupMenuItem(value: 'cancelled', child: Text(F.cancelCharge)),
                  ] else
                    PopupMenuItem(value: 'open', child: Text(F.reopen)),
                ],
              ),
          ]),
        ),
    ]);
  }
}

/// The admin records a payment. Queued when offline; the server refuses a
/// second copy of the same payment (client_ref), so a replay is harmless.
Future<bool?> showFeePaymentSheet(BuildContext context, {required String orgId, required Map<String, dynamic> account}) {
  final F = tr(context).fees;
  final cur = '${account['currency'] ?? ''}';
  final student = Map<String, dynamic>.from(account['student'] as Map);
  final owes = _n((account['balance'] as Map)['balance']);
  final amount = TextEditingController(text: owes > 0 ? feeMoney(owes, '') : '');
  final note = TextEditingController();
  var method = 'cash';
  var paidOn = DateTime.now();
  var saving = false;
  String? error;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(sheet).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${F.recordTitle} — ${student['name']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: F.amount, suffixText: cur, errorText: error),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            for (final m in kFeeMethods) ChoiceChip(label: Text(F.methods[m] ?? m), selected: method == m, onSelected: (_) => setState(() => method = m)),
          ]),
          const SizedBox(height: 6),
          TextButton.icon(
            style: TextButton.styleFrom(alignment: AlignmentDirectional.centerStart),
            icon: const Icon(Icons.event_rounded),
            label: Text(fmt(F.paidOn, {'date': DateFormat('yyyy/MM/dd').format(paidOn)})),
            onPressed: () async {
              final d = await showDatePicker(context: sheet, initialDate: paidOn, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now());
              if (d != null) setState(() => paidOn = d);
            },
          ),
          TextField(controller: note, decoration: InputDecoration(labelText: F.note)),
          const SizedBox(height: 16),
          LoadingButton(
            label: F.record,
            loading: saving,
            onPressed: () async {
              final value = num.tryParse(amount.text.trim().replaceAll(',', '.'));
              if (value == null || value <= 0) {
                setState(() => error = F.amountInvalid);
                return;
              }
              setState(() {
                saving = true;
                error = null;
              });
              final messenger = ScaffoldMessenger.of(context);
              try {
                final out = await SyncService.instance.submit(
                  'fee_payment',
                  {
                    'p_org': orgId,
                    'p_student': student['id'],
                    'p_amount': value,
                    'p_method': method,
                    'p_paid_on': DateFormat('yyyy-MM-dd').format(paidOn),
                    'p_note': note.text.trim().isEmpty ? null : note.text.trim(),
                    'p_client_ref': const Uuid().v4(),
                  },
                  label: fmt(F.outbox, {'name': student['name'], 'amount': feeMoney(value, cur)}),
                );
                messenger.showSnackBar(SnackBar(content: Text(out.queued ? kQueuedMessage : F.recorded)));
                if (sheet.mounted) Navigator.pop(sheet, true);
              } catch (e) {
                setState(() {
                  saving = false;
                  error = friendlyError(e, F.amountInvalid);
                });
              }
            },
          ),
        ]),
      ),
    ),
  );
}

/// A receipt, with sharing (WhatsApp etc.) as text.
Future<void> showFeeReceipt(BuildContext context, {required String orgId, required String paymentId}) async {
  final F = tr(context).fees;
  final messenger = ScaffoldMessenger.of(context);
  final failed = tr(context).common.loadFailed;
  Map<String, dynamic> r;
  try {
    r = Map<String, dynamic>.from(await SyncService.instance.raw(
        'fee-receipt:$paymentId', () => Supabase.instance.client.rpc('fee_receipt', params: {'p_org': orgId, 'p_payment': paymentId})) as Map);
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(friendlyError(e, failed))));
    return;
  }
  if (!context.mounted) return;
  final cur = '${r['currency'] ?? ''}';
  final left = _n((r['balance'] as Map?)?['balance']);
  final leftText = left > 0 ? '${F.balanceAfter}: ${feeMoney(left, cur)}' : F.settled;
  final rows = <(String, String)>[
    (F.amount, feeMoney(r['amount'], cur)),
    (F.method, F.methods['${r['method']}'] ?? '${r['method']}'),
    ('', _day(r['paid_on'])),
    if (r['recorded_by'] != null) (F.byLabel, '${r['recorded_by']}'),
    if (r['note'] != null) ('', '${r['note']}'),
    ('', leftText),
  ];
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${r['center']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16), textAlign: TextAlign.center),
        Text('${F.receiptTitle} — ${fmt(F.receiptNo, {'n': r['receipt_no']})}', style: const TextStyle(color: kInkMuted), textAlign: TextAlign.center),
        if (r['voided'] == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(child: GardenChip(F.voided, color: Colors.red.shade600, icon: Icons.block_rounded)),
          ),
        const SizedBox(height: 12),
        Text('${r['student']}', style: const TextStyle(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
        const Divider(height: 24),
        for (final (k, v) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              if (k.isNotEmpty) Expanded(child: Text(k, style: const TextStyle(color: kInkMuted))),
              Expanded(flex: k.isEmpty ? 1 : 2, child: Text(v, style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.share_rounded),
          label: Text(F.share),
          onPressed: () => SharePlus.instance.share(ShareParams(
            text: fmt(F.receiptText, {
              'center': r['center'],
              'title': F.receiptTitle,
              'no': fmt(F.receiptNo, {'n': r['receipt_no']}),
              'student': r['student'],
              'amount': feeMoney(r['amount'], cur),
              'date': _day(r['paid_on']),
              'method': F.methods['${r['method']}'] ?? '${r['method']}',
              'left': leftText,
            }),
          )),
        ),
      ]),
    ),
  );
}

/// The family's entry on the portal home - only where fees are switched on.
class FeesTile extends StatelessWidget {
  const FeesTile({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    if (!context.watch<TenantController>().feesEnabled) return const SizedBox.shrink();
    return GardenCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => context.push('/fees/$studentId'),
      child: Row(children: [
        const IconBubble(Icons.payments_rounded, color: Color(0xFF2E7D5B)),
        const SizedBox(width: 12),
        Expanded(child: Text(tr(context).fees.openAccount, style: const TextStyle(fontWeight: FontWeight.w800, color: kInk))),
        Icon(forwardChevron(context), color: kInkMuted),
      ]),
    );
  }
}
