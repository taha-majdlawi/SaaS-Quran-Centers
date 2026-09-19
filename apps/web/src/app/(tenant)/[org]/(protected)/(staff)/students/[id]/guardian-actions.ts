'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';
import { AccountError, linkGuardian, provisionGuardian } from '@/lib/accounts/provision';

async function callerId() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/login' as never);
  return user.id;
}

/** Creates a guardian login and links it to this student (admin only). */
export async function createGuardianForStudent(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const studentId = formData.get('studentId') as string;
  const identifier = (formData.get('identifier') as string)?.trim();
  const password = formData.get('password') as string;
  const back = `/students/${studentId}`;

  try {
    await provisionGuardian(createAdminClient(), await callerId(), {
      orgId,
      studentId,
      fullName: (formData.get('fullName') as string)?.trim(),
      identifier,
      password,
      phone: (formData.get('phone') as string)?.trim(),
    });
  } catch (e) {
    const message = e instanceof AccountError ? e.message : 'تعذّر إنشاء الحساب';
    redirect(`${back}?error=${encodeURIComponent(message)}` as never);
  }
  redirect(
    `${back}?guardianCreated=${encodeURIComponent(identifier)}&guardianPassword=${encodeURIComponent(password)}` as never,
  );
}

/** Links an existing guardian, or clears the link when guardianMemberId is empty. */
export async function setStudentGuardian(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const studentId = formData.get('studentId') as string;
  const guardianMemberId = ((formData.get('guardianMemberId') as string) ?? '') || null;
  const back = `/students/${studentId}`;

  try {
    await linkGuardian(createAdminClient(), await callerId(), { orgId, studentId, guardianMemberId });
  } catch (e) {
    const message = e instanceof AccountError ? e.message : 'تعذّر تحديث الربط';
    redirect(`${back}?error=${encodeURIComponent(message)}` as never);
  }
  redirect(`${back}?guardianLinked=1` as never);
}
