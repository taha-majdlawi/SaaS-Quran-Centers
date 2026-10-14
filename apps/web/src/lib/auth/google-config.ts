/**
 * The Google OAuth client (Google Cloud -> Google Auth Platform -> Clients -> "Bustan web") used
 * by Google's own sign-in button on bustan-alquran.com/google. A client id is public by design
 * (Google's button puts it in every page that shows it); the secret stays in Supabase only.
 * Empty: the buttons fall back to Supabase's redirect flow (Google then names the Supabase host).
 */
export const GOOGLE_CLIENT_ID = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID || '';
