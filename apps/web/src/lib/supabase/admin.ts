import { createClient } from '@supabase/supabase-js';

/**
 * Privileged client for operations an admin does ON BEHALF OF someone else
 * (creating a teacher's login directly, no invite link) - a regular
 * signUp() would hijack the CALLER's own session instead of creating an
 * independent account. Server-only: SUPABASE_SERVICE_ROLE_KEY must never
 * reach the browser bundle, and bypasses RLS entirely, so every caller of
 * this must do its own is_org_admin-style authorization check first.
 */
export function createAdminClient() {
  return createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}
