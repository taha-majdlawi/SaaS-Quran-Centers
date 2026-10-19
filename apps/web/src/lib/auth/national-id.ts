import type { SupabaseClient } from '@supabase/supabase-js';
import { createAdminClient } from '@/lib/supabase/admin';

/**
 * A national ID as stored (0095): Latin letters and digits, upper case, 4-20 long. Arabic-Indic
 * and Persian digits become 0-9, spaces and dashes go; anything else makes it not an ID (null).
 */
export function normalizeNationalId(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const v = value
    .replace(/[٠-٩]/g, (d) => String(d.charCodeAt(0) - 0x0660))
    .replace(/[۰-۹]/g, (d) => String(d.charCodeAt(0) - 0x06f0))
    .replace(/[\s\-_.]/g, '')
    .toUpperCase();
  return /^[A-Z0-9]{4,20}$/.test(v) ? v : null;
}

/** For a form: '' (cleared), a valid ID, or undefined when what was typed is not one. */
export function nationalIdField(value: unknown): string | null | undefined {
  if (typeof value !== 'string' || !value.trim()) return null;
  return normalizeNationalId(value) ?? undefined;
}

/**
 * The sign-in emails of the accounts whose national ID in this center is `id`: a student's (through
 * their record's member) and a staff member's (on the membership). Read with the service key -
 * visitors cannot read either table - and never shown to anyone: the caller only signs in with them.
 */
async function emailsFor(slug: string, id: string): Promise<string[]> {
  const admin = createAdminClient();
  const { data: org } = await admin.from('organizations').select('id').eq('slug', slug.toLowerCase()).maybeSingle();
  if (!org) return [];
  const [{ data: students }, { data: staff }] = await Promise.all([
    admin.from('students_profile').select('member:organization_members!students_profile_member_id_fkey(user_id, status)').eq('organization_id', org.id).eq('national_id', id),
    admin.from('organization_members').select('user_id, status').eq('organization_id', org.id).eq('national_id', id),
  ]);
  const ids = new Set<string>();
  for (const s of (students ?? []) as unknown as { member: { user_id: string; status: string } | null }[]) {
    if (s.member?.user_id && s.member.status === 'active') ids.add(s.member.user_id);
  }
  for (const m of (staff ?? []) as { user_id: string; status: string }[]) if (m.status === 'active') ids.add(m.user_id);
  const emails: string[] = [];
  for (const uid of [...ids].slice(0, 3)) {
    const { data } = await admin.auth.admin.getUserById(uid);
    if (data.user?.email) emails.push(data.user.email);
  }
  return emails;
}

/**
 * Sign in to a center with a national ID and the account's own password (the same password as
 * with the number / email). Returns whether it worked; a wrong ID and a wrong password look the same.
 */
export async function signInWithNationalId(supabase: SupabaseClient, slug: string, identifier: string, password: string) {
  const id = normalizeNationalId(identifier);
  if (!id || !password) return null;
  for (const email of await emailsFor(slug, id)) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (!error && data.user && data.session) return data;
  }
  return null;
}
