'use server';

import { cookies } from 'next/headers';
import { createClient } from '@/lib/supabase/server';
import { PENDING_ORG_COOKIE } from '@/lib/auth/signup';
import { finishGoogleSignIn, finishGoogleSignUp, readPendingOrg, type GoogleResult } from '@/lib/auth/google-finish';
import { getI18n } from '@/lib/i18n/server';

/**
 * Google's button on /google has signed the browser in (signInWithIdToken): now the same checks
 * as the redirect flow - a teacher or admin of the center, or the new center to create.
 */
export async function completeGoogle(input: { center?: string; invite?: string; signup?: boolean }): Promise<GoogleResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: (await getI18n()).t.login.errorGoogle };
  if (input.signup) {
    const jar = await cookies();
    const pending = readPendingOrg(jar.get(PENDING_ORG_COOKIE)?.value);
    jar.delete(PENDING_ORG_COOKIE);
    return finishGoogleSignUp(supabase, pending);
  }
  return finishGoogleSignIn(supabase, user, (input.center ?? '').toLowerCase(), input.invite ?? null);
}
