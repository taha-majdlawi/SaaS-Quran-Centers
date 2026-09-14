'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { logAudit } from '@/lib/audit/log';

export async function createInvitation(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const email = (formData.get('email') as string)?.trim().toLowerCase();
  const role = formData.get('role') as string;

  const supabase = await createClient();
  await supabase.rpc('create_invitation', { org_id: orgId, invite_email: email, invite_role: role });

  redirect('/members');
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
