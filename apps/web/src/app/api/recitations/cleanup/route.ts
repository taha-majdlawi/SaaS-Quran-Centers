import { createAdminClient } from '@/lib/supabase/admin';

/**
 * Deletes the files whose time is up, after the days each center's admin
 * chose: the recordings of reviewed recitations (0090) and the pictures sent
 * in conversations (0091). The database's daily job calls this (pg_net) with
 * the push shared secret: a file in Storage can only be deleted through the
 * Storage API. The recitations keep their result and mistakes, the messages
 * their text.
 */

const safeEqual = (a: string, b: string) => {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
};

const BATCH = 100;
const MAX_ROUNDS = 10; // up to 1000 files of each kind a day; the rest the next day

// what is due in one bucket, deleted batch by batch, then reported back
const KINDS = [
  { bucket: 'recitations', due: '_recitation_audio_due', done: '_recitation_audio_deleted', path: 'audio_path' },
  { bucket: 'chat-images', due: '_chat_images_due', done: '_chat_images_deleted', path: 'image_path' },
] as const;

export async function POST(req: Request) {
  const secret = process.env.PUSH_SHARED_SECRET;
  if (!secret || !safeEqual(req.headers.get('x-push-secret') ?? '', secret)) return new Response('unauthorized', { status: 401 });

  const admin = createAdminClient();
  const deleted: Record<string, number> = {};
  for (const k of KINDS) {
    deleted[k.bucket] = 0;
    for (let round = 0; round < MAX_ROUNDS; round++) {
      const { data: due, error } = await admin.rpc(k.due, { p_limit: BATCH });
      if (error) return Response.json({ deleted, error: error.message }, { status: 500 });
      const rows = (due ?? []) as Record<string, string>[];
      if (!rows.length) break;
      // a file already missing is simply not in the answer: the row is marked all the same
      const { error: rmError } = await admin.storage.from(k.bucket).remove(rows.map((r) => r[k.path]));
      if (rmError) return Response.json({ deleted, error: rmError.message }, { status: 502 });
      const { data: n } = await admin.rpc(k.done, { p_ids: rows.map((r) => r.id) });
      deleted[k.bucket] += (n as number | null) ?? 0;
      if (rows.length < BATCH) break;
    }
  }
  return Response.json({ deleted });
}
