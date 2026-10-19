import { createClient } from '@supabase/supabase-js';
import { signInWithNationalId } from '@/lib/auth/national-id';
import { validSlug } from '@/lib/auth/signup';

/**
 * The app signs in with a national ID (0095): only the server may look up which account an ID
 * belongs to, so it signs in here with the password and hands the app the session (the app then
 * holds it as if it had signed in itself). A wrong ID and a wrong password get the same answer.
 * Body: { center, identifier, password }.
 */
export async function POST(req: Request) {
  let body: { center?: unknown; identifier?: unknown; password?: unknown };
  try {
    body = await req.json();
  } catch {
    return Response.json({ ok: false }, { status: 400 });
  }
  const center = String(body.center ?? '').trim().toLowerCase();
  const identifier = String(body.identifier ?? '');
  const password = String(body.password ?? '');
  if (!validSlug(center) || !identifier || !password || password.length > 200) return Response.json({ ok: false }, { status: 400 });

  const anon = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const data = await signInWithNationalId(anon, center, identifier, password);
  if (!data?.session) return Response.json({ ok: false }, { status: 401 });
  return Response.json({ ok: true, refresh_token: data.session.refresh_token, access_token: data.session.access_token });
}
