// npm test --workspace apps/web - same cases as apps/mobile/test/next_position_test.dart.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { nextPosition } from './next-position';

const p = (surah: number, ayahFrom: number, ayahTo: number) => ({ surah, ayahFrom, ayahTo });

test('nothing yet', () => assert.equal(nextPosition([]), null));
test('stopped in the middle: the same surah, the next ayah', () => {
  const n = nextPosition([p(78, 1, 20)])!;
  assert.equal(n.finishedSurah, false);
  assert.equal(n.surah, 78);
  assert.equal(n.ayahFrom, 21);
});
test('finished a surah, going down from An-Nas: the one before it', () => {
  const n = nextPosition([p(112, 1, 4), p(113, 1, 5)])!;
  assert.equal(n.finishedSurah, true);
  assert.equal(n.surah, 111);
});
test('one surah only: from the end of the mushaf by default', () => assert.equal(nextPosition([p(114, 1, 6)])!.surah, 113));
test('memorising from the start: the one after it', () => assert.equal(nextPosition([p(3, 1, 200), p(2, 1, 286)])!.surah, 4));
test('several recitations of the same surah are one step', () => assert.equal(nextPosition([p(67, 16, 30), p(67, 1, 15), p(68, 1, 52)])!.surah, 66));
test('the whole Quran done', () => assert.equal(nextPosition([p(1, 1, 7), p(2, 1, 286)])!.surah, null));
