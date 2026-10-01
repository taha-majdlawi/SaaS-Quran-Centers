import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n/i18n.dart';
import '../../core/offline/sync_service.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/widgets/garden.dart';
import '../../core/widgets/ui.dart';
import '../profiles/profile_widgets.dart' show relDay, numText;
import '../recitation/recitation_repository.dart';
import '../recitation/recitation_sheet.dart';

/// The students a teacher (their circles) or an admin (the center) should look
/// at first: behind their goal, not reciting, often absent - ranked in SQL
/// (`students_needing_attention`), kept for offline use.
class AttentionScreen extends StatefulWidget {
  const AttentionScreen({super.key});

  static Future<List<dynamic>> load(SupabaseClient client, String orgId) async =>
      (await SyncService.instance.raw('attention:$orgId', () => client.rpc('students_needing_attention', params: {'p_org': orgId}))) as List<dynamic>;

  @override
  State<AttentionScreen> createState() => _AttentionScreenState();
}

class _AttentionScreenState extends State<AttentionScreen> {
  late Future<List<dynamic>> _future;
  String _filter = 'all';

  String get _orgId => context.read<TenantController>().active!.organization.id;

  @override
  void initState() {
    super.initState();
    _future = AttentionScreen.load(Supabase.instance.client, _orgId);
  }

  void _reload() => setState(() => _future = AttentionScreen.load(Supabase.instance.client, _orgId));

  Future<void> _recite(Map<String, dynamic> s) async {
    final grades = await RecitationRepository(Supabase.instance.client).fetchGrades(_orgId);
    if (!mounted) return;
    final points = await showRecitationSheet(context, studentId: s['id'] as String, studentName: s['name'] as String, grades: grades);
    if (points != null && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final A = tr(context).attn;
    return Scaffold(
      appBar: AppBar(title: Text(A.title)),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _future;
        },
        child: AsyncBody<List<dynamic>>(
          future: _future,
          onRetry: _reload,
          builder: (context, rows) {
            final all = rows.cast<Map<String, dynamic>>();
            bool has(Map<String, dynamic> s, List<String> codes) => (s['reasons'] as List).any((r) => codes.contains(r['code']));
            final list = switch (_filter) {
              'behind' => all.where((s) => has(s, ['behind'])).toList(),
              'idle' => all.where((s) => has(s, ['idle', 'never'])).toList(),
              'absent' => all.where((s) => has(s, ['absences'])).toList(),
              _ => all,
            };
            final brand = Theme.of(context).colorScheme.primary;
            return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), children: [
              Text(A.hint, style: const TextStyle(color: kInkMuted, fontSize: 12.5)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final (k, label, n) in [
                    ('all', A.all, all.length),
                    ('behind', A.filterBehind, all.where((s) => has(s, ['behind'])).length),
                    ('idle', A.filterIdle, all.where((s) => has(s, ['idle', 'never'])).length),
                    ('absent', A.filterAbsent, all.where((s) => has(s, ['absences'])).length),
                  ])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text('$label ($n)'),
                        selected: _filter == k,
                        showCheckmark: false,
                        selectedColor: brand,
                        labelStyle: TextStyle(color: _filter == k ? Colors.white : kInk, fontWeight: FontWeight.w700, fontSize: 12.5),
                        onSelected: (_) => setState(() => _filter = k),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Padding(padding: const EdgeInsets.only(top: 60), child: Center(child: Text(A.none, style: const TextStyle(color: kInkMuted, fontSize: 15))))
              else
                for (var i = 0; i < list.length; i++) _card(context, list[i], i),
            ]);
          },
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> s, int i) {
    final A = tr(context).attn;
    final reasons = (s['reasons'] as List).cast<Map<String, dynamic>>();
    final score = (s['score'] as num).toDouble();
    final color = score >= 40 ? TeacherStyle.danger : score >= 20 ? TeacherStyle.warning : TeacherStyle.blue;
    final phone = (s['whatsapp'] ?? s['phone']) as String?;
    String reason(Map<String, dynamic> r) => switch (r['code']) {
          'behind' => fmt(A.behind, {'pages': numText(r['pages'])}),
          'idle' => fmt(A.idle, {'days': r['days']}),
          'never' => A.never,
          'absences' => fmt(A.absences, {'count': r['count']}),
          _ => '${r['code']}',
        };
    IconData icon(String code) => switch (code) {
          'behind' => Icons.trending_down_rounded,
          'idle' || 'never' => Icons.hourglass_bottom_rounded,
          _ => Icons.event_busy_rounded,
        };
    return GardenCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      onTap: () => context.push('/students/${s['id']}/file'),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 5, decoration: BoxDecoration(color: color, borderRadius: const BorderRadiusDirectional.horizontal(start: Radius.circular(kCardRadius)))),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${s['name']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                      Text('${s['circle'] ?? ''}  ·  ${fmt(A.lastRecited, {'v': relDay(context, s['last_recited'] as String?)})}',
                          style: const TextStyle(color: kInkMuted, fontSize: 12)),
                    ]),
                  ),
                  CircleAvatar(radius: 14, backgroundColor: color.withValues(alpha: 0.12), child: Text('${i + 1}', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12))),
                ]),
                const SizedBox(height: 8),
                for (final r in reasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Icon(icon('${r['code']}'), size: 16, color: color),
                      const SizedBox(width: 6),
                      Expanded(child: Text(reason(r), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                    ]),
                  ),
                Row(children: [
                  TextButton.icon(onPressed: () => _recite(s), icon: const Icon(Icons.mic_rounded, size: 18), label: Text(A.recite)),
                  if (phone != null && phone.isNotEmpty)
                    TextButton.icon(onPressed: () => launchUrl(Uri.parse('tel:$phone')), icon: const Icon(Icons.call_rounded, size: 18), label: Text(A.call)),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
