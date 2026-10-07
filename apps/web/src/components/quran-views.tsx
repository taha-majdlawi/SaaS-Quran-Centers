import { notFound } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { QuranFont } from '@/components/quran-font';
import { QuranReader } from '@/components/quran-reader';
import { AYAH_COUNTS, SURAH_NAMES, SURAH_NAMES_LATIN, surahLabel } from '@/lib/quran/data';
import { arabicNumber } from '@/lib/quran/reader';
import { AYAH_RECITERS, centerAyahReciters, normalizeArabic } from '@/lib/quran/mushaf';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

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
  const { t, locale } = await getI18n();
  const Q = t.quran;
  const query = (q ?? '').trim();
  const lower = query.toLowerCase();
  // hamza forms folded: "الاعراف" finds "الأعراف"
  const folded = normalizeArabic(query);
  const surahs = SURAH_NAMES.map((name, i) => ({ n: i + 1, name, latin: SURAH_NAMES_LATIN[i] })).filter(
    (s) => !query || normalizeArabic(s.name).includes(folded) || s.latin.toLowerCase().includes(lower) || String(s.n) === query,
  );

  return (
    <QuranFont>
      <div className="max-w-2xl">
        <h1 className="mb-4 text-2xl font-bold">{Q.title}</h1>

        {state?.position && !query && (
          <a href={`${base}/${state.position.surah}?ayah=${state.position.ayah}` as never} className="mb-4 block rounded-lg bg-brand p-4 text-white">
            <p className="font-bold">{Q.continue}</p>
            <p className="text-sm opacity-90">{fmt(Q.position, { surah: surahLabel(state.position.surah, locale), ayah: state.position.ayah })}</p>
          </a>
        )}

        {!!state?.bookmarks.length && !query && (
          <div className="mb-6">
            <h2 className="mb-2 font-semibold">{Q.bookmarks}</h2>
            <div className="flex flex-wrap gap-2 text-sm">
              {state.bookmarks.map((b) => (
                <a key={b.id} href={`${base}/${b.surah}?ayah=${b.ayah}` as never} className="rounded-full border bg-white px-3 py-1">
                  🔖 {surahLabel(b.surah, locale)} : {b.ayah}
                </a>
              ))}
            </div>
          </div>
        )}

        <form className="mb-4">
          <input name="q" defaultValue={query} placeholder={Q.search} className="w-full rounded border px-3 py-2 text-sm" />
        </form>

        <div className="overflow-hidden rounded-lg border bg-white">
          {surahs.map((s) => (
            <a key={s.n} href={`${base}/${s.n}` as never} className="flex items-center justify-between border-b px-4 py-3 last:border-0 hover:bg-gray-50">
              <span className="flex items-center gap-3">
                <span className="flex h-8 w-8 items-center justify-center rounded-full bg-gray-100 text-xs">{locale === 'ar' ? arabicNumber(s.n) : s.n}</span>
                <span className="font-quran text-xl" lang="ar">
                  سورة {s.name}
                </span>
                {locale !== 'ar' && <span className="text-sm text-gray-500">{s.latin}</span>}
              </span>
              <span className="text-xs text-gray-500">{fmt(Q.ayahs, { n: AYAH_COUNTS[s.n - 1] })}</span>
            </a>
          ))}
        </div>
        <p className="mt-4 text-center text-xs text-gray-400">{Q.credit}</p>
      </div>
    </QuranFont>
  );
}

export async function QuranReaderView({
  orgId,
  base,
  surah,
  ayah,
  reciteTo,
  reciteType,
  recitations = true,
}: {
  orgId: string;
  base: string;
  surah: number;
  ayah?: number;
  /** from the daily portion: open the recite panel on ayah..reciteTo */
  reciteTo?: number;
  reciteType?: string;
  /** the center uses recitations (0088): the recite / test button */
  recitations?: boolean;
}) {
  if (!Number.isInteger(surah) || surah < 1 || surah > 114) notFound();
  const [state, { t, locale }] = await Promise.all([readingState(orgId), getI18n()]);
  const Q = t.quran;
  const reciters = centerAyahReciters(AYAH_RECITERS, state?.reciters ?? '', state?.default_reciter ?? '');
  const bookmarked = (state?.bookmarks ?? []).filter((b) => b.surah === surah).map((b) => b.ayah);

  return (
    <QuranFont>
      <div>
        <div className="mx-auto mb-3 flex max-w-[720px] items-center justify-between text-sm">
          <a href={base as never} className="text-brand hover:underline">
            {Q.back}
          </a>
          <div className="flex gap-3">
            {surah > 1 && (
              <a href={`${base}/${surah - 1}` as never} className="text-brand hover:underline">
                {Q.prevSurah}
              </a>
            )}
            {surah < 114 && (
              <a href={`${base}/${surah + 1}` as never} className="text-brand hover:underline">
                {Q.nextSurah}
              </a>
            )}
          </div>
        </div>
        {locale !== 'ar' && <p className="mb-2 text-center text-sm text-gray-500">{SURAH_NAMES_LATIN[surah - 1]}</p>}

        <QuranReader
          key={surah}
          orgId={orgId}
          surah={surah}
          surahName={SURAH_NAMES[surah - 1]}
          reciters={reciters}
          bookmarked={bookmarked}
          startAyah={ayah}
          autoRecite={ayah && reciteTo && reciteType ? { from: ayah, to: reciteTo, type: reciteType } : undefined}
          role={base === '/quran' ? 'staff' : 'family'}
          canRecite={recitations}
          typeLabels={t.labels.recitationType}
          labels={Q.ui}
          recite={Q.recite}
        />
        <p className="mt-6 text-center text-xs text-gray-400">{Q.credit}</p>
      </div>
    </QuranFont>
  );
}
