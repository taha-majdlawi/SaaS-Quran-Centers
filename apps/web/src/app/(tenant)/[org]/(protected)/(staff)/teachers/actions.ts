'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';
import { logAudit } from '@/lib/audit/log';
import { ALL_MODULE_KEYS } from '@/lib/permissions/modules';

/**
 * Full account edit (name, email, password, role, status) - not just the
 * organization_members row members/[id] covers, so this needs the Admin
 * API (service_role) the same way members/new-teacher does: changing
 * someone ELSE's email/password can't go through a plain client call.
 */
export async function updateTeacherAccount(formData: FormData) {
  const memberId = formData.get('memberId') as string;
  const orgId = formData.get('orgId') as string;
  const fullName = (formData.get('fullName') as string)?.trim();
  const email = (formData.get('email') as string)?.trim().toLowerCase();
  const password = (formData.get('password') as string)?.trim();
  const role = formData.get('role') as string;
  const status = formData.get('status') as string;
  const permissions = ALL_MODULE_KEYS.filter((key) => formData.get(`perm_${key}`) === 'on');

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

  // Never trust a client-submitted userId, and never trust memberId's org
  // without checking it server-side: this form only proved the caller is
  // admin of `orgId`, and everything below runs through the service-role
  // client, which bypasses RLS entirely - so re-deriving user_id here,
  // through the RLS-protected user-scoped client, is what stops a caller
  // from pointing memberId at a member of a DIFFERENT organization and
  // having the admin client act on them anyway. This select returns no row
  // unless the target member's organization_id is one the caller can
  // actually see under organization_members' own RLS policy, which is a
  // second, independent check beyond the explicit org.id comparison below.
  const { data: targetMember } = await supabase
    .from('organization_members')
    .select('user_id, organization_id')
    .eq('id', memberId)
    .maybeSingle();

  if (!targetMember || targetMember.organization_id !== orgId) {
    redirect(`/teachers?error=${encodeURIComponent('عضو غير موجود بهذا المركز')}` as never);
  }

  const userId = targetMember.user_id;

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
    .update({ role, status, permissions })
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
