// Extra home-screen sections (parity round with eqraa's home tab): goals,
// announcements/upcoming previews, daily ayah, prayer times, badges preview.
// Each widget takes plain data - no fetching here, see my_portal_repository.dart.
import 'dart:convert';

import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../calendar/calendar_models.dart';
import '../comms/comms_repository.dart' show Announcement;
import '../engagement/engagement_models.dart' show BadgeProgress;

// ---- next goals -------------------------------------------------------

class StudentGoal {
  const StudentGoal({required this.label, required this.remaining, required this.unit, required this.progress, required this.icon});
  final String label;
  final int remaining;
  final String unit;
  final double progress;
  final IconData icon;
}

/// Always-meaningful next milestones - the whole-Quran target (while short of
/// it) plus the next round hundred points. Mirrors eqraa's nextGoals exactly
/// (hardcoded milestones, not a stages/goals table).
List<StudentGoal> computeGoals(int totalParts, int totalPoints) {
  final goals = <StudentGoal>[];
  if (totalParts < 30) {
    goals.add(StudentGoal(
      label: 'لإكمال حفظ القرآن الكريم',
      remaining: 30 - totalParts,
      unit: 'جزء',
      progress: (totalParts / 30).clamp(0.0, 1.0),
      icon: Icons.auto_stories_rounded,
    ));
  }
  final nextHundred = ((totalPoints ~/ 100) + 1) * 100;
  goals.add(StudentGoal(
    label: 'للوصول إلى $nextHundred نقطة',
    remaining: nextHundred - totalPoints,
    unit: 'نقطة',
    progress: ((totalPoints % 100) / 100).clamp(0.0, 1.0),
    icon: Icons.stars_rounded,
  ));
  return goals;
}

class NextGoalsCard extends StatelessWidget {
  const NextGoalsCard({super.key, required this.goals});
  final List<StudentGoal> goals;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < goals.length; i++) ...[
              if (i > 0) const Divider(height: 20),
              Row(children: [
                Icon(goals[i].icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(goals[i].label, style: const TextStyle(fontWeight: FontWeight.w700))),
                Text('باقي ${goals[i].remaining} ${goals[i].unit}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: goals[i].progress, minHeight: 8)),
            ],
          ],
        ),
      ),
    );
  }
}

// ---- progress ring -----------------------------------------------------

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.progress, required this.centerText, this.size = 92, this.strokeWidth = 9});
  final double progress;
  final String centerText;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: strokeWidth,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        Text(centerText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
      ]),
    );
  }
}

// ---- announcements preview ---------------------------------------------

class AnnouncementsPreviewCard extends StatelessWidget {
  const AnnouncementsPreviewCard({super.key, required this.announcements});
  final List<Announcement> announcements;

