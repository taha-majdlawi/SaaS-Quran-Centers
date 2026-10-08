// Following a live recitation word by word: the device's speech recognition
// hands over each word it heard, and the matcher moves along the ayahs.
//
//   * the expected word -> uncovered, next one;
//   * a word a little further on -> the words in between were skipped
//     ("missing"), or said differently when something else was heard first
//     ("wrong");
//   * two unexpected words in a row -> the current word was said wrong;
//   * the student repeating the word just said, the isti'adha / basmala before
//     the first word, a word the recogniser split in two -> no mistake;
//   * a long silence on a word (forgot()) -> "missing".
// Every mistake is returned as an event so the screen can stop the student.
// apps/mobile/lib/features/quran/live_recite.dart is the same logic in Dart.

import { wordRanges, type Ayah } from './mushaf';
import { exactWord, plainWord, sameWord } from './recite';

export type LiveState = 'hidden' | 'ok' | 'missing' | 'wrong';

export interface LiveWord {
  a: number;
  i: number;
  text: string;
  plain: string;
  state: LiveState;
  heard?: string;
}

export type LiveEvent =
  | { kind: 'progress' }
  | { kind: 'done' }
  | { kind: 'mistake'; type: 'missing' | 'wrong'; at: number[]; heard?: string };

const LOOK_AHEAD = 3;

export class LiveMatcher {
  readonly words: LiveWord[] = [];
  pos = 0;
  private unmatched: string[] = [];

  constructor(ayahs: Pick<Ayah, 'number' | 'text'>[]) {
    for (const ayah of ayahs) {
      wordRanges(ayah.text).forEach(([s, e], i) => {
        const text = ayah.text.slice(s, e);
        const plain = plainWord(text);
        if (plain) this.words.push({ a: ayah.number, i, text, plain, state: 'hidden' });
      });
    }
  }

  get done() {
    return this.pos >= this.words.length;
  }

  get mistakes() {
    return this.words.filter((w) => w.state === 'missing' || w.state === 'wrong').length;
  }

  private matches(k: number, w: string) {
    const exp = this.words[k]?.plain;
    if (!exp) return false;
    const last = this.unmatched[this.unmatched.length - 1];
    return sameWord(exp, w) || (!!last && sameWord(exp, last + w));
  }

  private advanceTo(k: number): LiveEvent {
    this.words[k].state = 'ok';
    this.pos = k + 1;
    this.unmatched = [];
    return this.done ? { kind: 'done' } : { kind: 'progress' };
  }

  /** One heard word. Returns what happened (null = nothing to show). */
  feed(raw: string): LiveEvent | null {
    const w = plainWord(raw);
    if (!w || this.done) return null;
    // the word expected, said exactly; else repeating the word just said (often right after
    // being stopped); then the looser match (الرحمن / الرحيم are one letter apart: the loose
    // match alone took one for the other)
    const repeat = this.pos > 0 && this.unmatched.length === 0;
    if (exactWord(this.words[this.pos].plain, w)) return this.advanceTo(this.pos);
    if (repeat && exactWord(this.words[this.pos - 1].plain, w)) return null;
    if (this.matches(this.pos, w)) return this.advanceTo(this.pos);
    if (repeat && sameWord(this.words[this.pos - 1].plain, w)) return null;

    // (not before the first word: the basmala's words appear in the ayahs too)
    for (let k = 1; this.pos > 0 && k <= LOOK_AHEAD && this.pos + k < this.words.length; k++) {
      if (!this.matches(this.pos + k, w)) continue;
      const at = Array.from({ length: k }, (_, j) => this.pos + j);
      const type = this.unmatched.length ? 'wrong' : 'missing';
      const heard = this.unmatched.join(' ') || undefined;
      at.forEach((j, n) => {
        this.words[j].state = type;
        if (n === 0 && heard) this.words[j].heard = heard;
      });
      this.advanceTo(this.pos + k);
      return { kind: 'mistake', type, at, heard };
    }

    // before the first word: the isti'adha, the basmala, a cough...
    if (this.pos === 0) {
      this.unmatched = [w];
      return null;
    }
    this.unmatched.push(w);
    if (this.unmatched.length < 2) return null;
    const at = [this.pos];
    const heard = this.unmatched.join(' ');
    this.words[this.pos].state = 'wrong';
    this.words[this.pos].heard = heard;
    this.pos += 1;
    this.unmatched = [];
    return { kind: 'mistake', type: 'wrong', at, heard };
  }

  /** An unexpected word is waiting and nothing followed it: the current word was said wrong. */
  get pending() {
    return this.pos > 0 && this.unmatched.length > 0;
  }

  settle(): LiveEvent | null {
    if (!this.pending || this.done) return null;
    const heard = this.unmatched.join(' ');
    const at = [this.pos];
    this.words[this.pos].state = 'wrong';
    this.words[this.pos].heard = heard;
    this.pos += 1;
    this.unmatched = [];
    return { kind: 'mistake', type: 'wrong', at, heard };
  }

  /** The student is stuck on the current word (a long silence, or "I don't remember"). */
  forgot(): LiveEvent | null {
    if (this.done) return null;
    const at = [this.pos];
    this.words[this.pos].state = 'missing';
    this.pos += 1;
    this.unmatched = [];
    return { kind: 'mistake', type: 'missing', at };
  }

  /** Ending early: whatever was not reached counts as missing. */
  finish() {
    for (const w of this.words) if (w.state === 'hidden') w.state = 'missing';
    this.pos = this.words.length;
  }

  /** What is sent with the recitation (submit_live_recitation, 0087). */
  result() {
    const words = this.words.map((w) => ({ a: w.a, i: w.i, s: w.state === 'hidden' ? 'missing' : w.state, ...(w.heard ? { h: w.heard } : {}) }));
    const ok = words.filter((w) => w.s === 'ok').length;
    return { words, total: words.length, ok, score: words.length ? Math.round((ok / words.length) * 1000) / 10 : 0 };
  }
}

/**
 * Words of a recognition session that will not change any more: every final
 * result, and the interim one except its last word (still being heard).
 */
export function stableWords(results: { transcript: string; final: boolean }[]): string[] {
  // Chrome on Android repeats the whole phrase in every result of a continuous
  // session ("قل", "قل هو", "قل هو الله"...): a result that starts with the
  // previous one replaces it instead of adding to it
  const phrases: { transcript: string; final: boolean }[] = [];
  for (const r of results) {
    const t = r.transcript.trim();
    const prev = phrases[phrases.length - 1];
    if (prev && prev.transcript && t.startsWith(prev.transcript)) phrases[phrases.length - 1] = { transcript: t, final: r.final };
    else phrases.push({ transcript: t, final: r.final });
  }
  results = phrases;
  const out: string[] = [];
  results.forEach((r, idx) => {
    const ws = r.transcript.split(/\s+/).filter(Boolean);
    out.push(...(r.final || idx < results.length - 1 ? ws : ws.slice(0, -1)));
  });
  return out;
}
