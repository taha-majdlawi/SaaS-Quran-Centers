import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/org_avatar.dart';
import '../../core/widgets/ui.dart';
import '../students/students_repository.dart';
import 'certificates_repository.dart';

String _day(DateTime d) => '${d.toLocal().day}/${d.toLocal().month}/${d.toLocal().year}';

String _msg(Object e) => e is PostgrestException ? e.message : (e is StateError ? e.message : currentStrings.cert.failed);

// ---------------------------------------------------------------------------
// List: staff (issue / revoke / template) and the family portal (own only)
// ---------------------------------------------------------------------------

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key, this.portal = false});

  final bool portal;

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  final _repository = CertificatesRepository(AppSupabase.client);
  Future<CertificateList>? _future;
  String? _orgId;

  bool get _isAdmin => context.read<TenantController>().active?.role == OrgRole.admin;

  void _reload() => setState(() => _future = _repository.list(_orgId!));

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _issue() async {
    final students = await StudentsRepository(AppSupabase.client).fetchStudents(_orgId!);
    if (!mounted) return;
    String? studentId;
    String kind = 'custom';
    final title = TextEditingController();
    final description = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(tr(context).cert.issueTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: studentId,
                decoration: InputDecoration(labelText: tr(context).cert.student),
                items: [for (final s in students) DropdownMenuItem(value: s.id, child: Text('${s.fullName} — ${s.studentCode}', overflow: TextOverflow.ellipsis))],
                onChanged: (v) => setSheet(() => studentId = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: kind,
                decoration: InputDecoration(labelText: tr(context).cert.kind),
                items: [for (final e in kCertificateKindLabels.entries.where((e) => e.key != 'serd')) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setSheet(() => kind = v ?? kind),
              ),
              const SizedBox(height: 10),
              TextField(controller: title, maxLength: 120, decoration: InputDecoration(labelText: tr(context).cert.fieldTitle, hintText: tr(context).cert.titleHint)),
              TextField(controller: description, maxLength: 500, maxLines: 2, decoration: InputDecoration(labelText: tr(context).cert.fieldText)),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  if (studentId == null || title.text.trim().length < 2) return;
                  Navigator.pop(context, true);
                },
                child: Text(tr(context).cert.issue),
              ),
              const SizedBox(height: 4),
              Text(tr(context).cert.serdHint, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ]),
          ),
        ),
      ),
    );
    if (ok != true || studentId == null) return;
    try {
      await _repository.issue(orgId: _orgId!, studentId: studentId!, kind: kind, title: title.text.trim(), description: description.text.trim().isEmpty ? null : description.text.trim());
      if (mounted) {
        _toast(currentStrings.cert.issued);
        _reload();
      }
    } catch (e) {
      if (mounted) _toast(_msg(e));
    }
  }

  Future<void> _revoke(CertificateRow c) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr(context).cert.revokeTitle),
        content: TextField(controller: reason, decoration: InputDecoration(labelText: tr(context).cert.reason)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).common.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(context).cert.revoke, style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repository.revoke(_orgId!, c.id, reason.text.trim().isEmpty ? null : reason.text.trim());
      if (mounted) {
        _toast(currentStrings.cert.revoked);
        _reload();
      }
    } catch (e) {
      if (mounted) _toast(_msg(e));
    }
  }

  Future<void> _settings() async {
    final CertificateSettings s;
    try {
      s = await _repository.settings(_orgId!);
    } catch (e) {
      _toast(_msg(e));
      return;
    }
    final name = TextEditingController(text: s.signerName ?? '');
    final role = TextEditingController(text: s.signerTitle ?? '');
    final footer = TextEditingController(text: s.footer ?? '');
    final serd = TextEditingController(text: s.serdTitle);
    var auto = s.autoSerd;
    if (!mounted) return;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(tr(context).cert.customizeTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              TextField(controller: name, maxLength: 80, decoration: InputDecoration(labelText: tr(context).cert.signer)),
              TextField(controller: role, maxLength: 80, decoration: InputDecoration(labelText: tr(context).cert.signerRole, hintText: tr(context).cert.signerRoleHint)),
              TextField(controller: footer, maxLength: 200, decoration: InputDecoration(labelText: tr(context).cert.footer)),
              TextField(controller: serd, maxLength: 120, decoration: InputDecoration(labelText: tr(context).cert.serdTitle)),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(tr(context).cert.autoSerd), value: auto, onChanged: (v) => setSheet(() => auto = v)),
              Text(tr(context).cert.futureOnly, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(context).common.save)),
            ]),
          ),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await _repository.saveSettings(_orgId!, signerName: name.text, signerTitle: role.text, footer: footer.text, serdTitle: serd.text, autoSerd: auto);
      if (mounted) _toast(currentStrings.cert.saved);
    } catch (e) {
      if (mounted) _toast(_msg(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final org = context.watch<TenantController>().active?.organization;
    if (org == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_orgId != org.id) {
      _orgId = org.id;
      _future = _repository.list(org.id);
    }

    return Scaffold(
      appBar: AppBar(
        leading: const DrawerLeading(),
        title: Text(tr(context).cert.title),
        actions: [if (!widget.portal && _isAdmin) IconButton(tooltip: tr(context).cert.customize, onPressed: _settings, icon: const Icon(Icons.tune_rounded))],
      ),
      drawer: widget.portal ? null : const AppDrawer(),
      floatingActionButton: widget.portal ? null : FloatingActionButton.extended(onPressed: _issue, icon: Icon(Icons.add_rounded), label: Text(tr(context).cert.add)),
      body: FutureBuilder<CertificateList>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(onRetry: _reload);
          final data = snap.data;
          if (data == null) return const Center(child: CircularProgressIndicator());
          if (data.rows.isEmpty) return EmptyState(icon: Icons.workspace_premium_rounded, title: tr(context).cert.none);
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), children: [
              for (final c in data.rows)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.workspace_premium_rounded, color: c.revoked ? Colors.grey : Theme.of(context).colorScheme.primary, size: 32),
                    title: Text(c.title, style: TextStyle(fontWeight: FontWeight.w700, decoration: c.revoked ? TextDecoration.lineThrough : null)),
                    subtitle: Text('${c.recipient} · ${kCertificateKindLabels[c.kind] ?? c.kind} · ${_day(c.issuedAt)}${c.revoked ? tr(context).cert.revokedMark : ''}'),
                    trailing: (!widget.portal && data.canIssue && !c.revoked)
                        ? IconButton(tooltip: tr(context).cert.revoke, icon: const Icon(Icons.block_rounded, color: Colors.red), onPressed: () => _revoke(c))
                        : null,
                    onTap: () => context.push(widget.portal ? '/my/certificates/${c.id}' : '/certificates/${c.id}'),
                  ),
                ),
            ]),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One certificate: drawn like the printed one; the verify link can be copied
