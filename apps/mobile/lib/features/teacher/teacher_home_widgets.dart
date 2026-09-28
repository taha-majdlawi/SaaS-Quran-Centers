import 'package:flutter/material.dart';

import '../../core/i18n/i18n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/teacher_style.dart';
import '../../core/widgets/garden.dart';
import '../recitation/recitation_repository.dart';

/// One circle on the teacher's home: how far today's recitation got (ring),
/// who is here, the two things a teacher does first (start the lesson, check
/// in), and the roster folded underneath.
class TeacherCircleCard extends StatelessWidget {
  const TeacherCircleCard({
    super.key,
    required this.circle,
    this.done,
    this.total,
    this.present,
    this.absent,
    this.dueReviews,
    this.checkedIn,
    this.onOpen,
    this.onStart,
    this.onCheckIn,
    this.roster,
    this.rosterOpen = false,
    this.onToggleRoster,
  });

  final MyCircle circle;
  final int? done;
  final int? total;
  final int? present;
  final int? absent;
  final int? dueReviews;

  /// null = not known yet.
  final bool? checkedIn;
  final VoidCallback? onOpen;
  final VoidCallback? onStart;
  final VoidCallback? onCheckIn;
  final Widget? roster;
  final bool rosterOpen;
  final VoidCallback? onToggleRoster;

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final brand = Theme.of(context).colorScheme.primary;
    final all = total ?? circle.studentCount;
    final finished = done ?? 0;
    final ratio = all == 0 ? 0.0 : finished / all;
    final complete = all > 0 && finished >= all;

    return GardenCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: onOpen,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(kCardRadius)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(circle.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: kInk)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    GardenChip(circle.stageName ?? t.teach.general, icon: Icons.stairs_rounded),
                    if (circle.assistant) GardenChip(t.teach.assistant, color: TeacherStyle.gold, icon: Icons.handshake_rounded),
                    if (present != null) GardenChip(fmt(t.dash.presentN, {'present': present}), color: TeacherStyle.success, icon: Icons.check_circle_rounded),
                    if (absent != null && absent! > 0) GardenChip(fmt(t.dash.absentN, {'absent': absent}), color: TeacherStyle.danger, icon: Icons.cancel_rounded),
                    if (dueReviews != null && dueReviews! > 0)
                      GardenChip(fmt(t.teach.dueReviews, {'n': dueReviews}), color: TeacherStyle.blue, icon: Icons.replay_rounded),
                  ]),
                ]),
              ),
              const SizedBox(width: 12),
              Column(children: [
                GardenRing(
                  value: ratio,
                  size: 62,
                  color: complete ? TeacherStyle.success : brand,
                  center: complete
                      ? const Icon(Icons.check_rounded, color: TeacherStyle.success, size: 28)
                      : Text('$finished/$all', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: kInk)),
                ),
                const SizedBox(height: 4),
                Text(t.teach.recitedToday, style: const TextStyle(fontSize: 10.5, color: kInkMuted, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                label: Text(t.teach.startLesson),
              ),
            ),
            if (checkedIn != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: checkedIn!
                    ? Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: TeacherStyle.success.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.how_to_reg_rounded, color: TeacherStyle.success, size: 19),
                          const SizedBox(width: 4),
                          Flexible(child: Text(t.garden.checkedInShort, overflow: TextOverflow.ellipsis, style: const TextStyle(color: TeacherStyle.success, fontWeight: FontWeight.w800, fontSize: 13))),
                        ]),
                      )
                    : OutlinedButton.icon(
                        onPressed: onCheckIn,
                        icon: const Icon(Icons.how_to_reg_rounded, size: 19),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), padding: const EdgeInsets.symmetric(horizontal: 8)),
                        label: Text(t.garden.checkInShort, overflow: TextOverflow.ellipsis),
                      ),
              ),
            ],
          ]),
        ),
        if (roster != null) ...[
          const Divider(height: 1),
          InkWell(
            onTap: onToggleRoster,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Icon(Icons.groups_2_rounded, size: 20, color: brand),
                const SizedBox(width: 8),
                Expanded(child: Text(fmt(t.garden.studentsN, {'n': all}), style: TextStyle(fontWeight: FontWeight.w700, color: brand))),
                AnimatedRotation(
                  turns: rosterOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more_rounded, color: brand),
                ),
              ]),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: rosterOpen ? Padding(padding: const EdgeInsets.only(bottom: 8), child: roster!) : const SizedBox(width: double.infinity),
          ),
        ],
      ]),
    );
  }
}

/// The first things a teacher reaches for, one tap away.
class TeacherQuickActions extends StatelessWidget {
  const TeacherQuickActions({super.key, required this.actions});

  final List<({IconData icon, String label, Color color, VoidCallback onTap})> actions;

  @override
  Widget build(BuildContext context) {
    // up to four fit side by side on a phone; more scroll sideways
    if (actions.length <= 4) {
      return Row(children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: SizedBox(height: 112, child: GardenTile(icon: actions[i].icon, label: actions[i].label, color: actions[i].color, onTap: actions[i].onTap))),
        ],
      ]);
    }
    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final a = actions[i];
          return SizedBox(width: 92, child: GardenTile(icon: a.icon, label: a.label, color: a.color, onTap: a.onTap));
        },
      ),
    );
  }
}
