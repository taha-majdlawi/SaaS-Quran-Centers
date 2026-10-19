import '../../core/data/quran_data.dart';

/// A student's last memorization recitation, newest first (surah, ayahs).
class MemorizedPart {
  const MemorizedPart({required this.surah, required this.ayahFrom, required this.ayahTo});
  final int surah;
  final int ayahFrom;
  final int ayahTo;
}

/// Where the next memorization starts, worked out from where the student stopped
/// (same rule as apps/web/src/lib/quran/next-position.ts).
class NextPosition {
  const NextPosition({required this.lastSurah, required this.lastAyah, required this.finishedSurah, this.surah, this.ayahFrom});

  /// The surah and ayah the student reached last time.
  final int lastSurah;
  final int lastAyah;

  /// The last recitation reached the end of [lastSurah].
  final bool finishedSurah;

  /// Where to carry on: the next surah from ayah 1, or the same surah after [lastAyah].
  /// Null when there is nothing left in that direction (the whole Quran is done).
  final int? surah;
  final int? ayahFrom;
}

/// Most students memorise from An-Nas towards Al-Fatiha (114, 113, ...); some from the start
/// (Al-Baqara onwards). The direction is read from their own last two different surahs; with
/// only one, from the end of the mushaf - the usual way.
NextPosition? nextPosition(List<MemorizedPart> newestFirst) {
  if (newestFirst.isEmpty) return null;
  final last = newestFirst.first;
  if (last.surah < 1 || last.surah > 114) return null;
  final count = ayahCount(last.surah);
  final finished = last.ayahTo >= count;
  if (!finished) {
    return NextPosition(lastSurah: last.surah, lastAyah: last.ayahTo, finishedSurah: false, surah: last.surah, ayahFrom: last.ayahTo + 1);
  }
  final previous = newestFirst.skip(1).where((p) => p.surah != last.surah).map((p) => p.surah).firstOrNull;
  final forward = previous != null && previous < last.surah;
  final next = forward ? last.surah + 1 : last.surah - 1;
  final inRange = next >= 1 && next <= 114;
  return NextPosition(
    lastSurah: last.surah,
    lastAyah: last.ayahTo,
    finishedSurah: true,
    surah: inRange ? next : null,
    ayahFrom: inRange ? 1 : null,
  );
}
