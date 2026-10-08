// The live recitation matcher on real mushaf text.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { LiveMatcher, stableWords } from './live-recite';
import { parseSurahFile } from './mushaf';

const surah = (n: number) => parseSurahFile(n, JSON.parse(readFileSync(new URL(`../../../public/quran-data/surah_${n}.json`, import.meta.url), 'utf8')));
const feedAll = (m: LiveMatcher, text: string) => text.split(' ').map((w) => m.feed(w)).filter(Boolean);

test('a correct recitation uncovers every word, the basmala before it is ignored', () => {
  const m = new LiveMatcher(surah(112).ayahs);
  const events = feedAll(m, 'بسم الله الرحمن الرحيم قل هو الله أحد الله الصمد لم يلد ولم يولد ولم يكن له كفوا أحد');
  assert.equal(m.mistakes, 0);
  assert.ok(m.done);
  assert.equal(events.at(-1)?.kind, 'done');
  assert.equal(m.result().score, 100);
});

test('a skipped word stops the student as missing', () => {
  const m = new LiveMatcher(surah(112).ayahs);
  const events = feedAll(m, 'قل هو الله أحد الله لم');
  const mistake = events.find((e) => e?.kind === 'mistake');
  assert.deepEqual(mistake, { kind: 'mistake', type: 'missing', at: [5], heard: undefined });
  assert.equal(m.words[5].state, 'missing');
  assert.equal(m.words[6].state, 'ok');
});

test('a different word is wrong, with what was heard', () => {
  const m = new LiveMatcher(surah(112).ayahs);
  const events = feedAll(m, 'قل هو الله الكريم الله');
  const mistake = events.find((e) => e?.kind === 'mistake');
  assert.equal(mistake?.kind === 'mistake' && mistake.type, 'wrong');
  assert.equal(m.words[3].heard, 'الكريم');
  assert.equal(m.words[4].state, 'ok');
});

test('repeating the word just said and a split word are not mistakes', () => {
  const m = new LiveMatcher(surah(2).ayahs.slice(20, 21));
  feedAll(m, 'يا أيها الناس الناس اعبدوا ربكم');
  assert.equal(m.mistakes, 0);
  assert.equal(m.pos, 4);
});

test('forgetting marks the word missing and moves on; finishing early marks the rest', () => {
  const m = new LiveMatcher(surah(112).ayahs);
  feedAll(m, 'قل هو');
  m.forgot();
  assert.equal(m.words[2].state, 'missing');
  m.feed('أحد');
  m.finish();
  const r = m.result();
  assert.equal(r.words.filter((w) => w.s === 'missing').length, r.total - 3);
});

test('only settled words of a recognition session are used', () => {
  assert.deepEqual(stableWords([{ transcript: 'قل هو', final: true }, { transcript: 'الله أح', final: false }]), ['قل', 'هو', 'الله']);
});

test('an unexpected word with nothing after it settles as wrong', () => {
  const m = new LiveMatcher(surah(112).ayahs);
  feedAll(m, 'قل هو الله أحد الله الكريم');
  assert.ok(m.pending);
  const e = m.settle();
  assert.equal(e?.kind === 'mistake' && e.type, 'wrong');
  assert.equal(m.words[5].heard, 'الكريم');
});

test('the cumulative results of Chrome on Android are not counted twice', () => {
  const r = stableWords([
    { transcript: 'قل', final: true },
    { transcript: 'قل هو', final: true },
    { transcript: 'قل هو الله أحد', final: false },
  ]);
  assert.deepEqual(r, ['قل', 'هو', 'الله']);
});

test('al-Fatiha: الرحيم right after الرحمن is not taken for a repeat of it', () => {
  const m = new LiveMatcher(surah(1).ayahs.filter((a) => a.number <= 5));
  feedAll(m, 'بسم الله الرحمن الرحيم الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين إياك نعبد وإياك نستعين');
  assert.equal(m.mistakes, 0);
  assert.ok(m.done);
  // a real repeat is still no mistake
  const r = new LiveMatcher(surah(1).ayahs.filter((a) => a.number <= 3));
  feedAll(r, 'بسم الله الرحمن الرحمن الرحيم الحمد لله رب العالمين الرحمن الرحيم');
  assert.equal(r.mistakes, 0);
});

test('the expected word is recognised early, and the last word of an ayah a little more loosely', () => {
  const m = new LiveMatcher(surah(112).ayahs);
  feedAll(m, 'قل هو الله');
  assert.ok(m.expects('أحد'));
  assert.ok(!m.expects('الصمد'));
  // "احدن" (two letters off the short word) only passes as the ayah's last word, loosely
  assert.ok(!m.expects('احدن'));
  // the ayah's last word, نستعين, heard with its end swallowed at the stop
  const f = new LiveMatcher(surah(1).ayahs.filter((a) => a.number <= 5));
  feedAll(f, 'بسم الله الرحمن الرحيم الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين إياك نعبد وإياك');
  assert.ok(f.expects('تستعي', true));
  assert.ok(!f.expects('تستعي'));
});

test('going back to the start of the ayah after a stop (waqf and ibtida) is no mistake', () => {
  const m = new LiveMatcher(surah(1).ayahs.filter((a) => a.number <= 4));
  feedAll(m, 'بسم الله الرحمن الرحيم الحمد لله');
  // a stop after لله, then the ayah again from its start
  feedAll(m, 'الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين');
  assert.equal(m.mistakes, 0);
  assert.ok(m.done);
  // or from the ayah before
  const b = new LiveMatcher(surah(1).ayahs.filter((a) => a.number <= 3));
  feedAll(b, 'بسم الله الرحمن الرحيم الحمد لله رب العالمين بسم الله الرحمن الرحيم الحمد لله رب العالمين الرحمن الرحيم');
  assert.equal(b.mistakes, 0);
  assert.ok(b.done);
});

test('a word corrected by reading the ayah again is no mistake; after a stop the ayah may be read again', () => {
  const m = new LiveMatcher(surah(112).ayahs);
  // a wrong word, then the ayah from its start, right this time
  feedAll(m, 'قل هو الله الكريم قل هو الله أحد الله الصمد');
  assert.equal(m.mistakes, 0);
  assert.equal(m.pos, 6);
  // stopped on a mistake (أحد marked wrong), then the passage again from the start: no new mistake
  const s = new LiveMatcher(surah(112).ayahs);
  feedAll(s, 'قل هو الله الكريم الله');
  assert.equal(s.mistakes, 1);
  feedAll(s, 'قل هو الله أحد الله الصمد لم يلد');
  assert.equal(s.mistakes, 1);
  assert.equal(s.pos, 8);
});

test('a word that only looks like going back is still judged', () => {
  const m = new LiveMatcher(surah(112).ayahs);
  feedAll(m, 'قل هو الله أحد الله الصمد لم');
  // "الصمد" again, then a word that is neither the re-reading nor the word expected: wrong
  feedAll(m, 'الصمد كفوا');
  assert.equal(m.words[7].state, 'wrong');
  // a stray earlier word followed by the word expected: no mistake
  const n = new LiveMatcher(surah(112).ayahs);
  feedAll(n, 'قل هو الله أحد الله الصمد لم الصمد يلد');
  assert.equal(n.mistakes, 0);
  assert.equal(n.pos, 8);
});
