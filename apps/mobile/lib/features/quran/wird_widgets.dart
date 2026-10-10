import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/quran_data.dart';
import '../../core/i18n/i18n.dart';
import '../../core/offline/sync_service.dart';
import '../../core/tenant/tenant_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/widgets/garden.dart';
import 'quran_data.dart' show QuranTextService, wordRanges, arabicNumber;

/// ورد اليوم: the new portion and the review portion, each with "recite now"
/// that opens the mushaf on it with the recite panel ready (student_wird, 0086).
/// The family recites from it; the student's teacher only sees it.
class WirdCard extends StatefulWidget {
  const WirdCard({super.key, required this.studentId, this.canRecite = false});

  final String studentId;
  final bool canRecite;

  static Future<Map<String, dynamic>?> load(SupabaseClient client, String orgId, String studentId) async =>
      (await SyncService.instance.raw('wird:$orgId:$studentId', () => client.rpc('student_wird', params: {'p_org': orgId, 'p_student': studentId}))) as Map<String, dynamic>?;

  @override
  State<WirdCard> createState() => _WirdCardState();
}

class _WirdCardState extends State<WirdCard> {
  Future<Map<String, dynamic>?>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  void _load({bool force = false}) {
    final orgId = context.read<TenantController>().active?.organization.id;
    if ((force || _future == null) && orgId != null) {
      _future = WirdCard.load(Supabase.instance.client, orgId, widget.studentId).catchError((_) => null);
    }
  }

  /// the family recites it (live screen); the teacher opens it in the mushaf
  String _path(int surah, int from, int to, String type) => widget.canRecite
      ? '/my/recite?s=${widget.studentId}&surah=$surah&from=$from&to=$to&type=$type'
      : '/quran/$surah?ayah=$from';

  Future<void> _open(String path) async {
    await context.push(path);
    if (mounted) setState(() => _load(force: true));
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) return const SizedBox.shrink();
    final W = tr(context).wird;
    return FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (context, snap) {
        final w = snap.data;
        if (w == null) return const SizedBox.shrink();
        final n = w['new'] as Map<String, dynamic>?;
        final r = w['review'] as Map<String, dynamic>?;
        final rows = <Widget>[];
        if (n != null) {
          final s = n['surah'] as int;
          rows.add(_row(
            context,
            W.newPart,
            '${surahName(s)} ${n['ayah_from']}–${n['ayah_to']}',
            null,
            n['state'] as String,
            _path(s, n['ayah_from'] as int, n['ayah_to'] as int, 'new_memorization'),
          ));
        }
        if (r != null) {
          final a = r['surah_from'] as int, b = r['surah_to'] as int;
          final to = a == b ? r['ayah_to'] as int : ayahCount(a);
          rows.add(_row(
            context,
            W.reviewPart,
            a == b ? '${surahName(a)} ${r['ayah_from']}–${r['ayah_to']}' : '${surahName(a)} ${r['ayah_from']} — ${surahName(b)} ${r['ayah_to']}',
            '${fmt(W.pages, {'n': r['pages']})} · ${r['approved'] == true ? W.fromTeacher : W.suggested}',
            r['state'] as String,
            _path(a, r['ayah_from'] as int, to, 'recent_review'),
          ));
        }
        return GardenCard(
          margin: const EdgeInsets.only(top: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              IconBubble(w['complete'] == true ? Icons.task_alt_rounded : Icons.menu_book_rounded,
                  color: w['complete'] == true ? TeacherStyle.success : Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(W.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            ]),
            if (w['working_day'] == false) Padding(padding: const EdgeInsets.only(top: 6), child: Text(W.dayOff, style: const TextStyle(fontSize: 12, color: kInkMuted))),
            if (w['complete'] == true)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text(W.complete, style: TextStyle(color: TeacherStyle.success, fontWeight: FontWeight.w700))),
            if (rows.isEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(W.none, style: const TextStyle(color: kInkMuted))) else ...rows,
          ]),
        );
      },
    );
  }

  Widget _row(BuildContext context, String title, String label, String? note, String state, String path) {
    final W = tr(context).wird;
    final chip = switch (state) {
      'done' => GardenChip(W.done, color: TeacherStyle.success, icon: Icons.check_rounded),
      'sent' => GardenChip(W.sent, color: const Color(0xFFB26A00), icon: Icons.schedule_rounded),
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(note == null ? title : '$title · $note', style: const TextStyle(fontSize: 12, color: kInkMuted)),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
        if (chip != null)
          chip
        else
          FilledButton.icon(
            // the theme's full-width minimum has no width to fill in a row: the whole card failed to lay out (blank)
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, minimumSize: const Size(0, 40)),
            onPressed: () => _open(path),
            icon: Icon(widget.canRecite ? Icons.mic_rounded : Icons.auto_stories_rounded, size: 16),
            label: Text(widget.canRecite ? W.recite : W.open),
          ),
      ]),
    );
  }
}

