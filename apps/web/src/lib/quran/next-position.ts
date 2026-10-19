import { AYAH_COUNTS } from './data';

/** A new-memorization recitation (surah, ayahs). */
export interface MemorizedPart {
  surah: number;
  ayahFrom: number;
  ayahTo: number;
}

/** Where the next memorization starts (same rule as the app's next_position.dart). */
export interface NextPosition {
  /** The surah and ayah the student reached last time. */
  lastSurah: number;
  lastAyah: number;
  /** The last recitation reached the end of that surah. */
  finishedSurah: boolean;
  /** Where to carry on - null when nothing is left in that direction (the whole Quran done). */
  surah: number | null;
  ayahFrom: number | null;
}

/**
 * From the student's latest memorization recitations, newest first. Most students memorise from
 * An-Nas towards Al-Fatiha (114, 113, ...), some from the start; the direction is read from their
 * last two different surahs, and with only one, from the end of the mushaf - the usual way.
 */
export function nextPosition(newestFirst: MemorizedPart[]): NextPosition | null {
  const last = newestFirst[0];
  if (!last || last.surah < 1 || last.surah > 114) return null;
  const finished = last.ayahTo >= AYAH_COUNTS[last.surah - 1];
  if (!finished) {
    return { lastSurah: last.surah, lastAyah: last.ayahTo, finishedSurah: false, surah: last.surah, ayahFrom: last.ayahTo + 1 };
  }
  const previous = newestFirst.slice(1).find((p) => p.surah !== last.surah)?.surah;
  const next = previous != null && previous < last.surah ? last.surah + 1 : last.surah - 1;
  const inRange = next >= 1 && next <= 114;
  return { lastSurah: last.surah, lastAyah: last.ayahTo, finishedSurah: true, surah: inRange ? next : null, ayahFrom: inRange ? 1 : null };
}
