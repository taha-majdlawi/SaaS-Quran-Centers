'use client';

import { useEffect, useState } from 'react';
import { QURAN_DATA, parseSurahFile, wordRanges } from '@/lib/quran/mushaf';
import { arabicNumber } from '@/lib/quran/reader';

type Item = { a: number; i: number; s?: string; h?: string };

/** The words a check or a test flagged, written out (the result only stores their places). */
export function RecitationWords({ surah, items, missingLabel, wrongLabel }: { surah: number; items: Item[]; missingLabel: string; wrongLabel: string }) {
  const [text, setText] = useState<Map<number, string> | null>(null);
  useEffect(() => {
    let alive = true;
    fetch(`${QURAN_DATA}/surah_${surah}.json`)
      .then((r) => (r.ok ? r.json() : null))
      .then((raw) => alive && raw && setText(new Map(parseSurahFile(surah, raw).ayahs.map((a) => [a.number, a.text]))))
      .catch(() => {});
    return () => {
      alive = false;
    };
  }, [surah]);

  const word = (it: Item) => {
    const t = text?.get(it.a);
    const r = t ? wordRanges(t)[it.i] : null;
    return r ? t!.slice(r[0], r[1]) : '…';
  };
  const missing = items.filter((w) => w.s !== 'wrong');
  const wrong = items.filter((w) => w.s === 'wrong');

  const row = (label: string, list: Item[], cls: string) =>
    list.length > 0 && (
      <p className="text-sm">
        <span className="text-gray-500">{label} </span>
        {list.map((w, k) => (
          <span key={k} className={`me-2 inline-block font-quran text-lg ${cls}`} lang="ar">
            {word(w)}
            <sup className="text-[0.6em] text-gray-400">{arabicNumber(w.a)}</sup>
            {w.h && <span className="font-sans text-xs text-gray-500"> ({w.h})</span>}
          </span>
        ))}
      </p>
    );

  return (
    <div className="space-y-1">
      {row(missingLabel, missing, 'text-red-700')}
      {row(wrongLabel, wrong, 'text-orange-700')}
    </div>
  );
}
