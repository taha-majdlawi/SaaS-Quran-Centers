'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

/** Shared by both tenant and platform layouts - host-relative, so middleware.ts
 * re-adds whichever prefix (`/{slug}` or `/platform`) matches the hostname. */
export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect('/login');
}