/// Where a student keeps slipping (recitation_mistake_stats, 0086): by surah, ayah and word.
class MistakeStatsCard extends StatelessWidget {
  const MistakeStatsCard({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    final orgId = context.read<TenantController>().active?.organization.id;
    if (orgId == null) return const SizedBox.shrink();
    final M = tr(context).mistakes;
    return FutureBuilder<dynamic>(
      future: SyncService.instance
          .raw('mistakes:$orgId:$studentId', () => Supabase.instance.client.rpc('recitation_mistake_stats', params: {'p_org': orgId, 'p_student': studentId, 'p_days': 90}))
          .catchError((_) => null),
      builder: (context, snap) {
        final d = snap.data as Map<String, dynamic>?;
        if (d == null || (d['sessions'] as num? ?? 0) == 0) return const SizedBox.shrink();
        final bySurah = (d['by_surah'] as List).cast<Map<String, dynamic>>();
        final byAyah = (d['by_ayah'] as List).cast<Map<String, dynamic>>();
        final byWord = (d['by_word'] as List).cast<Map<String, dynamic>>();
        final max = bySurah.fold<int>(1, (m, s) => (s['count'] as int) > m ? s['count'] as int : m);
        Widget head(String t) => Padding(padding: const EdgeInsets.only(top: 12, bottom: 6), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800)));
        Text times(int n) => Text(fmt(M.times, {'n': n}), style: TextStyle(color: n > 1 ? Colors.red.shade700 : kInkMuted, fontWeight: n > 1 ? FontWeight.w700 : null));

        return GardenCard(
          margin: const EdgeInsets.only(top: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(M.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text('${fmt(M.hint, {'days': d['days']})} · ${fmt(M.summary, {'sessions': d['sessions'], 'mistakes': d['mistakes']})}',
                style: const TextStyle(fontSize: 12, color: kInkMuted)),
            if ((d['mistakes'] as num? ?? 0) == 0)
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(M.none))
            else ...[
              head(M.bySurah),
              for (final s in bySurah)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [Expanded(child: Text(surahName(s['surah'] as int))), Text('${s['count']}', style: const TextStyle(color: kInkMuted))]),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: (s['count'] as int) / max, minHeight: 6, color: Colors.red.shade300, backgroundColor: Colors.grey.shade100),
                    ),
                  ]),
                ),
              if (byAyah.isNotEmpty) head(M.byAyah),
              for (final a in byAyah)
                InkWell(
                  onTap: () => context.push('/quran/${a['surah']}?ayah=${a['ayah']}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Expanded(child: Text(fmt(M.ayah, {'surah': surahName(a['surah'] as int), 'ayah': a['ayah']}), style: TextStyle(color: Theme.of(context).colorScheme.primary))),
                      times(a['count'] as int),
                    ]),
                  ),
                ),
              if (byWord.isNotEmpty) head(M.byWord),
              if (byWord.isNotEmpty) _Words(items: byWord, times: times),
            ],
          ]),
        );
      },
    );
  }
}

class _Words extends StatelessWidget {
  const _Words({required this.items, required this.times});

  final List<Map<String, dynamic>> items;
  final Text Function(int n) times;

  @override
  Widget build(BuildContext context) {
    final surahs = {for (final i in items) if (i['text'] == null) i['surah'] as int};
    return FutureBuilder<Map<String, String>>(
      future: () async {
        final out = <String, String>{};
        for (final s in surahs) {
          try {
            final d = await QuranTextService().surah(s);
            for (final a in d.ayahs) {
              out['$s:${a.number}'] = a.text;
            }
          } catch (_) {}
        }
        return out;
      }(),
      builder: (context, snap) {
        String word(Map<String, dynamic> i) {
          final t = i['text'] as String?;
          if (t != null && t.isNotEmpty) return t;
          final text = snap.data?['${i['surah']}:${i['ayah']}'];
          if (text == null) return '…';
          final r = wordRanges(text);
          final w = i['word'] as int;
          return w < r.length ? text.substring(r[w].$1, r[w].$2) : '…';
        }

        return Column(children: [
          for (final i in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Expanded(
                  child: Text('${word(i)} ${arabicNumber(i['ayah'] as int)}',
                      textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 19, color: Colors.red.shade800)),
                ),
                times(i['count'] as int),
              ]),
            ),
        ]);
      },
    );
  }
}
