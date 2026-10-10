'use server';

import { redirect } from '@/lib/platform/redirect';
import { createClient } from '@/lib/supabase/server';

export async function resolveError(formData: FormData) {
  const fp = String(formData.get('fingerprint') ?? '');
  const resolved = formData.get('resolved') !== '0';
  const supabase = await createClient();
  await supabase.rpc('platform_resolve_error', { p_fingerprint: fp, p_resolved: resolved });
  return redirect(`/errors?fp=${fp}` as never);
}

/**
 * A test report, to check the whole chain end to end: it goes in through the
 * same door as every crash (report_client_error), shows in this list, and
 * sends the new-bug alert to the owner's phone. Mark it «fixed» afterwards.
 */
export async function sendTestError() {
  const supabase = await createClient();
  const { error } = await supabase.rpc('report_client_error', {
    p_source: 'server',
    p_message: `اختبار المراقبة — أُرسل من صفحة الأخطاء ${new Date().toISOString().slice(0, 16).replace('T', ' ')}`,
    p_screen: '/errors',
    p_extra: { kind: 'test' },
  });
  return redirect(`/errors?status=open${error ? `&test_error=${encodeURIComponent(error.message)}` : '&tested=1'}` as never);
}
