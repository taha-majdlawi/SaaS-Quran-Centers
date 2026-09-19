import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

/** Only same-site relative paths: a posted `back` must never become an open redirect. */
export function safeBack(value: FormDataEntryValue | null, fallback: string): string {
  const v = typeof value === 'string' ? value : '';
  return v.startsWith('/') && !v.startsWith('//') && !v.includes('\\') ? v : fallback;
}

export function withParam(path: string, key: string, value: string): string {
  const [base, query = ''] = path.split('?');
  const params = new URLSearchParams(query);
  params.set(key, value);
  return `${base}?${params.toString()}`;
}

/** Runs one RPC and comes back to `back` with ?ok=<code> or ?error=<message>. */
export async function runRpc(
  fn: string,
  args: Record<string, unknown>,
  back: string,
  okCode: string,
): Promise<never> {
  const supabase = await createClient();
  const { error } = await supabase.rpc(fn, args);
  if (error) redirect(withParam(back, 'error', error.message) as never);
  redirect(withParam(back, 'ok', okCode) as never);
}
