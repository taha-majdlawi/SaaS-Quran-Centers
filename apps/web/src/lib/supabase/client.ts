import { createBrowserClient } from '@supabase/ssr';

/**
 * Browser-side client, anon key only - identical trust model to the legacy
 * static site (wep-eqraa-center): authorization is enforced by Postgres RLS,
 * never by anything in this file. See supabase/migrations/0001_core_tenancy.sql.
 */
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