// (the printable PDF is one tap away on the web).
// ---------------------------------------------------------------------------

class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key, required this.certificateId});

  final String certificateId;

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final _repository = CertificatesRepository(AppSupabase.client);
  Future<Map<String, dynamic>?>? _future;

  @override
  Widget build(BuildContext context) {
    final org = context.watch<TenantController>().active?.organization;
    if (org == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    _future ??= _repository.get(org.id, widget.certificateId);

    return Scaffold(
      appBar: AppBar(title: Text(tr(context).cert.one)),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(onRetry: () => setState(() => _future = _repository.get(org.id, widget.certificateId)));
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final c = snap.data;
          if (c == null) return EmptyState(icon: Icons.search_off_rounded, title: tr(context).cert.notFound);
          final center = c['center'] as Map<String, dynamic>;
          final color = parseBrandColor(center['primary_color'] as String?);
          final revoked = c['revoked_at'] != null;
          final verify = 'https://${center['slug']}.bustan-alquran.com/verify/${c['serial']}';

          return ListView(padding: const EdgeInsets.all(16), children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: color, width: 6), borderRadius: BorderRadius.circular(4)),
              child: Stack(children: [
                if (revoked)
                  Positioned.fill(
                    child: Center(
                      child: Transform.rotate(
                        angle: -0.2,
                        child: Text('ملغاة', style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: Colors.red.withValues(alpha: 0.35))),
                      ),
                    ),
                  ),
                Column(children: [
                  OrgAvatar(name: '${center['name']}', logoUrl: center['logo_url'] as String?, brandColor: center['primary_color'] as String?, size: 56),
                  const SizedBox(height: 6),
                  Text('${center['name']}', style: TextStyle(fontWeight: FontWeight.w800, color: color)),
                  const SizedBox(height: 24),
                  Text('${c['title']}', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 30, fontWeight: FontWeight.w700, color: color)),
                  const SizedBox(height: 10),
                  Text('تشهد إدارة المركز بأن', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Text('${c['recipient_name']}', textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 26, fontWeight: FontWeight.w700)),
                  if (c['description'] != null) ...[
                    const SizedBox(height: 10),
                    Text('${c['description']}', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.7, color: Colors.grey.shade800)),
                  ],
                  if (c['footer'] != null) ...[
                    const SizedBox(height: 8),
                    Text('${c['footer']}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                  const SizedBox(height: 24),
                  if (c['signer_name'] != null || c['signer_title'] != null)
                    Column(children: [
                      Container(width: 140, height: 1, color: Colors.grey),
                      const SizedBox(height: 4),
                      Text('${c['signer_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${c['signer_title'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ]),
                  const SizedBox(height: 14),
                  Text(_day(DateTime.parse(c['issued_at'] as String)), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text('${c['serial']}', textDirection: TextDirection.ltr, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey.shade500)),
                ]),
              ]),
            ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: verify));
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context).cert.linkCopied)));
              },
              icon: const Icon(Icons.link_rounded),
              label: Text(tr(context).cert.copyLink),
            ),
            const SizedBox(height: 6),
            Text(tr(context).cert.pdfHint, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ]);
        },
      ),
    );
  }
}
