// npm test --workspace apps/web - the center link rules and the product's addresses.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { productUrl, validSlug } from './signup';

test('a center link: small latin letters, digits and single dashes, not a reserved word', () => {
  for (const ok of ['alnoor', 'al-noor-2', 'a1']) assert.ok(validSlug(ok), ok);
  for (const bad of ['', 'Al', 'al--noor', '-al', 'al-', 'al_noor', 'admin', 'www', 'evil.com', 'a'.repeat(64)]) assert.ok(!validSlug(bad), bad);
});

test('the product address: https, http only for a local run', () => {
  process.env.NEXT_PUBLIC_ROOT_DOMAIN = 'bustan-alquran.com';
  assert.equal(productUrl('/confirm'), 'https://bustan-alquran.com/confirm');
  assert.equal(productUrl('/dashboard', 'alnoor'), 'https://alnoor.bustan-alquran.com/dashboard');
  process.env.NEXT_PUBLIC_ROOT_DOMAIN = 'localhost:3000';
  assert.equal(productUrl('/dashboard', 'x'), 'http://x.localhost:3000/dashboard');
});