  @override
  Widget build(BuildContext context) {
    final visible = announcements.where((a) => !a.draft).take(2).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Card(
      color: Colors.amber.shade50,
      child: InkWell(
        onTap: () => context.push('/announcements'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.campaign_rounded, color: Colors.amber.shade800, size: 20),
                const SizedBox(width: 8),
                const Text('إعلانات', style: TextStyle(fontWeight: FontWeight.w800)),
              ]),
              for (final a in visible)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- upcoming (7-day) events strip --------------------------------------

class UpcomingEventsCard extends StatelessWidget {
  const UpcomingEventsCard({super.key, required this.entries});
  final List<CalEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Card(
      child: InkWell(
        onTap: () => context.push('/calendar'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: const [
                Icon(Icons.event_rounded, size: 20),
                SizedBox(width: 8),
                Text('قريبًا', style: TextStyle(fontWeight: FontWeight.w800)),
              ]),
              for (final e in entries.take(3))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: e.typeColor, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(formatDayRange(e.startDate, e.startDate), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- daily ayah / quote --------------------------------------------------

class _Inspiration {
  const _Inspiration(this.text, this.source);
  final String text;
  final String source;
}

List<_Inspiration>? _inspirationsCache;

Future<List<_Inspiration>> _loadInspirations() async {
  if (_inspirationsCache != null) return _inspirationsCache!;
  final raw = await rootBundle.loadString('assets/data/daily_inspirations.json');
  final list = jsonDecode(raw) as List;
  _inspirationsCache = [for (final e in list) _Inspiration(e['text'] as String, e['source'] as String)];
  return _inspirationsCache!;
}

class DailyInspirationCard extends StatelessWidget {
  const DailyInspirationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_Inspiration>>(
      future: _loadInspirations(),
      builder: (context, snap) {
        final list = snap.data;
        if (list == null || list.isEmpty) return const SizedBox.shrink();
        final now = DateTime.now();
        final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
        final pick = list[dayOfYear % list.length];
        return Card(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(pick.text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.5)),
                const SizedBox(height: 6),
                Text(pick.source, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---- prayer times ---------------------------------------------------------

class PrayerEntry {
  const PrayerEntry(this.label, this.time);
  final String label;
  final DateTime time;
}

class TodayPrayers {
  const TodayPrayers(this.entries, this.nextIndex);
  final List<PrayerEntry> entries;
  final int nextIndex;
}

const Map<String, adhan.CalculationMethod> _calcMethods = {
  'muslim_world_league': adhan.CalculationMethod.muslim_world_league,
  'egyptian': adhan.CalculationMethod.egyptian,
  'karachi': adhan.CalculationMethod.karachi,
  'umm_al_qura': adhan.CalculationMethod.umm_al_qura,
  'dubai': adhan.CalculationMethod.dubai,
  'moon_sighting_committee': adhan.CalculationMethod.moon_sighting_committee,
  'north_america': adhan.CalculationMethod.north_america,
  'kuwait': adhan.CalculationMethod.kuwait,
  'qatar': adhan.CalculationMethod.qatar,
  'singapore': adhan.CalculationMethod.singapore,
  'turkey': adhan.CalculationMethod.turkey,
  'tehran': adhan.CalculationMethod.tehran,
};

/// Coordinates are the center's own configured location (organization_settings
/// prayer_lat/prayer_lng), never on-device geolocation - matches eqraa, and
/// avoids a location-permission prompt entirely.
TodayPrayers? computeTodayPrayers(Map<String, String> settings) {
  try {
    final lat = double.tryParse(settings['prayer_lat'] ?? '');
    final lng = double.tryParse(settings['prayer_lng'] ?? '');
    if (lat == null || lng == null) return null;
    final method = _calcMethods[settings['prayer_calc_method']] ?? adhan.CalculationMethod.egyptian;
    final params = method.getParameters();
    params.madhab = settings['prayer_madhab'] == 'hanafi' ? adhan.Madhab.hanafi : adhan.Madhab.shafi;

    final pt = adhan.PrayerTimes.today(adhan.Coordinates(lat, lng), params);
    final entries = [
      PrayerEntry('الفجر', pt.fajr),
      PrayerEntry('الظهر', pt.dhuhr),
      PrayerEntry('العصر', pt.asr),
      PrayerEntry('المغرب', pt.maghrib),
      PrayerEntry('العشاء', pt.isha),
    ];
    final now = DateTime.now();
    var next = entries.indexWhere((e) => e.time.isAfter(now));
    if (next == -1) next = 0;
    return TodayPrayers(entries, next);
  } catch (_) {
    return null;
  }
}

class PrayerTimesCard extends StatelessWidget {
  const PrayerTimesCard({super.key, required this.today});
  final TodayPrayers today;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (var i = 0; i < today.entries.length; i++) _prayerCell(today.entries[i], i == today.nextIndex),
          ],
        ),
      ),
    );
  }

  Widget _prayerCell(PrayerEntry e, bool isNext) {
    final time = '${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: isNext ? const Color(0xFF1E7A54) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        Text(e.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isNext ? Colors.white : null)),
        const SizedBox(height: 4),
        Text(time, style: TextStyle(fontSize: 13, color: isNext ? const Color(0xFFD4A24C) : Colors.grey.shade600)),
      ]),
    );
  }
}

// ---- badges preview -------------------------------------------------------

class BadgesPreviewRow extends StatelessWidget {
  const BadgesPreviewRow({super.key, required this.badges});
  final List<BadgeProgress> badges;

  @override
  Widget build(BuildContext context) {
    final earned = badges.where((b) => b.earned).toList();
    if (earned.isEmpty) return const SizedBox.shrink();
    return Card(
      child: InkWell(
        onTap: () => context.push('/my/badges'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('شاراتك', style: TextStyle(fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${earned.length}', style: TextStyle(color: Colors.grey.shade600)),
                const Icon(Icons.chevron_left_rounded, size: 18),
              ]),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final b in earned.take(8))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: b.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(b.icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(b.name, style: TextStyle(color: b.color, fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
