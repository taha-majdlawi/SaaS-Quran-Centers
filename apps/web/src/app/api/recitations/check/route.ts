import { NextResponse } from 'next/server';
import { getCloudflareContext } from '@opennextjs/cloudflare';
import { createClient as createSupabase } from '@supabase/supabase-js';
import { createAdminClient } from '@/lib/supabase/admin';
import { createClient } from '@/lib/supabase/server';
import { parseAlquranCloud, parseSurahFile, QURAN_DATA, type SurahDetail } from '@/lib/quran/mushaf';
import { compareRecitation } from '@/lib/quran/recite';

// The site's check of a recorded recitation, for the web reader and the app
// (which sends its access token): transcribe the recording (Workers AI,
// Whisper) and compare it word by word with the ayahs. The result is saved on
// the submission; the teacher still listens and decides.
//
// Only someone who may see the submission (RLS: the family, or its teacher
// once sent) can ask, and each recording is checked once.

const MODEL = '@cf/openai/whisper-large-v3-turbo';
const MAX_BYTES = 12 * 1024 * 1024; // ~6 minutes of 16 kHz WAV

interface AiBinding {
  run(model: string, input: Record<string, unknown>): Promise<{ text?: string }>;
}
interface Env {
  AI?: AiBinding;
  ASSETS?: { fetch(req: Request | string): Promise<Response> };
}

async function surahText(surah: number, origin: string, env: Env): Promise<SurahDetail | null> {
  const path = `${QURAN_DATA}/surah_${surah}.json`;
  try {
    const res = env.ASSETS ? await env.ASSETS.fetch(new Request(new URL(path, origin))) : await fetch(new URL(path, origin));
    if (res.ok) return parseSurahFile(surah, await res.json());
  } catch {
    // fall through to the public text
  }
  try {
    const res = await fetch(`https://api.alquran.cloud/v1/surah/${surah}/quran-uthmani`);
    return res.ok ? parseAlquranCloud(surah, await res.json()) : null;
  } catch {
    return null;
  }
}

// native (nodejs_compat): a byte-by-byte loop costs real CPU time on a ~10 MB recording
const toBase64 = (buf: ArrayBuffer) => Buffer.from(buf).toString('base64');

export async function POST(request: Request) {
  let id: unknown;
  try {
    ({ id } = await request.json());
  } catch {
    return NextResponse.json({ error: 'طلب غير صالح' }, { status: 400 });
  }
  if (typeof id !== 'string' || !/^[0-9a-f-]{36}$/i.test(id)) return NextResponse.json({ error: 'طلب غير صالح' }, { status: 400 });

  // the caller's own client: the app sends its token, the site its cookie
  const token = request.headers.get('authorization')?.replace(/^Bearer\s+/i, '');
  const supabase = token
    ? createSupabase(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, {
        auth: { autoRefreshToken: false, persistSession: false },
        global: { headers: { Authorization: `Bearer ${token}` } },
      })
    : await createClient();
  const { data: row } = await supabase
    .from('recitation_submissions')
    .select('id, surah, ayah_from, ayah_to, audio_path, status, auto_result')
    .eq('id', id)
    .maybeSingle();
  if (!row) return NextResponse.json({ error: 'غير مصرّح' }, { status: 403 });
  if (row.auto_result) return NextResponse.json({ result: row.auto_result });
  if (!row.audio_path || (row.status !== 'draft' && row.status !== 'submitted')) {
    return NextResponse.json({ error: 'لا يوجد تسجيل' }, { status: 400 });
  }

  const admin = createAdminClient();
  const save = async (result: Record<string, unknown>, transcript: string | null, score: number | null) => {
    await admin
      .from('recitation_submissions')
      .update({ auto_result: result, transcript, auto_score: score, checked_at: new Date().toISOString() })
      .eq('id', id);
  };

  let env: Env = {};
  try {
    env = (await getCloudflareContext({ async: true })).env as Env;
  } catch {
    // local `next dev` without the Cloudflare bindings
  }
  if (!env.AI) {
    // the recording still goes to the teacher, just without the check
    return NextResponse.json({ result: { unavailable: true } });
  }

  const { data: file } = await admin.storage.from('recitations').download(row.audio_path);
  if (!file) return NextResponse.json({ error: 'لم يُعثر على التسجيل' }, { status: 404 });
  if (file.size > MAX_BYTES) {
    const result = { unavailable: true, reason: 'too_long' };
    await save(result, null, null);
    return NextResponse.json({ result });
  }

  const detail = await surahText(row.surah, new URL(request.url).origin, env);
  const ayahs = detail?.ayahs.filter((a) => a.number >= row.ayah_from && a.number <= row.ayah_to) ?? [];
  if (!ayahs.length) return NextResponse.json({ result: { unavailable: true } });

  let transcript = '';
  try {
    const out = await env.AI.run(MODEL, { audio: toBase64(await file.arrayBuffer()), language: 'ar', task: 'transcribe', vad_filter: true });
    transcript = (out.text ?? '').trim();
  } catch {
    // not saved: the student can try the check again
    return NextResponse.json({ result: { unavailable: true } });
  }

  const result = compareRecitation(ayahs, transcript);
  await save({ ...result }, transcript, result.score);
  return NextResponse.json({ result, transcript });
}
