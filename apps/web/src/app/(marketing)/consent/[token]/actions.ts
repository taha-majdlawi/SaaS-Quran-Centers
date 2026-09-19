'use server';

import { redirect } from 'next/navigation';
import { createAdminClient } from '@/lib/supabase/admin';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Public answer to a consent link. The token is the only credential. */
export async function answerConsent(formData: FormData) {
  const token = (formData.get('token') as string) ?? '';
  const decision = formData.get('decision') as string;
  if (!UUID.test(token) || !['approved', 'declined'].includes(decision)) redirect('/' as never);

  await createAdminClient().rpc('consent_answer', { p_token: token, p_decision: decision });
  redirect(`/consent/${token}?done=1` as never);
}
