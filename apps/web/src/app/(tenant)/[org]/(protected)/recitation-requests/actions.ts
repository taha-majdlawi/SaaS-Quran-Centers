'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export async function rejectRecitationRequest(formData: FormData) {
  const id = formData.get('id') as string;

  const supabase = await createClient();
  await supabase.from('serd_sessions').update({ status: 'cancelled' }).eq('id', id);

  redirect('/recitation-requests');
}
