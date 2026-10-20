'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { logAudit } from '@/lib/audit/log';
import { inviteMember } from '@/lib/accounts/invite';

export async function createInvitation(formData: FormData) {
  const supabase = await createClient();
  const email = ((formData.get('email') as string) ?? '').trim().toLowerCase();
  // the link is emailed when the platform can send email; else the admin copies it from the list
  const { sent, error } = await inviteMember(supabase, {
    orgId: formData.get('orgId') as string,
    email,
    role: formData.get('role') as string,
  });
  if (error) redirect(`/members?error=${encodeURIComponent(error)}` as never);
  redirect(`/members?invited=${encodeURIComponent(email)}&sent=${sent ? 1 : 0}` as never);
}

export async function updateMember(formData: FormData) {
  const id = formData.get('id') as string;
  const role = formData.get('role') as string;
  const status = formData.get('status') as string;

  const supabase = await createClient();
  const { error } = await supabase.from('organization_members').update({ role, status }).eq('id', id);

  if (error) {
    redirect(`/members/${id}?error=${encodeURIComponent(error.message)}` as never);
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
