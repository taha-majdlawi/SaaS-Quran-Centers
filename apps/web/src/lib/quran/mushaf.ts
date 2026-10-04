// The mushaf data, shared by the reader (client) and the pages (server).
//
// The files are served by this site from /quran-data (apps/web/public/quran-data,
// filled by the "Quran data" workflow - see docs/QURAN.md):
//   surah_<n>.json                         text, juz, Madinah page, sajda, whole-surah recitations
//   audio/reciters.json                    reciters recorded ayah by ayah (url = base + SSSAAA.mp3)
//   audio/timings/<reciter>/surah_<n>.json word timings, relative to each ayah's own file
// Until they are there the reader still works: the text comes from api.alquran.cloud
// (Tanzil) and the reciters from the built-in list below - only word sync waits.

import uploadedReciters from './ayah-reciters.json';

export const QURAN_DATA = '/quran-data';

export interface Ayah {
  number: number;
  text: string;
  juz: number;
  /** Page of the Madinah mushaf (1-604). */
  page: number;
  sajda: boolean;
  sajdaObligatory: boolean;
}

export interface SurahAudio {
  reciter: string;
  rewaya: string;
  link: string;
}

export interface SurahDetail {
  number: number;
  ayahs: Ayah[];
  /** مكية / مدنية when the file says so. */
  place: string | null;
  /** One MP3 for the whole surah, per reciter (empty with the fallback text). */
  audio: SurahAudio[];
}

/** A reciter with one file per ayah. */
export interface AyahReciter {
  id: string;
  name: string;
  style: string;
  base: string;
}

export interface MushafPage {
  page: number;
  juz: number;
  ayahs: Ayah[];
}

/** Per ayah: [firstWord, afterLastWord, fromMs, toMs] per spoken word, relative to the ayah's file. */
export type SurahTimings = Record<string, [number, number, number, number][]>;

export type SyncMode = 'none' | 'ayah' | 'word';

const BASMALA_START = /^بِسْمِ\s+[^\s]*ٱللَّهِ\s+[^\s]*ٱلرَّحْمَٰنِ\s+[^\s]*ٱلرَّحِيمِ\s*/;

/** Some sources glue the basmala onto ayah 1 (not al-Fatiha, where it is the ayah, nor at-Tawba): it is shown apart. */
export function stripBasmala(surah: number, n: number, text: string): string {
  if (n !== 1 || surah === 1 || surah === 9) return text;
  if (BASMALA_START.test(text)) return text.replace(BASMALA_START, '');
  const words = text.split(' ');
  // spelling varies between sources; the first word is always "بسم"
  return words[0]?.replace(/[^ء-ي]/g, '') === 'بسم' && words.length > 4 ? words.slice(4).join(' ') : text;
}

interface RawSurahFile {
  revelation_place?: { ar?: string };
  verses?: { number: number; text: { ar: string } | string; juz: number; page: number; sajda?: false | { obligatory?: boolean } }[];
  audio?: { reciter?: { ar?: string } | string; rewaya?: { ar?: string } | string; link?: string }[];
}

const ar = (v: { ar?: string } | string | undefined) => (typeof v === 'string' ? v : (v?.ar ?? ''));

/** Our own file (eqraa format). */
export function parseSurahFile(surah: number, raw: RawSurahFile): SurahDetail {
  const ayahs = (raw.verses ?? []).map((v) => ({
    number: v.number,
    text: stripBasmala(surah, v.number, ar(v.text).trim()),
    juz: v.juz,
    page: v.page,
    sajda: !!v.sajda,
    sajdaObligatory: !!(v.sajda && v.sajda.obligatory),
  }));
  return {
    number: surah,
    ayahs,
    place: raw.revelation_place?.ar ?? null,
    audio: (raw.audio ?? []).filter((a) => !!a.link).map((a) => ({ reciter: ar(a.reciter), rewaya: ar(a.rewaya), link: a.link! })),
  };
}

/** api.alquran.cloud (Tanzil) - used until our files are uploaded. */
export function parseAlquranCloud(surah: number, json: { data?: { revelationType?: string; ayahs: { text: string; numberInSurah: number; juz: number; page: number; sajda: unknown }[] } }): SurahDetail | null {
  const list = json.data?.ayahs;
  if (!list?.length) return null;
  return {
    number: surah,
    ayahs: list.map((a) => ({
      number: a.numberInSurah,
      text: stripBasmala(surah, a.numberInSurah, a.text.trim()),
      juz: a.juz,
      page: a.page,
      sajda: !!a.sajda,
      sajdaObligatory: typeof a.sajda === 'object' && !!(a.sajda as { obligatory?: boolean })?.obligatory,
    })),
    place: json.data?.revelationType === 'Meccan' ? 'مكية' : json.data?.revelationType === 'Medinan' ? 'مدنية' : null,
    audio: [],
  };
}

/** Ayahs grouped by Madinah page: a new page whenever the number changes. */
export function toPages(ayahs: Ayah[]): MushafPage[] {
  const pages: MushafPage[] = [];
  for (const a of ayahs) {
    const last = pages[pages.length - 1];
    if (last && last.page === a.page) last.ayahs.push(a);
    else pages.push({ page: a.page, juz: a.juz, ayahs: [a] });
  }
  return pages;
}

