import { createAdminClient } from '@/lib/supabase/admin';

/**
 * Deletes the recordings of reviewed recitations whose time is up (the days
 * each center's admin chose - 0090). The database's daily job calls this
 * (pg_net) with the push shared secret: a file in Storage can only be deleted
 * through the Storage API. The recitations keep their result and mistakes.
 */

const safeEqual = (a: string, b: string) => {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
};

const BATCH = 100;
const MAX_ROUNDS = 10; // up to 1000 recordings a day; the rest the next day

export async function POST(req: Request) {
  const secret = process.env.PUSH_SHARED_SECRET;
  if (!secret || !safeEqual(req.headers.get('x-push-secret') ?? '', secret)) return new Response('unauthorized', { status: 401 });

  const admin = createAdminClient();
  let deleted = 0;
  for (let round = 0; round < MAX_ROUNDS; round++) {
    const { data: due, error } = await admin.rpc('_recitation_audio_due', { p_limit: BATCH });
    if (error) return Response.json({ deleted, error: error.message }, { status: 500 });
    const rows = (due ?? []) as { id: string; audio_path: string }[];
    if (!rows.length) break;
    // a file already missing is simply not in the answer: the recitation is marked all the same
    const { error: rmError } = await admin.storage.from('recitations').remove(rows.map((r) => r.audio_path));
    if (rmError) return Response.json({ deleted, error: rmError.message }, { status: 502 });
    const { data: n } = await admin.rpc('_recitation_audio_deleted', { p_ids: rows.map((r) => r.id) });
    deleted += (n as number | null) ?? 0;
    if (rows.length < BATCH) break;
  }
  return Response.json({ deleted });
}
