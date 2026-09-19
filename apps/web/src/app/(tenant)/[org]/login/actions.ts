'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { toLoginEmail } from '@/lib/accounts/login-id';

export async function signInToTenant(formData: FormData) {
  const orgSlug = formData.get('orgSlug') as string;
  const identifier = (formData.get('identifier') as string) ?? '';
  const password = formData.get('password') as string;

  const supabase = await createClient();

  const { data: org } = await supabase.from('organizations').select('id').eq('slug', orgSlug).maybeSingle();

  if (!org) {
    redirect(`/login?error=${encodeURIComponent('المركز غير موجود')}`);
  }

  const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
    email: toLoginEmail(orgSlug, identifier),
    password,
  });

  if (signInError || !signInData.user) {
    redirect(`/login?error=${encodeURIComponent('البريد الإلكتروني أو كلمة السر غير صحيحة')}`);
  }

  const { data: membership } = await supabase
    .from('organization_members')
    .select('id')
    .eq('organization_id', org.id)
    .eq('user_id', signInData.user.id)
    .eq('status', 'active')
    .maybeSingle();

  if (!membership) {
    await supabase.auth.signOut();
    redirect(`/login?error=${encodeURIComponent('حسابك غير مرتبط بهذا المركز')}`);
  }

  redirect('/dashboard');
}
