// npm test --workspace apps/web - the recitation check's word comparison on real mushaf text.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { compareRecitation, plainWord, sameWord } from './recite';
import { parseSurahFile } from './mushaf';

const surah = (n: number) => parseSurahFile(n, JSON.parse(readFileSync(new URL(`../../../public/quran-data/surah_${n}.json`, import.meta.url), 'utf8')));

test('the Uthmani spelling and a plain transcript are the same word', () => {
  assert.equal(plainWord('ٱلرَّحۡمَٰنِ'), 'الرحمن');
  assert.ok(sameWord(plainWord('ٱلصَّلَوٰةَ'), plainWord('الصلاة')));
  assert.ok(sameWord(plainWord('ٱلرَّحۡمَٰنِ'), plainWord('الرحمان')));
  assert.ok(!sameWord(plainWord('ٱلرَّحِيمِ'), plainWord('الكريم')));
});

test('a full, correct recitation of al-Fatiha (with the isti\'adha) scores 100', () => {
  const r = compareRecitation(
    surah(1).ayahs,
    'أعوذ بالله من الشيطان الرجيم بسم الله الرحمن الرحيم الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين إياك نعبد وإياك نستعين اهدنا الصراط المستقيم صراط الذين أنعمت عليهم غير المغضوب عليهم ولا الضالين',
  );
  assert.equal(r.score, 100);
  assert.equal(r.missing + r.wrong, 0);
  assert.equal(r.extra, 5);
});

test('a skipped phrase is reported missing in its own ayah', () => {
  const r = compareRecitation(surah(2).ayahs.slice(0, 5), 'الم ذلك الكتاب لا ريب فيه هدى للمتقين الذين يؤمنون بالغيب ويقيمون الصلاة ومما رزقناهم ينفقون والذين يؤمنون بما أنزل إليك وما أنزل من قبلك أولئك على هدى من ربهم وأولئك هم المفلحون');
  const missing = r.words.filter((w) => w.s === 'missing');
  assert.deepEqual([...new Set(missing.map((w) => w.a))], [4]);
  assert.equal(missing.length, 3);
});

test('a different word is reported wrong with what was heard', () => {
  const r = compareRecitation(surah(1).ayahs.slice(1, 2), 'الحمد لله رب المسلمين');
  const wrong = r.words.filter((w) => w.s === 'wrong');
  assert.equal(wrong.length, 1);
  assert.equal(wrong[0].h, 'المسلمين');
});

test('the transcript splitting يَـٰٓأَيُّهَا into two words still matches', () => {
  const r = compareRecitation(surah(2).ayahs.slice(20, 21), 'يا أيها الناس اعبدوا ربكم الذي خلقكم والذين من قبلكم لعلكم تتقون');
  assert.equal(r.score, 100);
});
