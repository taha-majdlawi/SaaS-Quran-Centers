'use client';

import { useEffect, useState } from 'react';
import { QURAN_DATA, parseSurahFile, wordRanges } from '@/lib/quran/mushaf';
import { arabicNumber } from '@/lib/quran/reader';
import { fmt } from '@/lib/i18n/config';

type Item = { surah: number; ayah: number; word: number; text: string | null; count: number };

/** The most-missed words written out: the stats keep their places, the text comes from the surah files. */
export function MistakeWords({ items, timesLabel }: { items: Item[]; timesLabel: string }) {
  const [texts, setTexts] = useState<Map<string, string>>(new Map());
  useEffect(() => {
    let alive = true;
    const surahs = [...new Set(items.filter((i) => !i.text).map((i) => i.surah))];
    Promise.all(
      surahs.map((n) =>
        fetch(`${QURAN_DATA}/surah_${n}.json`)
          .then((r) => (r.ok ? r.json() : null))
          .then((raw) => (raw ? parseSurahFile(n, raw).ayahs.map((a) => [`${n}:${a.number}`, a.text] as const) : []))
          .catch(() => []),
      ),
    ).then((all) => alive && setTexts(new Map(all.flat())));
    return () => {
      alive = false;
    };
  }, [items]);

  const word = (i: Item) => {
    if (i.text) return i.text;
    const t = texts.get(`${i.surah}:${i.ayah}`);
    const r = t ? wordRanges(t)[i.word] : null;
    return r ? t!.slice(r[0], r[1]) : '…';
  };
  return (
    <ul className="space-y-1">
      {items.map((i) => (
        <li key={`${i.surah}:${i.ayah}:${i.word}`} className="flex items-baseline justify-between gap-2">
          <span className="font-quran text-lg text-red-800" lang="ar">
            {word(i)} <sup className="text-[0.6em] text-gray-400">{arabicNumber(i.ayah)}</sup>
          </span>
          <span className={`text-sm ${i.count > 1 ? 'font-semibold text-red-700' : 'text-gray-500'}`}>{fmt(timesLabel, { n: i.count })}</span>
        </li>
      ))}
    </ul>
  );
}
