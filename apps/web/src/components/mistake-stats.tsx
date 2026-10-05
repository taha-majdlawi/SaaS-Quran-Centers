import { surahLabel } from '@/lib/quran/data';
import { fmt } from '@/lib/i18n/config';
import { MistakeWords } from '@/components/mistake-words';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';

export interface MistakeStatsData {
  days: number;
  sessions: number;
  mistakes: number;
  by_surah: { surah: number; count: number }[];
  by_ayah: { surah: number; ayah: number; count: number }[];
  by_word: { surah: number; ayah: number; word: number; text: string | null; count: number }[];
}

/** Where a student keeps slipping (recitation_mistake_stats, 0086): by surah, ayah and word. `base` is the mushaf path. */
export function MistakeStats({ data, base, locale, M }: { data: MistakeStatsData | null; base: string; locale: string; M: Dictionary['mistakeStats'] }) {
  if (!data || data.sessions === 0) return null;
  const max = Math.max(1, ...data.by_surah.map((s) => s.count));
  return (
    <section className="rounded-lg border bg-white p-4">
      <h2 className="font-bold">{M.title}</h2>
      <p className="mb-3 text-xs text-gray-500">{fmt(M.hint, { days: data.days })} · {fmt(M.summary, { sessions: data.sessions, mistakes: data.mistakes })}</p>
      {data.mistakes === 0 ? (
        <p className="text-sm text-gray-500">{M.none}</p>
      ) : (
        <div className="grid gap-4 md:grid-cols-3">
          <div>
            <h3 className="mb-2 text-sm font-semibold">{M.bySurah}</h3>
            <ul className="space-y-1.5 text-sm">
              {data.by_surah.map((s) => (
                <li key={s.surah}>
                  <div className="flex justify-between">
                    <span>{surahLabel(s.surah, locale)}</span>
                    <span className="text-gray-500">{s.count}</span>
                  </div>
                  <div className="h-1.5 rounded bg-gray-100">
                    <div className="h-1.5 rounded bg-red-400" style={{ width: `${(s.count / max) * 100}%` }} />
                  </div>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h3 className="mb-2 text-sm font-semibold">{M.byAyah}</h3>
            <ul className="space-y-1 text-sm">
              {data.by_ayah.map((a) => (
                <li key={`${a.surah}:${a.ayah}`} className="flex justify-between">
                  <a href={`${base}/${a.surah}?ayah=${a.ayah}` as never} className="text-brand hover:underline">
                    {fmt(M.ayah, { surah: surahLabel(a.surah, locale), ayah: a.ayah })}
                  </a>
                  <span className={a.count > 1 ? 'font-semibold text-red-700' : 'text-gray-500'}>{fmt(M.times, { n: a.count })}</span>
                </li>
              ))}
            </ul>
          </div>
          <div>
            <h3 className="mb-2 text-sm font-semibold">{M.byWord}</h3>
            <MistakeWords items={data.by_word} timesLabel={M.times} />
          </div>
        </div>
      )}
    </section>
  );
}
