// npm test --workspace apps/web - national ID numbers as stored (0095).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { nationalIdField, normalizeNationalId } from './national-id';

test('digits in any script, spaces and dashes', () => {
  assert.equal(normalizeNationalId('123456789'), '123456789');
  assert.equal(normalizeNationalId('١٢٣٤٥٦٧٨٩'), '123456789');
  assert.equal(normalizeNationalId('۱۲۳ ۴۵۶-۷۸۹'), '123456789');
  assert.equal(normalizeNationalId(' ab-12 34 '), 'AB1234');
});

test('not an ID', () => {
  for (const v of ['', '12', 'x'.repeat(21), 'abc@d.com', '12;drop', 'رقم1234', null, 5]) assert.equal(normalizeNationalId(v), null, String(v));
});

test('a form field: empty clears it, junk is refused', () => {
  assert.equal(nationalIdField(''), null);
  assert.equal(nationalIdField('  '), null);
  assert.equal(nationalIdField('٤٠٠١٢٣٤٥٦'), '400123456');
  assert.equal(nationalIdField('12'), undefined);
});
