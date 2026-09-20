import { notFound } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { QuranFont } from '@/components/quran-font';
import { QuranReader } from '@/components/quran-reader';
import { AYAH_COUNTS, SURAH_NAMES } from '@/lib/quran/data';
import { QURAN_CREDIT, arabicNumber, centerReciters, fetchSurah } from '@/lib/quran/reader';

interface ReadingState {
  position: { surah: number; ayah: number } | null;
  bookmarks: { id: string; surah: number; ayah: number }[];
  reciters: string;
  default_reciter: string;
}

const readingState = async (orgId: string): Promise<ReadingState | null> => {
  const supabase = await createClient();
  const { data } = await supabase.rpc('get_reading_state', { p_org: orgId });
  return (data as ReadingState | null) ?? null;
};

/** The 114 surahs, "continue reading" and the person's bookmarks. `base` is '/quran' or '/my/quran'. */
export async function QuranIndexView({ orgId, base, q }: { orgId: string; base: string; q?: string }) {
  const state = await readingState(orgId);
  const query = (q ?? '').trim();
  const surahs = SURAH_NAMES.map((name, i) => ({ n: i + 1, name })).filter((s) => !query || s.name.includes(query) || String(s.n) === query);

  return (
    <QuranFont>
      <div className="max-w-2xl">
        <h1 className="mb-4 text-2xl font-bold">المصحف</h1>

        {state?.position && !query && (
          <a href={`${base}/${state.position.surah}?ayah=${state.position.ayah}` as never} className="mb-4 block rounded-lg bg-brand p-4 text-white">
            <p className="font-bold">أكمل القراءة</p>
            <p className="text-sm opacity-90">
              سورة {SURAH_NAMES[state.position.surah - 1]} — الآية {state.position.ayah}
            </p>
          </a>
        )}

        {!!state?.bookmarks.length && !query && (
          <div className="mb-6">
            <h2 className="mb-2 font-semibold">علاماتي</h2>
            <div className="flex flex-wrap gap-2 text-sm">
              {state.bookmarks.map((b) => (
                <a key={b.id} href={`${base}/${b.surah}?ayah=${b.ayah}` as never} className="rounded-full border bg-white px-3 py-1">
                  🔖 {SURAH_NAMES[b.surah - 1]} : {b.ayah}
                </a>
              ))}
            </div>
          </div>
        )}

        <form className="mb-4">
          <input name="q" defaultValue={query} placeholder="ابحث باسم السورة أو رقمها" className="w-full rounded border px-3 py-2 text-sm" />
        </form>

        <div className="overflow-hidden rounded-lg border bg-white">
          {surahs.map((s) => (
            <a key={s.n} href={`${base}/${s.n}` as never} className="flex items-center justify-between border-b px-4 py-3 last:border-0 hover:bg-gray-50">
              <span className="flex items-center gap-3">
                <span className="flex h-8 w-8 items-center justify-center rounded-full bg-gray-100 text-xs">{arabicNumber(s.n)}</span>
                <span className="font-quran text-xl">سورة {s.name}</span>
              </span>
              <span className="text-xs text-gray-500">{AYAH_COUNTS[s.n - 1]} آية</span>
            </a>
          ))}
        </div>
        <p className="mt-4 text-center text-xs text-gray-400">{QURAN_CREDIT}</p>
      </div>
    </QuranFont>
  );
}

export async function QuranReaderView({ orgId, base, surah, ayah }: { orgId: string; base: string; surah: number; ayah?: number }) {
  if (!Number.isInteger(surah) || surah < 1 || surah > 114) notFound();
  const [ayahs, state] = await Promise.all([fetchSurah(surah), readingState(orgId)]);

  const reciters = centerReciters(state?.reciters ?? '', state?.default_reciter ?? '');
  const bookmarked = (state?.bookmarks ?? []).filter((b) => b.surah === surah).map((b) => b.ayah);

  return (
    <QuranFont>
      <div className="max-w-3xl">
        <div className="mb-3 flex items-center justify-between text-sm">
          <a href={base as never} className="text-brand hover:underline">
            ← المصحف
          </a>
          <div className="flex gap-3">
            {surah > 1 && (
              <a href={`${base}/${surah - 1}` as never} className="text-brand hover:underline">
                السورة السابقة
              </a>
            )}
            {surah < 114 && (
              <a href={`${base}/${surah + 1}` as never} className="text-brand hover:underline">
                السورة التالية
              </a>
            )}
          </div>
        </div>
        <h1 className="mb-4 text-center font-quran text-3xl">سورة {SURAH_NAMES[surah - 1]}</h1>

        {ayahs ? (
          <QuranReader orgId={orgId} surah={surah} ayahs={ayahs} reciters={reciters} bookmarked={bookmarked} startAyah={ayah} />
        ) : (
          <p className="rounded bg-red-50 px-3 py-4 text-center text-sm text-red-600">تعذّر تحميل نص السورة الآن، حاول لاحقًا.</p>
        )}
        <p className="mt-6 text-center text-xs text-gray-400">{QURAN_CREDIT}</p>
      </div>
    </QuranFont>
  );
}
