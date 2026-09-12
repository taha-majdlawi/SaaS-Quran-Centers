'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';

/**
 * Creates a real, ready-to-use login for a teacher directly - no invite
 * link to send. Needs the Supabase Admin API (service_role) because a
 * plain signUp() here would replace the ADMIN's own session with the new
 * teacher's, instead of creating an independent account for someone else.
 */
export async function createTeacherDirectly(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const fullName = (formData.get('fullName') as string)?.trim();
  const email = (formData.get('email') as string)?.trim().toLowerCase();
  const password = formData.get('password') as string;

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect('/login' as never);

  const { data: caller } = await supabase
    .from('organization_members')
    .select('role')
    .eq('organization_id', orgId)
    .eq('user_id', user.id)
    .eq('status', 'active')
    .maybeSingle();

  if (caller?.role !== 'admin') {
    redirect(`/members/new-teacher?error=${encodeURIComponent('غير مصرح لك بهذا الإجراء')}` as never);
  }

  const admin = createAdminClient();

  const { data: created, error: createError } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: fullName },
  });

  if (createError || !created.user) {
    redirect(
      `/members/new-teacher?error=${encodeURIComponent(createError?.message ?? 'فشل إنشاء الحساب')}` as never,
    );
  }

  const { error: memberError } = await admin.from('organization_members').insert({
    organization_id: orgId,
    user_id: created.user.id,
    role: 'teacher',
    status: 'active',
    invited_by: user.id,
  });

  if (memberError) {
    redirect(`/members/new-teacher?error=${encodeURIComponent(memberError.message)}` as never);
  }

  redirect(
    `/members?createdEmail=${encodeURIComponent(email)}&createdPassword=${encodeURIComponent(password)}` as never,
  );
}
