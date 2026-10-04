import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/i18n.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/tenant/organization.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/widgets/ui.dart';
import 'calendar_models.dart';
import 'calendar_repository.dart';
import '../../core/widgets/net_image.dart';

const _siteBase = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://bustan-alquran.com');

class _DetailData {
  const _DetailData(this.entry, this.candidates);
  final CalEntry entry;
  final List<Candidate> candidates;
}

/// One calendar entry. Families see their children with register / cancel /
/// waiting-list buttons; teachers see their own students' roster; the admin
/// sees everyone and records results. Consent (for trips) is shown per child.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _repository = CalendarRepository(AppSupabase.client);
  late Future<_DetailData> _future = _load();

  String get _orgId => context.read<TenantController>().active!.organization.id;
  OrgRole? get _role => context.read<TenantController>().active?.role;

  Future<_DetailData> _load() async {
    final entry = await _repository.fetchDetails(_orgId, widget.eventId);
    final staff = _role == OrgRole.admin || _role == OrgRole.teacher;
    final candidates = staff && entry.supportsRegistration && entry.registrationState != 'ended'
        ? await _repository.fetchCandidates(_orgId, widget.eventId).catchError((_) => <Candidate>[])
        : <Candidate>[];
    return _DetailData(entry, candidates);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
        _reload();
      }
    } on PostgrestException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _copyLink(String token) async {
    await Clipboard.setData(ClipboardData(text: '$_siteBase/consent/$token'));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context).cal.linkCopied)));
  }

  Future<void> _pickCandidate(List<Candidate> candidates) async {
    final picked = await showModalBottomSheet<Candidate>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _CandidatePicker(candidates: candidates),
    );
    if (picked != null) await _run(() => _repository.register(_orgId, widget.eventId, picked.studentId), currentStrings.cal.registeredDone);
  }

  Future<void> _editResult(Participant p) async {
    final rank = TextEditingController(text: p.resultRank?.toString() ?? '');
    final note = TextEditingController(text: p.resultNote ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(fmt(tr(context).cal.resultOf, {'name': p.studentName})),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: rank, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr(context).cal.rank)),
          const SizedBox(height: 10),
          TextField(controller: note, decoration: InputDecoration(labelText: tr(context).cal.note)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).common.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(minimumSize: Size(90, 44)), child: Text(tr(context).common.save)),
        ],
      ),
    );
    final r = int.tryParse(rank.text.trim());
    final n = note.text.trim();
    rank.dispose();
    note.dispose();
    if (ok == true) await _run(() => _repository.setResult(p.registrationId, r, n.isEmpty ? null : n), currentStrings.cal.resultSaved);
  }

  Future<void> _confirm(String title, String body, Future<void> Function() action, String done) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context).common.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(tr(context).common.confirm)),
        ],
      ),
    );
    if (ok == true) await _run(action, done);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _role == OrgRole.admin;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context).cal.details),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await context.push('/calendar/${widget.eventId}/edit');
                if (mounted) _reload();
              },
            ),
        ],
      ),
      body: AsyncBody<_DetailData>(
        future: _future,
        onRetry: _reload,
        builder: (context, data) {
          final e = data.entry;
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _info(e),
                if (e.supportsRegistration) ...[
                  SectionTitle(tr(context).cal.registration),
                  _registrationSummary(e),
                  if (e.mine.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    for (final m in e.mine) _mineCard(e, m),
                  ],
                  if (e.participants.isNotEmpty || _role == OrgRole.admin || _role == OrgRole.teacher) ...[
                    SectionTitle(fmt(tr(context).cal.participants, {'n': e.participants.length})),
                    if (data.candidates.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OutlinedButton.icon(
                          onPressed: () => _pickCandidate(data.candidates),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(tr(context).cal.registerStudent),
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                        ),
                      ),
                    for (final p in e.participants) _participantCard(e, p, isAdmin),
                    if (e.participants.isEmpty) Padding(padding: EdgeInsets.all(12), child: Text(tr(context).cal.noParticipants)),
                  ],
                  if (e.waitlist.isNotEmpty) ...[
                    SectionTitle(fmt(tr(context).cal.waitlistCount, {'n': e.waitlist.length})),
                    for (var i = 0; i < e.waitlist.length; i++) ListTile(dense: true, leading: CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 11))), title: Text(e.waitlist[i].name)),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _info(CalEntry e) {
    Widget row(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(e.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: e.typeColor, borderRadius: BorderRadius.circular(20)),
                child: Text(e.typeName, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ]),
            if (e.description != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(e.description!)),
            if (e.images.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: _imageGallery(e.images)),
            row(Icons.event_rounded, '${formatDayRange(e.startDate, e.endDate)}${e.startsAt == null ? '' : '  ·  ${e.startsAt!.substring(0, 5)}'}'),
            if (e.location != null) row(Icons.place_outlined, e.location!),
            row(Icons.groups_rounded, [
              kAudienceLabels[e.audience] ?? e.audience,
              if (e.circleName != null) fmt(tr(context).cal.circle, {'name': e.circleName}),
              if (e.stageName != null) fmt(tr(context).cal.stage, {'name': e.stageName}),
            ].join('  ·  ')),
            row(Icons.work_outline_rounded, e.isWorkingDay ? tr(context).cal.workDay : tr(context).cal.offDay),
          ],
        ),
      ),
    );
  }

  Widget _imageGallery(List<CalImage> images) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.black,
              insetPadding: const EdgeInsets.all(12),
              child: Stack(children: [
                Positioned.fill(child: InteractiveViewer(child: Center(child: NetImage(images[i].imageUrl, fit: BoxFit.contain)))),
                Positioned(
                  top: 4,
                  left: 4,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ]),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: NetImage(
              images[i].imageUrl,
              width: 180,
              height: 140,
              error: Container(width: 180, height: 140, color: Colors.grey.shade200, child: const Icon(Icons.broken_image_rounded)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _registrationSummary(CalEntry e) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            Text(kStateLabels[e.registrationState] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(fmt(tr(context).cal.taken, {'n': '${e.taken}${e.capacity == null ? '' : ' / ${e.capacity}'}'})),
            if (e.waiting > 0) Text(fmt(tr(context).cal.waiting, {'n': e.waiting})),
            if (e.registrationDeadline != null) Text(fmt(tr(context).cal.deadline, {'date': e.registrationDeadline})),
            if (e.requiresConsent) Text(tr(context).cal.needsConsent, style: TextStyle(color: Colors.orange)),
          ],
        ),
      ),
    );
  }

  Widget _mineCard(CalEntry e, MineRow m) {
    final state = e.registrationState;
    final registered = m.registrationId != null;
    final familyRegistered = m.source == 'self' || m.source == 'guardian';
    Widget? action;
    if (registered) {
      action = familyRegistered && state != 'ended'
          ? OutlinedButton(
              onPressed: () => _confirm(tr(context).cal.unregister, fmt(tr(context).cal.unregisterQ, {'name': m.studentName}), () => _repository.unregister(m.registrationId!), tr(context).cal.unregistered),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, minimumSize: const Size(0, 40)),
              child: Text(tr(context).cal.unregister),
            )
          : Text(tr(context).cal.staffRegistered, style: TextStyle(fontSize: 12));
    } else if (state == 'open') {
      action = FilledButton(
        onPressed: () => _run(() => _repository.register(_orgId, e.id, m.studentId), tr(context).cal.registeredDone),
        style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
        child: Text(tr(context).cal.register),
      );
    } else if (state == 'full' && !m.waiting) {
      action = OutlinedButton(
        onPressed: () => _run(() => _repository.joinWaitlist(_orgId, e.id, m.studentId), tr(context).cal.waitlisted),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
        child: Text(tr(context).cal.joinWaitlist),
      );
    } else if (m.waiting) {
      action = OutlinedButton(
        onPressed: () => _run(() => _repository.leaveWaitlist(_orgId, e.id, m.studentId), tr(context).cal.leftWaitlist),
        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
        child: Text(tr(context).cal.leaveWaitlist),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(m.studentName, style: const TextStyle(fontWeight: FontWeight.w800))),
              if (registered) StatusChip(label: tr(context).cal.registeredChip, color: Colors.green) else if (m.waiting) StatusChip(label: tr(context).cal.waitingChip, color: Colors.amber),
            ]),
            if (registered && e.requiresConsent) ...[
              const SizedBox(height: 8),
              Row(children: [
                StatusChip(
                  label: fmt(tr(context).cal.consent, {'status': kConsentLabels[m.consentStatus] ?? ''}),
                  color: m.consentStatus == 'approved' ? Colors.green : (m.consentStatus == 'declined' ? Colors.red : Colors.amber),
                ),
                if (m.consentStatus == 'pending' && m.consentToken != null)
                  TextButton.icon(onPressed: () => _copyLink(m.consentToken!), icon: Icon(Icons.copy_rounded, size: 16), label: Text(tr(context).cal.copyLink)),
              ]),
            ],
            if (m.resultRank != null) Padding(padding: EdgeInsets.only(top: 8), child: Text('${fmt(tr(context).cal.result, {'rank': m.resultRank})}${m.resultNote == null ? '' : ' — ${m.resultNote}'}')),
            if (action != null) Padding(padding: const EdgeInsets.only(top: 10), child: action),
          ],
        ),
      ),
    );
  }

  Widget _participantCard(CalEntry e, Participant p, bool isAdmin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              InitialAvatar(p.studentName, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.studentName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${p.studentCode}${p.circleName == null ? '' : '  ·  ${p.circleName}'}  ·  ${kSourceLabels[p.source] ?? p.source}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ]),
              ),
              if (e.requiresConsent)
                StatusChip(
                  label: kConsentLabels[p.consentStatus] ?? '',
                  color: p.consentStatus == 'approved' ? Colors.green : (p.consentStatus == 'declined' ? Colors.red : Colors.amber),
                ),
            ]),
            if (p.resultRank != null) Padding(padding: EdgeInsets.only(top: 6), child: Text('${fmt(tr(context).cal.rankN, {'rank': p.resultRank})}${p.resultNote == null ? '' : ' — ${p.resultNote}'}', style: const TextStyle(fontSize: 12.5))),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 0, children: [
              if (p.consentStatus == 'pending') ...[
                TextButton(onPressed: () => _copyLink(p.consentToken), child: Text(tr(context).cal.copyConsent)),
                TextButton(onPressed: () => _run(() => _repository.recordConsent(p.registrationId, 'approved'), tr(context).cal.consentRecorded), child: Text(tr(context).cal.phoneConsent)),
                TextButton(onPressed: () => _run(() => _repository.recordConsent(p.registrationId, 'declined'), tr(context).cal.declineRecorded), child: Text(tr(context).cal.decline)),
              ],
              if (isAdmin) TextButton(onPressed: () => _editResult(p), child: Text(tr(context).cal.resultBtn)),
              TextButton(
                onPressed: () => _confirm(tr(context).cal.unregister, fmt(tr(context).cal.unregisterQ, {'name': p.studentName}), () => _repository.unregister(p.registrationId), tr(context).cal.unregistered),
                child: Text(tr(context).cal.unregister, style: TextStyle(color: Colors.red)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _CandidatePicker extends StatefulWidget {
  const _CandidatePicker({required this.candidates});
  final List<Candidate> candidates;

  @override
  State<_CandidatePicker> createState() => _CandidatePickerState();
}

class _CandidatePickerState extends State<_CandidatePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final items = widget.candidates.where((c) => _query.isEmpty || c.name.contains(_query) || c.code.contains(_query)).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(hintText: tr(context).cal.searchStudent, prefixIcon: Icon(Icons.search_rounded)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) => ListTile(
                leading: InitialAvatar(items[i].name),
                title: Text(items[i].name),
                subtitle: Text('${items[i].code}${items[i].circleName == null ? '' : '  ·  ${items[i].circleName}'}'),
                onTap: () => Navigator.pop(context, items[i]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
