// Source of the text and recitations for the reader. Both are public sources;
// nothing of either is stored in our database:
//   * text  - api.alquran.cloud, Uthmani script from the Tanzil project
//             (tanzil.net, used unmodified with attribution);
//   * audio - everyayah.com, one MP3 per ayah.

export const QURAN_CREDIT = 'نص المصحف: مشروع تنزيل (tanzil.net) · التلاوات: everyayah.com';

export interface Reciter {
  id: string; // folder on the audio host = the id stored in center settings
  name: string;
}

export const RECITERS: Reciter[] = [
  { id: 'Alafasy_128kbps', name: 'مشاري العفاسي' },
  { id: 'Abdul_Basit_Murattal_192kbps', name: 'عبد الباسط عبد الصمد (مرتل)' },
  { id: 'Abdul_Basit_Mujawwad_128kbps', name: 'عبد الباسط عبد الصمد (مجوّد)' },
  { id: 'Husary_128kbps', name: 'محمود خليل الحصري' },
  { id: 'Minshawy_Murattal_128kbps', name: 'محمد صديق المنشاوي (مرتل)' },
  { id: 'Abdurrahmaan_As-Sudais_192kbps', name: 'عبد الرحمن السديس' },
  { id: 'Saood_ash-Shuraym_128kbps', name: 'سعود الشريم' },
  { id: 'MaherAlMuaiqly128kbps', name: 'ماهر المعيقلي' },
  { id: 'Hudhaify_128kbps', name: 'علي الحذيفي' },
  { id: 'Ghamadi_40kbps', name: 'سعد الغامدي' },
  { id: 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net', name: 'أحمد العجمي' },
  { id: 'Muhammad_Ayyoub_128kbps', name: 'محمد أيوب' },
  { id: 'Abu_Bakr_Ash-Shaatree_128kbps', name: 'أبو بكر الشاطري' },
  { id: 'Nasser_Alqatami_128kbps', name: 'ناصر القطامي' },
  { id: 'Yasser_Ad-Dussary_128kbps', name: 'ياسر الدوسري' },
];

/** The reciters a center offers (its `quran_reciters` setting, empty = all), default first. */
export function centerReciters(configured: string, defaultId: string): Reciter[] {
  const allowed = new Set(configured.split(',').map((s) => s.trim()).filter(Boolean));
  let list = RECITERS.filter((r) => allowed.size === 0 || allowed.has(r.id));
  if (!list.length) list = [...RECITERS];
  const i = list.findIndex((r) => r.id === defaultId);
  if (i > 0) list = [list[i], ...list.slice(0, i), ...list.slice(i + 1)];
  return list;
}

export const ayahAudioUrl = (reciterId: string, surah: number, ayah: number) =>
  `https://everyayah.com/data/${reciterId}/${String(surah).padStart(3, '0')}${String(ayah).padStart(3, '0')}.mp3`;

export interface QuranAyah {
  number: number;
  text: string;
  juz: number;
  page: number;
  sajda: boolean;
}

const ARABIC_DIGITS = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
export const arabicNumber = (n: number) => String(n).split('').map((d) => ARABIC_DIGITS[Number(d)]).join('');

/** One surah's text (cached for a week by the platform's fetch cache). */
export async function fetchSurah(surah: number): Promise<QuranAyah[] | null> {
  if (!Number.isInteger(surah) || surah < 1 || surah > 114) return null;
  try {
    const res = await fetch(`https://api.alquran.cloud/v1/surah/${surah}/quran-uthmani`, { next: { revalidate: 604800 } });
    if (!res.ok) return null;
    const json = (await res.json()) as { data?: { ayahs: { text: string; numberInSurah: number; juz: number; page: number; sajda: unknown }[] } };
    return (json.data?.ayahs ?? []).map((a) => {
      let text = a.text.trim();
      // The source glues the basmala onto ayah 1 of every surah except al-Fatiha
      // (where it IS the first ayah) and at-Tawba (which has none): show it apart.
      if (a.numberInSurah === 1 && surah !== 1 && surah !== 9) {
        const words = text.split(' ');
        if (words.length > 4) text = words.slice(4).join(' ');
      }
      return { number: a.numberInSurah, text, juz: a.juz, page: a.page, sajda: !!a.sajda };
    });
  } catch {
    return null;
  }
}