/** Words of an ayah as [start, end) character ranges - the text itself is never rewritten. */
export function wordRanges(text: string): [number, number][] {
  const out: [number, number][] = [];
  for (const m of text.matchAll(/\S+/g)) out.push([m.index!, m.index! + m[0].length]);
  return out;
}

/**
 * The word being recited at `ms` into the ayah's file: the last segment that has
 * started (between words the previous one stays lit), -1 before the first.
 */
export function wordIndexAt(segments: [number, number, number, number][] | undefined, ms: number): number {
  if (!segments?.length) return -1;
  let found = -1;
  for (let i = 0; i < segments.length; i++) {
    if (segments[i][2] <= ms) found = i;
    else break;
  }
  return found;
}

/**
 * Word sync is only trusted when the text and the timings agree on the number
 * of words; otherwise that ayah follows at ayah level instead of lighting the
 * wrong word (a stray space inside a word in the source text, for example).
 */
export function timingsFit(text: string, segments: unknown[] | undefined): boolean {
  return !!segments && segments.length > 0 && segments.length === wordRanges(text).length;
}

export const ayahFileUrl = (r: AyahReciter, surah: number, ayah: number) =>
  `${r.base.endsWith('/') ? r.base : `${r.base}/`}${String(surah).padStart(3, '0')}${String(ayah).padStart(3, '0')}.mp3`;

/** Built in, so ayah sync works before audio/reciters.json is uploaded (everyayah.com, one MP3 per ayah). */
export const BUILTIN_RECITERS: AyahReciter[] = [
  ['Alafasy_128kbps', 'مشاري العفاسي', 'مرتل'],
  ['Abdul_Basit_Murattal_192kbps', 'عبد الباسط عبد الصمد', 'مرتل'],
  ['Abdul_Basit_Mujawwad_128kbps', 'عبد الباسط عبد الصمد', 'مجوّد'],
  ['Husary_128kbps', 'محمود خليل الحصري', 'مرتل'],
  ['Minshawy_Murattal_128kbps', 'محمد صديق المنشاوي', 'مرتل'],
  ['Abdurrahmaan_As-Sudais_192kbps', 'عبد الرحمن السديس', 'مرتل'],
  ['Saood_ash-Shuraym_128kbps', 'سعود الشريم', 'مرتل'],
  ['MaherAlMuaiqly128kbps', 'ماهر المعيقلي', 'مرتل'],
  ['Hudhaify_128kbps', 'علي الحذيفي', 'مرتل'],
  ['Ghamadi_40kbps', 'سعد الغامدي', 'مرتل'],
  ['Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net', 'أحمد العجمي', 'مرتل'],
  ['Muhammad_Ayyoub_128kbps', 'محمد أيوب', 'مرتل'],
  ['Abu_Bakr_Ash-Shaatree_128kbps', 'أبو بكر الشاطري', 'مرتل'],
  ['Nasser_Alqatami_128kbps', 'ناصر القطامي', 'مرتل'],
  ['Yasser_Ad-Dussary_128kbps', 'ياسر الدوسري', 'مرتل'],
].map(([id, name, style]) => ({ id, name, style, base: `https://everyayah.com/data/${id}/` }));

export function parseReciters(raw: unknown): AyahReciter[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((r) => r as { id?: unknown; name_ar?: unknown; style_ar?: unknown; base?: unknown })
    .filter((r) => (typeof r.id === 'string' || typeof r.id === 'number') && typeof r.base === 'string' && /^https:\/\//.test(r.base))
    .map((r) => ({ id: String(r.id), name: String(r.name_ar ?? r.id), style: String(r.style_ar ?? ''), base: String(r.base) }));
}

/** The reciters a center offers (its `quran_reciters` setting, empty = all), its default first. */
export function centerAyahReciters(all: AyahReciter[], configured: string, defaultId: string): AyahReciter[] {
  const allowed = new Set(configured.split(',').map((s) => s.trim()).filter(Boolean));
  let list = all.filter((r) => allowed.size === 0 || allowed.has(r.id));
  if (!list.length) list = [...all];
  const i = list.findIndex((r) => r.id === defaultId);
  if (i > 0) list = [list[i], ...list.slice(0, i), ...list.slice(i + 1)];
  return list;
}

/** Arabic letters with the hamza forms folded, so "الاعراف" finds "الأعراف". */
export function normalizeArabic(s: string): string {
  return s
    .replace(/[ً-ٰٟۖ-ۭ]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ة/g, 'ه')
    .replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي')
    .trim();
}

/**
 * The ayah-by-ayah reciters: the uploaded list (a copy of audio/reciters.json the
 * import workflow writes next to this file) or, before that, the built-in one.
 */
export const AYAH_RECITERS: AyahReciter[] = parseReciters(uploadedReciters).length ? parseReciters(uploadedReciters) : BUILTIN_RECITERS;

export const reciterLabel = (r: AyahReciter) => (r.style ? `${r.name} (${r.style})` : r.name);
