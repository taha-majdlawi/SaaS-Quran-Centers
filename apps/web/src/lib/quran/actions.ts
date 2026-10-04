'use server';

import { createClient } from '@/lib/supabase/server';
import { parseAlquranCloud, type SurahDetail } from '@/lib/quran/mushaf';

// Called from the reader (client component); the RPCs check membership and
// validate the ayah, and every result is scoped to the signed-in person.

export async function savePosition(orgId: string, surah: number, ayah: number) {
  const supabase = await createClient();
  await supabase.rpc('save_reading_position', { p_org: orgId, p_surah: surah, p_ayah: ayah });
}

/** Returns whether the bookmark exists after the call. */
export async function toggleBookmark(orgId: string, surah: number, ayah: number): Promise<boolean | null> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('toggle_bookmark', { p_org: orgId, p_surah: surah, p_ayah: ayah, p_note: null });
  return error ? null : (data as boolean);
}

/**
 * The surah from api.alquran.cloud (Tanzil text), for as long as our own files
 * (/quran-data) are not uploaded yet. Cached by the platform for a week.
 */
export async function fallbackSurah(surah: number): Promise<SurahDetail | null> {
  if (!Number.isInteger(surah) || surah < 1 || surah > 114) return null;
  try {
    const res = await fetch(`https://api.alquran.cloud/v1/surah/${surah}/quran-uthmani`, { next: { revalidate: 604800 } });
    return res.ok ? parseAlquranCloud(surah, await res.json()) : null;
  } catch {
    return null;
  }
}
