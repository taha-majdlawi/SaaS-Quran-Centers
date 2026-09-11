'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

const RESERVED_SLUGS = new Set(['www', 'admin', 'api', 'app', 'platform']);
const SLUG_PATTERN = /^[a-z0-9]+(-[a-z0-9]+)*$/;

export async function signUpAndCreateOrganization(formData: FormData) {
  const orgName = (formData.get('orgName') as string)?.trim();
  const slug = (formData.get('slug') as string)?.trim().toLowerCase();
  const email = formData.get('email') as string;
  const password = formData.get('password') as string;

  if (!orgName || !slug || !email || !password) {
    redirect(`/signup?error=${encodeURIComponent('كل الحقول مطلوبة')}`);
  }
  if (!SLUG_PATTERN.test(slug) || RESERVED_SLUGS.has(slug)) {
    redirect(
      `/signup?error=${encodeURIComponent('الرابط غير صالح - حروف إنجليزية صغيرة وأرقام وشرطات فقط، بدون كلمات محجوزة')}`,
    );
  }

  const supabase = await createClient();

  const { data: signUpData, error: signUpError } = await supabase.auth.signUp({ email, password });

  if (signUpError) {
    redirect(`/signup?error=${encodeURIComponent(signUpError.message)}`);
  }

  if (!signUpData.session) {
    // "Confirm email" is on for this project - org creation resumes after
    // the visitor confirms and logs in (not wired yet in this skeleton).
    redirect(
      `/signup?error=${encodeURIComponent('تحقق من بريدك لتأكيد الحساب أولًا - راجعنا بعد التأكيد لإكمال إنشاء المركز')}`,
    );
  }

  const { error: orgError } = await supabase.rpc('create_organization_with_owner', {
    org_name: orgName,
    org_slug: slug,
  });

  if (orgError) {
    const message = orgError.code === '23505' ? 'هذا الرابط مستخدم من قبل، جرّب رابط آخر' : orgError.message;
    redirect(`/signup?error=${encodeURIComponent(message)}`);
  }

  redirect(`https://${slug}.${process.env.NEXT_PUBLIC_ROOT_DOMAIN}/dashboard`);
}
