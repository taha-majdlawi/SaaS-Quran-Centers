import 'package:flutter/material.dart';

import '../../core/i18n/i18n.dart';
import '../../core/widgets/format.dart';
import '../../core/widgets/ui.dart';
import 'serd_models.dart';

const _statusColors = <String, MaterialColor>{
  'scheduled': Colors.blue,
  'submitted': Colors.amber,
  'approved': Colors.green,
  'rejected': Colors.red,
};

/// One serd session as a card. [actions] is the admin/teacher button row.
class SerdSessionCard extends StatelessWidget {
  const SerdSessionCard({super.key, required this.row, this.actions});

  final SerdRow row;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final grey = TextStyle(color: Colors.grey.shade600, fontSize: 12.5);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.studentName + (row.studentCode == null ? '' : '  ·  ${row.studentCode}'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
                StatusChip(label: kSerdStatusLabels[row.status] ?? row.status, color: _statusColors[row.status] ?? Colors.grey),
              ],
            ),
            const SizedBox(height: 6),
            Text(fmt(tr(context).serd.partsLine, {'v': serdPartsLabel(row.parts), 'v2': serdJuzEquivalent(row.totalEighths)})),
            const SizedBox(height: 4),
            Text(
              [
                formatDate(row.sessionDate),
                if (row.examinerName != null) fmt(tr(context).serd.examiner, {'examinerName': row.examinerName}),
                if (row.circleTeacherName != null) fmt(tr(context).serd.circleTeacher, {'circleTeacherName': row.circleTeacherName}),
                if (row.status == 'scheduled')
                  row.assignedTeacherName != null ? fmt(tr(context).serd.assignedTo, {'assignedTeacherName': row.assignedTeacherName}) : tr(context).serd.openToAny,
              ].join('  ·  '),
              style: grey,
            ),
            if (row.studentId == null && row.status != 'scheduled')
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: StatusChip(label: tr(context).serd.noStudent, color: Colors.orange),
              ),
            if (row.scorePercent != null) ...[
              const SizedBox(height: 6),
              Text.rich(TextSpan(children: [
                TextSpan(text: tr(context).serd.scoreLabel),
                TextSpan(text: '${row.scorePercent}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                if (row.status == 'approved')
                  TextSpan(text: fmt(tr(context).serd.resultLine, {'v': row.passed ? tr(context).serd.passed : tr(context).serd.repeat, 'passApplied': row.passApplied, 'pointsAwarded': row.pointsAwarded})),
              ])),
            ],
            if (row.errors.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(row.errors.map((e) => '${e.name}: ${e.count} (−${e.deducted}%)').join('  ·  '), style: grey),
              ),
            if (row.notes != null && row.notes!.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 4), child: Text(row.notes!, style: grey)),
            if (row.rejectReason != null && row.rejectReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(fmt(tr(context).serd.rejectReasonV, {'rejectReason': row.rejectReason}), style: const TextStyle(color: Colors.red, fontSize: 12.5)),
              ),
            if (actions != null) ...[const Divider(height: 22), actions!],
          ],
        ),
      ),
    );
  }
}

extension on SerdRow {
  String get passApplied => '${passPercentApplied ?? '—'}%';
}

/// A student's APPROVED serd record. A juz is "done" only when all eight of its
/// eighths are covered, so a half never reads as a whole juz.
class SerdSummaryCard extends StatelessWidget {
  const SerdSummaryCard({super.key, required this.summary});

  final SerdSummary? summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final t = tr(context);
    final c = t.serdCard;
    if (s == null || s.sessionsCount == 0) {
      return Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(c.none)));
    }
    Widget tile(String label, String value) => Expanded(
          child: Column(children: [
            Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5)),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              tile(c.sessions, '${s.sessionsCount}'),
              tile(c.average, s.averageScore == null ? '—' : '${s.averageScore}%'),
              tile(c.best, s.bestScore == null ? '—' : '${s.bestScore}%'),
              tile(c.covered, fmt(c.juzCount, {'n': serdJuzEquivalent(s.eighthsTotal)})),
            ]),
            if (s.juzDone.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(fmt(c.complete, {'list': s.juzDone.map((j) => t.isAr ? '$j (${kJuzNames[j - 1]})' : '$j').join(t.common.listSep)}),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
            if (s.juzProgress.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(fmt(c.partial, {'list': s.juzProgress.map((p) => fmt(c.partialItem, {'juz': p.juz, 'e': p.eighths})).join(t.common.listSep)}),
                  style: TextStyle(color: Colors.grey.shade700)),
            ],
            const Divider(height: 22),
            for (final row in s.sessions.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(child: Text('${serdPartsLabel(row.parts)}\n${formatDate(row.sessionDate)}', style: const TextStyle(fontSize: 13))),
                    Text('${row.scorePercent}%  +${row.pointsAwarded}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PartInput {
  _PartInput({this.juz, this.den = 1, this.index = 1});
  int? juz;
  int den;
  int index;
}

/// Rows of "which juz + which amount". Only the amounts in [denominators] are
/// offered (the server re-checks them against the student's stage).
class SerdPartsEditor extends StatefulWidget {
  const SerdPartsEditor({super.key, required this.denominators, required this.onChanged, this.initial = const []});

  final List<int> denominators;
  final List<SerdPart> initial;
  final ValueChanged<List<SerdPart>> onChanged;

  @override
  State<SerdPartsEditor> createState() => _SerdPartsEditorState();
}

class _SerdPartsEditorState extends State<SerdPartsEditor> {
  late final List<_PartInput> _rows = widget.initial.isEmpty
      ? [_PartInput()]
      : [for (final p in widget.initial) _PartInput(juz: p.juz, den: p.den, index: p.index)];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  void _emit() => widget.onChanged([
        for (final r in _rows)
          if (r.juz != null) SerdPart(juz: r.juz!, den: r.den, index: r.index),
      ]);

  Future<int?> _pickJuz() {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: ListView.builder(
          itemCount: 30,
          itemBuilder: (context, i) => ListTile(
            leading: CircleAvatar(radius: 16, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
            title: Text(kJuzNames[i]),
            onTap: () => Navigator.pop(context, i + 1),
          ),
        ),
      ),
    );
  }

  List<({int den, int index, String label})> get _options => [
        (den: 1, index: 1, label: tr(context).serd.whole),
        for (final d in const [2, 4, 8])
          if (widget.denominators.contains(d))
            for (var i = 1; i <= d; i++) (den: d, index: i, label: serdPortionLabel(d, i)),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _rows.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final j = await _pickJuz();
                          if (j != null) {
                            setState(() => _rows[i].juz = j);
                            _emit();
                          }
                        },
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: Text(_rows[i].juz == null ? tr(context).serd.pickJuz : fmt(tr(context).serd.juzLine2, {'juz': _rows[i].juz, 'v': kJuzNames[_rows[i].juz! - 1]})),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                      ),
                    ),
                    if (_rows.length > 1)
                      IconButton(
                        onPressed: () {
                          setState(() => _rows.removeAt(i));
                          _emit();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
                if (_options.length > 1) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final o in _options)
                        ChoiceChip(
                          label: Text(o.label),
                          selected: _rows[i].den == o.den && _rows[i].index == o.index,
                          onSelected: (_) {
                            setState(() {
                              _rows[i].den = o.den;
                              _rows[i].index = o.index;
                            });
                            _emit();
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () => setState(() => _rows.add(_PartInput())),
          icon: const Icon(Icons.add_circle_outline),
          label: Text(tr(context).serd.addJuz),
        ),
      ],
    );
  }
}
