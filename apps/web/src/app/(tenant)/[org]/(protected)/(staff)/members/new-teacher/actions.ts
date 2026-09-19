'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';
import { AccountError, provisionTeacher } from '@/lib/accounts/provision';

/**
 * Creates a ready-to-use login for a teacher directly - no invite link.
 * The teacher signs in with an ID number (or a real email) plus the center
 * code. All permission rules live in lib/accounts/provision.ts, shared with
 * the mobile API, so both platforms behave identically.
 */
export async function createTeacherDirectly(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const fullName = (formData.get('fullName') as string)?.trim();
  const identifier = (formData.get('identifier') as string)?.trim();
  const phone = (formData.get('phone') as string)?.trim();
  const password = formData.get('password') as string;

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/login' as never);

  try {
    await provisionTeacher(createAdminClient(), user.id, { orgId, fullName, identifier, password, phone });
  } catch (e) {
    const message = e instanceof AccountError ? e.message : 'تعذّر إنشاء الحساب';
    redirect(`/members/new-teacher?error=${encodeURIComponent(message)}` as never);
  }

  redirect(
    `/members?createdEmail=${encodeURIComponent(identifier)}&createdPassword=${encodeURIComponent(password)}` as never,
  );
}
