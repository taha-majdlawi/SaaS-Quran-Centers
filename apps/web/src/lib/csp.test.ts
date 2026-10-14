// npm test --workspace apps/web - the pages' Content-Security-Policy.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { contentSecurityPolicy, newNonce } from './csp';

const parse = (csp: string) => Object.fromEntries(csp.split('; ').map((d) => { const [k, ...v] = d.split(' '); return [k, v]; }));

test('scripts run only with the nonce, never inline or eval in production', () => {
  const d = parse(contentSecurityPolicy('abc', 'https://x.supabase.co', 'bustan-alquran.com'));
  assert.deepEqual(d['script-src'], ["'self'", "'nonce-abc'", "'strict-dynamic'"]);
  assert.deepEqual(d['object-src'], ["'none'"]);
  assert.deepEqual(d['frame-ancestors'], ["'none'"]);
  assert.deepEqual(d['base-uri'], ["'self'"]);
  assert.ok(!contentSecurityPolicy('abc', 'https://x.supabase.co', 'bustan-alquran.com').includes('unsafe-eval'));
});

test('Supabase over https and wss, forms only to the product', () => {
  const d = parse(contentSecurityPolicy('n', 'https://x.supabase.co', 'bustan-alquran.com'));
  assert.deepEqual(d['connect-src'], ["'self'", 'https://x.supabase.co', 'wss://x.supabase.co', 'https://accounts.google.com/gsi/']);
  // Google sign-in's frames only, nothing else framed
  assert.deepEqual(d['frame-src'], ['https://accounts.google.com/gsi/']);
  assert.deepEqual(d['form-action'], ["'self'", 'https://bustan-alquran.com', 'https://*.bustan-alquran.com']);
  assert.ok('upgrade-insecure-requests' in d);
});

test('local development: http/ws and eval for the dev server', () => {
  const d = parse(contentSecurityPolicy('n', 'http://127.0.0.1:54321', 'localhost:3000', true));
  assert.deepEqual(d['connect-src'], ["'self'", 'http://127.0.0.1:54321', 'ws://127.0.0.1:54321', 'https://accounts.google.com/gsi/']);
  assert.ok(d['script-src'].includes("'unsafe-eval'"));
  // the recordings come from Storage, over http locally
  assert.ok(d['media-src'].includes('http://127.0.0.1:54321') && d['img-src'].includes('http://127.0.0.1:54321'));
  assert.deepEqual(d['form-action'], ["'self'", 'http://localhost:3000', 'http://*.localhost:3000']);
  assert.ok(!('upgrade-insecure-requests' in d));
  // a local production build: http, but no eval
  assert.ok(!parse(contentSecurityPolicy('n', 'http://127.0.0.1:54321', 'localhost:8787'))['script-src'].includes("'unsafe-eval'"));
});

test('a bad Supabase URL leaves only the app itself', () => {
  assert.deepEqual(parse(contentSecurityPolicy('n', '', 'a.com'))['connect-src'], ["'self'", 'https://accounts.google.com/gsi/']);
});

test('every nonce is new and 128 bits', () => {
  const a = newNonce();
  assert.notEqual(a, newNonce());
  assert.equal(Buffer.from(a, 'base64').length, 16);
});
