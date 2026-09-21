import { createClient } from '@/lib/supabase/server';

/** Full data export for the center admin (JSON download). The RPC itself checks the caller is this center's admin. */
export async function GET(request: Request) {
  const org = new URL(request.url).searchParams.get('org');
  if (!org) return new Response('bad request', { status: 400 });
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('admin_export_data', { p_org: org });
  if (error) return new Response(error.message, { status: 403 });
  const stamp = new Date().toISOString().slice(0, 10);
  return new Response(JSON.stringify(data, null, 2), {
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Content-Disposition': `attachment; filename="center-backup-${stamp}.json"`,
      'Cache-Control': 'no-store',
    },
  });
}
