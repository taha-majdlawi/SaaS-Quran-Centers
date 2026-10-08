// Comparing what the student recited (the transcript of their recording) with
// the text of the ayahs. It is an aid for the student and the teacher: it can
// tell a missing or a different word, not tajweed or the vowels (the
// transcript has none) - the teacher's listening is the verdict.

import { wordRanges, type Ayah } from './mushaf';

export type WordState = 'ok' | 'missing' | 'wrong';

export interface CheckedWord {
  /** ayah number and the word's index inside it (same split as wordRanges) */
  a: number;
  i: number;
  s: WordState;
  /** what was heard instead, for 'wrong' */
  h?: string;
}

export interface ReciteResult {
  words: CheckedWord[];
  total: number;
  ok: number;
  missing: number;
  wrong: number;
  /** words heard that are not in the range (the isti'adha, a repeated word...) */
  extra: number;
  score: number;
}

const MARKS = /[ؐ-ًؚ-ٰٟۖ-ۭـ]/g;

/** Letters only, the hamza forms folded, no vowels or Quranic marks. */
export function plainWord(w: string): string {
  return w
    .replace(MARKS, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ة/g, 'ه')
    .replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي')
    .replace(/ء/g, '')
    .replace(/[^ء-ي]/g, '');
}

/**
 * The word without its long vowels: the Uthmani script writes some of them small
 * or not at all (ٱلصَّلَوٰةَ / الصلاة, ٱلرَّحْمَٰنِ / الرحمن), a transcript writes them in full.
 */
const skeleton = (w: string) => w.replace(/[اوي]/g, '');

function distance(a: string, b: string): number {
  if (a === b) return 0;
  const prev = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i++) {
    let diag = prev[0];
    prev[0] = i;
    for (let j = 1; j <= b.length; j++) {
      const up = prev[j];
      prev[j] = Math.min(prev[j] + 1, prev[j - 1] + 1, diag + (a[i - 1] === b[j - 1] ? 0 : 1));
      diag = up;
    }
  }
  return prev[b.length];
}

/** Same word, allowing the spelling differences between the mushaf and a transcript. */
/** Same word, only the long vowels apart (written small or not at all in the mushaf). */
export const exactWord = (a: string, b: string) => !!a && (a === b || skeleton(a) === skeleton(b));

/** slack: one more letter allowed (the last word of an ayah - see LiveMatcher.matches). */
export function sameWord(expected: string, heard: string, slack = 0): boolean {
  if (!expected || !heard) return false;
  if (expected === heard) return true;
  const se = skeleton(expected);
  const sh = skeleton(heard);
  if (se === sh && se.length > 0) return true;
  const long = Math.max(se.length, sh.length);
  if (long < 3) return false;
  // one letter off in a short word, about a quarter in a long one
  return distance(se, sh) <= Math.max(1, Math.floor(long / 4)) + (long >= 5 ? slack : 0);
}

/** Transcript -> words (punctuation, digits and Latin letters dropped). */
export function heardWords(transcript: string): string[] {
  return transcript
    .split(/[\s،؛؟.,!?:;"'()\[\]-]+/)
    .map(plainWord)
    .filter(Boolean);
}

/**
 * Aligns the ayahs' words with the heard words (edit distance, with a heard word
 * allowed to be split in two by the transcript: يَـٰٓأَيُّهَا / يا أيها) and marks
 * every expected word ok, missing or wrong.
 */
export function compareRecitation(ayahs: Pick<Ayah, 'number' | 'text'>[], transcript: string): ReciteResult {
  const expected: { a: number; i: number; w: string }[] = [];
  for (const ayah of ayahs) {
    wordRanges(ayah.text).forEach(([s, e], i) => {
      const w = plainWord(ayah.text.slice(s, e));
      // a lone pause or sajda sign is not a word
      if (w) expected.push({ a: ayah.number, i, w });
    });
  }
  const heard = heardWords(transcript);
  const n = expected.length;
  const m = heard.length;

  // cost[i][j]: aligning expected[i..] with heard[j..]
  const INS = 0.6; // an extra heard word costs less than a missing one
  const cost: Float32Array[] = Array.from({ length: n + 1 }, () => new Float32Array(m + 1));
  const step: Uint8Array[] = Array.from({ length: n + 1 }, () => new Uint8Array(m + 1));
  // steps: 1 match, 2 wrong, 3 missing, 4 extra, 5 match of two heard words
  for (let i = n; i >= 0; i--) {
    for (let j = m; j >= 0; j--) {
      if (i === n && j === m) continue;
      let best = Infinity;
      let how = 0;
      if (i < n && j < m) {
        const same = sameWord(expected[i].w, heard[j]);
        const c = cost[i + 1][j + 1] + (same ? 0 : 1);
        if (c < best) [best, how] = [c, same ? 1 : 2];
      }
      if (i < n && j + 1 < m && sameWord(expected[i].w, heard[j] + heard[j + 1])) {
        const c = cost[i + 1][j + 2];
        if (c < best) [best, how] = [c, 5];
      }
      if (i < n) {
        const c = cost[i + 1][j] + 1;
        if (c < best) [best, how] = [c, 3];
      }
      if (j < m) {
        const c = cost[i][j + 1] + INS;
        if (c < best) [best, how] = [c, 4];
      }
      cost[i][j] = best;
      step[i][j] = how;
    }
  }

  const words: CheckedWord[] = [];
  let extra = 0;
  let i = 0;
  let j = 0;
  while (i < n || j < m) {
    const how = step[i][j];
    if (how === 1 || how === 5) {
      words.push({ a: expected[i].a, i: expected[i].i, s: 'ok' });
      i++;
      j += how === 5 ? 2 : 1;
    } else if (how === 2) {
      words.push({ a: expected[i].a, i: expected[i].i, s: 'wrong', h: heard[j] });
      i++;
      j++;
    } else if (how === 3) {
      words.push({ a: expected[i].a, i: expected[i].i, s: 'missing' });
      i++;
    } else {
      extra++;
      j++;
    }
  }

  const ok = words.filter((w) => w.s === 'ok').length;
  const missing = words.filter((w) => w.s === 'missing').length;
  const wrong = words.length - ok - missing;
  return { words, total: n, ok, missing, wrong, extra, score: n ? Math.round((ok / n) * 1000) / 10 : 0 };
}
