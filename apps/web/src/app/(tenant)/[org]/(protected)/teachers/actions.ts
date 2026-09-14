'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';
import { logAudit } from '@/lib/audit/log';

/**
 * Full account edit (name, email, password, role, status) - not just the
 * organization_members row members/[id] covers, so this needs the Admin
 * API (service_role) the same way members/new-teacher does: changing
 * someone ELSE's email/password can't go through a plain client call.
 */
export async function updateTeacherAccount(formData: FormData) {
  const memberId = formData.get('memberId') as string;
  const userId = formData.get('userId') as string;
  const orgId = formData.get('orgId') as string;
  const fullName = (formData.get('fullName') as string)?.trim();
  const email = (formData.get('email') as string)?.trim().toLowerCase();
  const password = (formData.get('password') as string)?.trim();
  const role = formData.get('role') as string;
  const status = formData.get('status') as string;

  const supabase = await createClient();
  const {
    data: { user: caller },
  } = await supabase.auth.getUser();

  const { data: callerMembership } = await supabase
    .from('organization_members')
    .select('role')
    .eq('organization_id', orgId)
    .eq('user_id', caller?.id ?? '')
    .eq('status', 'active')
    .maybeSingle();

  if (callerMembership?.role !== 'admin') {
    redirect(`/teachers/${memberId}?error=${encodeURIComponent('غير مصرح لك بهذا الإجراء')}` as never);
  }

  const admin = createAdminClient();

  const authUpdate: { email?: string; password?: string } = {};
  if (email) authUpdate.email = email;
  if (password) authUpdate.password = password;

  if (Object.keys(authUpdate).length > 0) {
    const { error: authError } = await admin.auth.admin.updateUserById(userId, authUpdate);
    if (authError) {
      redirect(`/teachers/${memberId}?error=${encodeURIComponent(authError.message)}` as never);
    }
  }

  await admin.from('profiles').update({ full_name: fullName }).eq('id', userId);

  const { error: memberError } = await admin
    .from('organization_members')
    .update({ role, status })
    .eq('id', memberId);

  if (memberError) {
    redirect(`/teachers/${memberId}?error=${encodeURIComponent(memberError.message)}` as never);
  }

  if (caller) {
    await logAudit(supabase, {
      organizationId: orgId,
      actorId: caller.id,
      action: 'update',
      entityTable: 'organization_members',
      entityId: memberId,
    });
  }

  redirect('/teachers');
}
