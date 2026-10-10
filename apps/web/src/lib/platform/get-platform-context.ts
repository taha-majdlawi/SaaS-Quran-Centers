import { createClient } from '@/lib/supabase/server';
import { ownerMfaState, type MfaState } from './mfa';

export interface PlatformContext {
  /** In platform_owners (the password is enough to know this). */
  isOwner: boolean;
  /** Where the owner stands with the second factor (lib/platform/mfa.ts). */
  mfa: MfaState;
  email: string | null;
}

/** Every page under app/(platform)/platform/(protected)/* should call this
 * first - RLS still enforces the real boundary, this drives the UI/redirect. */
export async function getPlatformContext(): Promise<PlatformContext> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return { isOwner: false, mfa: 'enroll', email: null };

  const { data: owner } = await supabase
    .from('platform_owners')
    .select('user_id')
    .eq('user_id', user.id)
    .maybeSingle();

  const mfa = owner ? await ownerMfaState(supabase, user) : 'enroll';
  return { isOwner: Boolean(owner), mfa, email: user.email ?? null };
}
