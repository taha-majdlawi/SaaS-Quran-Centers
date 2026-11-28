'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { logAudit } from '@/lib/audit/log';
import { inviteMember } from '@/lib/accounts/invite';
import { staffStrings } from '@/lib/i18n/server';
import { nationalIdField } from '@/lib/auth/national-id';

export async function createInvitation(formData: FormData) {
  const supabase = await createClient();
  const email = ((formData.get('email') as string) ?? '').trim().toLowerCase();
  // name and national ID are optional; accepting the invitation writes them to the account (0099)
  const nationalId = nationalIdField(formData.get('nationalId'));
  if (nationalId === undefined) {
    redirect(`/members?error=${encodeURIComponent((await staffStrings()).students.nationalIdInvalid)}` as never);
  }
  // the link is emailed when the platform can send email; else the admin copies it from the list
  const { sent, error } = await inviteMember(supabase, {
    orgId: formData.get('orgId') as string,
    email,
    role: formData.get('role') as string,
    fullName: ((formData.get('fullName') as string) ?? '').trim() || null,
    nationalId,
  });
  if (error) {
    const message = /رقم الهوية مستخدم/.test(error) ? (await staffStrings()).students.nationalIdTaken : error;
    redirect(`/members?error=${encodeURIComponent(message)}` as never);
  }
  redirect(`/members?invited=${encodeURIComponent(email)}&sent=${sent ? 1 : 0}` as never);
}

/** Withdraws an invitation that was not accepted yet - its link stops working (0099). */
export async function cancelInvitation(formData: FormData) {
  const supabase = await createClient();
  const { error } = await supabase.rpc('cancel_invitation', {
    p_org: formData.get('orgId') as string,
    p_invitation: formData.get('invitationId') as string,
  });
  if (error) redirect(`/members?error=${encodeURIComponent(error.message)}` as never);
  redirect('/members');
}

export async function updateMember(formData: FormData) {
  const id = formData.get('id') as string;
  const orgId = formData.get('orgId') as string;
  const role = formData.get('role') as string;
  const status = formData.get('status') as string;
  const back = (message: string) => `/members/${id}?error=${encodeURIComponent(message)}` as never;

  const supabase = await createClient();
  const S = await staffStrings();

  // the official name and the national ID (both checked by the database: admins of this center only)
  if (formData.has('fullName')) {
    const fullName = ((formData.get('fullName') as string) ?? '').trim();
    const initial = ((formData.get('initialName') as string) ?? '').trim();
    if (fullName !== initial) {
      const { error: nameError } = await supabase.rpc('set_member_name', { p_org: orgId, p_member: id, p_name: fullName });
      if (nameError) redirect(back(/مشترك/.test(nameError.message) ? S.members.nameShared : nameError.message));
    }
  }
  if (formData.has('nationalId')) {
    const nationalId = nationalIdField(formData.get('nationalId'));
    if (nationalId === undefined) redirect(back(S.students.nationalIdInvalid));
    const { error: idError } = await supabase.rpc('set_member_national_id', { p_org: orgId, p_member: id, p_national_id: nationalId ?? '' });
    if (idError) redirect(back(idError.code === '23505' ? S.students.nationalIdTaken : idError.message));
  }

  const { error } = await supabase.from('organization_members').update({ role, status }).eq('id', id);

  if (error) {
    redirect(back(error.message));
  }

  redirect('/members');
}

export async function removeMember(formData: FormData) {
  const id = formData.get('id') as string;

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  const { data: member } = await supabase
    .from('organization_members')
    .select('organization_id')
    .eq('id', id)
    .maybeSingle();

  const { error } = await supabase.from('organization_members').delete().eq('id', id);

  if (error) {
    redirect(`/members/${id}?error=${encodeURIComponent(error.message)}` as never);
  }

  if (member && user) {
    await logAudit(supabase, {
      organizationId: member.organization_id,
      actorId: user.id,
      action: 'delete',
      entityTable: 'organization_members',
      entityId: id,
    });
  }

  redirect('/members');
}
