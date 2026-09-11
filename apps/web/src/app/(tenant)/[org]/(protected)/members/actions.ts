'use server';

import { revalidatePath } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

export async function createInvitation(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const email = (formData.get('email') as string)?.trim().toLowerCase();
  const role = formData.get('role') as string;

  const supabase = await createClient();
  await supabase.rpc('create_invitation', { org_id: orgId, invite_email: email, invite_role: role });

  revalidatePath('/members');
}
