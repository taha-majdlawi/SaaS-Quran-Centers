// npm test --workspace apps/web - the sign-in address behind a number (mobile mirrors it).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { hasRealEmail, legacyLoginEmail, toLoginEmail } from './login-id';

test('a number in any digits is the same account', () => {
  assert.equal(toLoginEmail('noor', '123'), '123@noor.id.bustan-alquran.com');
  assert.equal(toLoginEmail('Noor ', ' ١٢٣ '), '123@noor.id.bustan-alquran.com');
  assert.equal(toLoginEmail('noor', '۱۲۳'), '123@noor.id.bustan-alquran.com');
});

test('an email is used as typed, in lower case', () => {
  assert.equal(toLoginEmail('noor', ' Teacher@Mail.COM '), 'teacher@mail.com');
});

test('the old address only when Arabic digits were typed', () => {
  assert.equal(legacyLoginEmail('noor', '123'), null);
  assert.equal(legacyLoginEmail('noor', 'a@b.co'), null);
  assert.equal(legacyLoginEmail('noor', '١٢٣'), '١٢٣@noor.id.bustan-alquran.com');
});

test('made-up addresses are not real ones', () => {
  assert.equal(hasRealEmail('123@noor.id.bustan-alquran.com'), false);
  assert.equal(hasRealEmail('teacher@mail.com'), true);
  assert.equal(hasRealEmail(null), false);
});
