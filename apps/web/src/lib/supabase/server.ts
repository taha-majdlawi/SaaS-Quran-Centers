import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import { authCookieDomain } from './cookie-options';

/** Server Component / Route Handler client - reads the caller's auth cookie so RLS sees the real user. */
export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => cookieStore.getAll(),
        setAll: (cookiesToSet) => {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, { ...options, domain: authCookieDomain() }),
            );
          } catch {
            // Called from a Server Component with no response to write to -
            // safe to ignore as long as middleware also refreshes the session.
          }
        },
      },
    },
  );
}
