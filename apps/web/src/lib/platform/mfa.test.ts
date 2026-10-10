// npm test --workspace apps/web - the owner's second factor: who is sent where.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mfaState, tokenAal } from './mfa';

const token = (payload: object) => `h.${Buffer.from(JSON.stringify(payload)).toString('base64url')}.s`;

test('past the second factor: in', () => {
  assert.equal(mfaState('aal2', 1), 'ok');
});

test('a factor but the password only: enter the code', () => {
  assert.equal(mfaState('aal1', 1), 'verify');
  assert.equal(mfaState(null, 2), 'verify');
});

test('no factor yet: set one up', () => {
  assert.equal(mfaState('aal1', 0), 'enroll');
  assert.equal(mfaState(undefined, 0), 'enroll');
});

test('the level comes from the access token', () => {
  assert.equal(tokenAal(token({ sub: 'x', aal: 'aal2' })), 'aal2');
  assert.equal(tokenAal(token({ sub: 'x', aal: 'aal1' })), 'aal1');
  assert.equal(tokenAal(token({ sub: 'x' })), null);
  assert.equal(tokenAal('garbage'), null);
  assert.equal(tokenAal(null), null);
});
