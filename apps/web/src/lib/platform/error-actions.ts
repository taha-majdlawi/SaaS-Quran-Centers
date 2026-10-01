'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export async function resolveError(formData: FormData) {
  const fp = String(formData.get('fingerprint') ?? '');
  const resolved = formData.get('resolved') !== '0';
  const supabase = await createClient();
  await supabase.rpc('platform_resolve_error', { p_fingerprint: fp, p_resolved: resolved });
  redirect(`/errors?fp=${fp}` as never);
}
