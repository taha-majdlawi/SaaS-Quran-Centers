import { createClient } from '@supabase/supabase-js';
import { createAdminClient } from '@/lib/supabase/admin';
import { removeIfStranger } from '@/lib/auth/google-finish';

/**
 * The app has just signed in with Google (signInWithIdToken): is this account a teacher or an
 * admin of some center? The app signs out when not (and an account Google just made for a
 * stranger is removed here), the same rule as the web's /google page. Bearer: the new session.
 */
export async function POST(req: Request) {
  const token = (req.headers.get('authorization') ?? '').replace(/^Bearer\s+/i, '');
  if (!token) return Response.json({ ok: false }, { status: 401 });
  const anon = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const {
    data: { user },
  } = await anon.auth.getUser(token);
  if (!user) return Response.json({ ok: false }, { status: 401 });

  const { count } = await createAdminClient()
    .from('organization_members')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', user.id)
    .eq('status', 'active')
    .in('role', ['admin', 'teacher']);
  if (count) return Response.json({ ok: true });
  await removeIfStranger(user);
  return Response.json({ ok: false, email: user.email ?? '' });
}
