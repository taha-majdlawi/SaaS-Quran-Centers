// npm test --workspace apps/web - where a sign-in leads (lib/auth/next.ts).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { destinationFor, homeFor, loginWithNext, safeNext } from './next';

test('a page on this site is followed back', () => {
  assert.equal(safeNext('/students'), '/students');
  assert.equal(safeNext('/students/5?tab=points'), '/students/5?tab=points');
});

test('another site never is', () => {
  for (const v of ['//evil.com', '/\\evil.com', 'https://evil.com', 'evil.com', '', null, undefined, 5, '/a\nb', '/' + 'x'.repeat(600)]) {
    assert.equal(safeNext(v), null, String(v));
  }
});

test('nor the sign-in pages themselves', () => {
  for (const v of ['/login', '/login?error=x', '/mfa']) assert.equal(safeNext(v), null, v);
  assert.equal(safeNext('/loginx'), '/loginx');
});

test("each role's own first page", () => {
  assert.equal(homeFor('student'), '/my');
  assert.equal(homeFor('guardian'), '/my');
  assert.equal(homeFor('teacher'), '/dashboard');
  assert.equal(homeFor('admin'), '/dashboard');
});

test('the sign-in address keeps the page', () => {
  assert.equal(loginWithNext('/students?x=1'), '/login?next=%2Fstudents%3Fx%3D1');
  assert.equal(loginWithNext('/'), '/login');
  assert.equal(loginWithNext('//evil.com'), '/login');
  assert.equal(loginWithNext(null), '/login');
});

test('a student is sent back only within the portal', () => {
  assert.equal(destinationFor('student', '/settings'), '/my');
  assert.equal(destinationFor('student', '/my/quran'), '/my/quran');
  assert.equal(destinationFor('guardian', null), '/my');
  assert.equal(destinationFor('teacher', '/students'), '/students');
  assert.equal(destinationFor('admin', null), '/dashboard');
});
