import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import 'comms_repository.dart';

/// Announcements. Everyone reads the ones addressed to them (the server filters
/// by audience); the admin - or a teacher with the module, for their own
/// circle - can publish.
class AnnouncementsListScreen extends StatefulWidget {
  const AnnouncementsListScreen({super.key});

  @override
  State<AnnouncementsListScreen> createState() => _AnnouncementsListScreenState();
}

class _AnnouncementsListScreenState extends State<AnnouncementsListScreen> {
  final _repository = CommsRepository(AppSupabase.client);
  Future<List<Announcement>>? _future;
  String? _orgId;

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<TenantController>();
    final orgId = tenant.active?.organization.id;
    if (orgId != null && orgId != _orgId) {
      _orgId = orgId;
      _future = _repository.announcements(orgId);
    }
    final role = tenant.active?.role;
    final isStaff = role == OrgRole.admin || role == OrgRole.teacher;
    final canWrite = role == OrgRole.admin || (role == OrgRole.teacher && tenant.hasModule('announcements'));

    return Scaffold(
      appBar: AppBar(title: const Text('الإعلانات')),
      drawer: isStaff ? const AppDrawer() : null,
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/announcements/new');
                if (mounted) setState(() => _future = _repository.announcements(_orgId!));
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('إعلان جديد'),
            )
          : null,
      body: _future == null
          ? const SizedBox.shrink()
          : AsyncBody<List<Announcement>>(
              future: _future!,
              onRetry: () => setState(() => _future = _repository.announcements(_orgId!)),
              builder: (context, list) => RefreshIndicator(
                onRefresh: () async => setState(() => _future = _repository.announcements(_orgId!)),
                child: list.isEmpty
                    ? ListView(children: const [SizedBox(height: 80), EmptyState(icon: Icons.campaign_outlined, title: 'لا توجد إعلانات')])
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        children: [
                          for (final a in list)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(child: Text('${a.pinned ? '📌 ' : ''}${a.title}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5))),
                                    if (a.draft) const StatusChip(label: 'مسودة', color: Colors.amber),
                                  ]),
                                  const SizedBox(height: 6),
                                  Text(a.body),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Expanded(
                                      child: Text(
                                        [
                                          if (a.publishedAt != null) formatDate(a.publishedAt),
                                          if (a.author != null) a.author!,
                                          if (isStaff) kAudienceLabels[a.audience] ?? '',
                                          if (isStaff && a.circleName != null) a.circleName!,
                                        ].join('  ·  '),
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ),
                                    if (canWrite && a.canEdit)
                                      TextButton(
                                        onPressed: () async {
                                          await context.push('/announcements/${a.id}', extra: a);
                                          if (mounted) setState(() => _future = _repository.announcements(_orgId!));
                                        },
                                        child: const Text('تعديل'),
                                      ),
                                  ]),
                                ]),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
    );
  }
}

class AnnouncementFormScreen extends StatefulWidget {
  const AnnouncementFormScreen({super.key, this.announcement});

  final Announcement? announcement;

  @override
  State<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends State<AnnouncementFormScreen> {
  final _repository = CommsRepository(AppSupabase.client);
  late final _title = TextEditingController(text: widget.announcement?.title ?? '');
  late final _body = TextEditingController(text: widget.announcement?.body ?? '');
  late String _audience = widget.announcement?.audience ?? 'all';
  late String? _circleId = widget.announcement?.circleId;
  late bool _pinned = widget.announcement?.pinned ?? false;
  late bool _publish = widget.announcement == null ? true : !widget.announcement!.draft;
  late final Future<List<({String id, String name})>> _circles = _loadCircles();
  bool _saving = false;
  String? _error;

  String get _orgId => context.read<TenantController>().active!.organization.id;
  bool get _isAdmin => context.read<TenantController>().active?.role == OrgRole.admin;

  Future<List<({String id, String name})>> _loadCircles() =>
      _repository.myCircles(_orgId, isAdmin: _isAdmin, userId: context.read<AuthController>().currentUser?.id ?? '');

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      setState(() => _error = 'العنوان والنص مطلوبان');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.saveAnnouncement(
        _orgId,
        id: widget.announcement?.id,
        title: _title.text.trim(),
        body: _body.text.trim(),
        audience: _audience,
        circleId: _circleId,
        pinned: _pinned,
        publish: _publish,
        expiresOn: widget.announcement?.expiresOn,
      );
      if (mounted) context.pop();
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: const Text('متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    await _repository.deleteAnnouncement(_orgId, widget.announcement!.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final admin = _isAdmin;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.announcement == null ? 'إعلان جديد' : 'تعديل إعلان'),
        actions: [if (widget.announcement != null) IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete)],
      ),
      body: AsyncBody<List<({String id, String name})>>(
        future: _circles,
        builder: (context, circles) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) MessageBanner(message: _error!),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'العنوان')),
            const SizedBox(height: 12),
            TextField(controller: _body, maxLines: 6, decoration: const InputDecoration(labelText: 'النص')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: !admin && _audience == 'teachers' ? 'guardians' : _audience,
              decoration: const InputDecoration(labelText: 'الجمهور'),
              items: [for (final e in kAudienceLabels.entries) if (admin || e.key != 'teachers') DropdownMenuItem(value: e.key, child: Text(e.value))],
              onChanged: (v) => setState(() => _audience = v ?? 'all'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _circleId,
              isExpanded: true,
              decoration: InputDecoration(labelText: admin ? 'حلقة محددة (اختياري)' : 'حلقتك'),
              items: [
                if (admin) const DropdownMenuItem<String?>(value: null, child: Text('كل الحلقات')),
                for (final c in circles) DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _circleId = v),
            ),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('تثبيت في الأعلى'), value: _pinned, onChanged: (v) => setState(() => _pinned = v)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('نشر الآن'),
              subtitle: const Text('يصل إشعار للجمهور عند أول نشر'),
              value: _publish,
              onChanged: (v) => setState(() => _publish = v),
            ),
            const SizedBox(height: 12),
            LoadingButton(label: 'حفظ', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
