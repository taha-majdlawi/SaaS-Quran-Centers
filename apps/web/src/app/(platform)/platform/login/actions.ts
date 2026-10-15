'use server';

import { redirect } from '@/lib/platform/redirect';
import { safeNext } from '@/lib/auth/next';
import { createClient } from '@/lib/supabase/server';

export async function signInToPlatform(formData: FormData) {
  const email = formData.get('email') as string;
  const password = formData.get('password') as string;

  const supabase = await createClient();

  const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({ email, password });

  if (signInError || !signInData.user) {
    return redirect(`/login?error=${encodeURIComponent('البريد الإلكتروني أو كلمة السر غير صحيحة')}`);
  }

  const { data: owner } = await supabase
    .from('platform_owners')
    .select('user_id')
    .eq('user_id', signInData.user.id)
    .maybeSingle();

  if (!owner) {
    await supabase.auth.signOut();
    return redirect(`/login?error=${encodeURIComponent('حسابك ليس من مالكي المنصة')}`);
  }

  // a full address on admin.{ROOT_DOMAIN} (lib/platform/redirect.ts); the console's layout asks for the code next
  return redirect(safeNext(formData.get('next')) ?? '/');
}
