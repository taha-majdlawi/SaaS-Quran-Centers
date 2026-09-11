import { createClient } from '@/lib/supabase/server';

export interface PlatformContext {
  isOwner: boolean;
  email: string | null;
}

/** Every page under app/(platform)/platform/(protected)/* should call this
 * first - RLS still enforces the real boundary, this drives the UI/redirect. */
export async function getPlatformContext(): Promise<PlatformContext> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return { isOwner: false, email: null };

  const { data: owner } = await supabase
    .from('platform_owners')
    .select('user_id')
    .eq('user_id', user.id)
    .maybeSingle();

  return { isOwner: Boolean(owner), email: user.email ?? null };
}
