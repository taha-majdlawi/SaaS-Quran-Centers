'use client';

import { useEffect, useMemo, useRef, useState } from 'react';
import { ayahAudioUrl, arabicNumber, type QuranAyah, type Reciter } from '@/lib/quran/reader';
import { savePosition, toggleBookmark } from '@/lib/quran/actions';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';

/**
 * The reading view of one surah: tap an ayah to play from it, bookmark it, or
 * copy it. Playback runs ayah by ayah (optionally repeating each one, which is
 * how memorization is drilled), highlights and scrolls to the ayah being recited,
 * and the reading position is saved as you go.
 */
export function QuranReader({
  orgId,
  surah,
  ayahs,
  reciters,
  bookmarked: initialBookmarks,
  startAyah,
  labels: L,
}: {
  orgId: string;
  surah: number;
  ayahs: QuranAyah[];
  reciters: Reciter[];
  bookmarked: number[];
  startAyah?: number;
  /** t.quran.ui */
  labels: Dictionary['quran']['ui'];
}) {
  const audio = useRef<HTMLAudioElement | null>(null);
  const [reciterId, setReciterId] = useState(reciters[0]?.id ?? '');
  const [current, setCurrent] = useState<number | null>(startAyah ?? null);
  const [playing, setPlaying] = useState(false);
  const [repeat, setRepeat] = useState(1);
  const [scale, setScale] = useState(1);
  const [marks, setMarks] = useState<Set<number>>(new Set(initialBookmarks));
  const [menu, setMenu] = useState<number | null>(null);
  const [error, setError] = useState('');
  const done = useRef(0);
  const last = useRef<number | null>(null);

  // remembered choices (per browser)
  useEffect(() => {
    try {
      const r = localStorage.getItem('quran_reciter');
      if (r && reciters.some((x) => x.id === r)) setReciterId(r);
      const s = Number(localStorage.getItem('quran_scale'));
      if (s >= 0.8 && s <= 1.8) setScale(s);
    } catch {}
  }, [reciters]);

  useEffect(() => {
    if (startAyah) document.getElementById(`ayah-${startAyah}`)?.scrollIntoView({ block: 'center' });
  }, [startAyah]);

  // save where the reader stopped when leaving
  useEffect(() => {
    const save = () => {
      if (last.current) void savePosition(orgId, surah, last.current);
    };
    window.addEventListener('pagehide', save);
    return () => {
      window.removeEventListener('pagehide', save);
      save();
      audio.current?.pause();
    };
  }, [orgId, surah]);

  const play = (n: number) => {
    const el = audio.current;
    if (!el) return;
    setError('');
    done.current = 0;
    last.current = n;
    setCurrent(n);
    el.src = ayahAudioUrl(reciterId, surah, n);
    el.play().then(() => setPlaying(true)).catch(() => setError(L.playFailed));
    document.getElementById(`ayah-${n}`)?.scrollIntoView({ behavior: 'smooth', block: 'center' });
  };

  const onEnded = () => {
    if (current == null) return;
    done.current += 1;
    if (done.current < repeat) {
      audio.current!.currentTime = 0;
      void audio.current!.play();
    } else if (current < ayahs.length) {
      play(current + 1);
    } else {
      setPlaying(false);
    }
  };

  const toggle = () => {
    const el = audio.current;
    if (!el) return;
    if (playing) {
      el.pause();
      setPlaying(false);
    } else if (el.src && current != null && !el.ended) {
      void el.play();
      setPlaying(true);
    } else {
      play(current ?? 1);
    }
  };

  const mark = async (n: number) => {
    const now = await toggleBookmark(orgId, surah, n);
    if (now === null) return;
    setMarks((m) => {
      const next = new Set(m);
      if (now) next.add(n);
      else next.delete(n);
      return next;
    });
  };

  const size = useMemo(() => `${1.6 * scale}rem`, [scale]);

  return (
    <div>
      <audio ref={audio} onEnded={onEnded} onPause={() => setPlaying(false)} onPlay={() => setPlaying(true)} preload="none" />

      <div className="sticky top-0 z-10 mb-4 flex flex-wrap items-center gap-3 rounded-lg border bg-white p-3 text-sm shadow-sm">
        <button onClick={toggle} className="rounded bg-brand px-4 py-1.5 font-semibold text-white">
          {playing ? L.pause : L.play}
        </button>
        <button onClick={() => current && current > 1 && play(current - 1)} className="rounded border px-2 py-1" aria-label={L.prevAyah}>
          ⏮
        </button>
        <button onClick={() => (current ?? 0) < ayahs.length && play((current ?? 0) + 1)} className="rounded border px-2 py-1" aria-label={L.nextAyah}>
          ⏭
        </button>
        <select
          value={reciterId}
          onChange={(e) => {
            setReciterId(e.target.value);
            try {
              localStorage.setItem('quran_reciter', e.target.value);
            } catch {}
          }}
          className="rounded border px-2 py-1"
        >
          {reciters.map((r) => (
            <option key={r.id} value={r.id}>
              {r.name}
            </option>
          ))}
        </select>
        <label className="flex items-center gap-1">
          {L.repeat}
          <select value={repeat} onChange={(e) => setRepeat(Number(e.target.value))} className="rounded border px-1 py-1">
            {[1, 2, 3, 5, 10].map((n) => (
              <option key={n} value={n}>
                ×{n}
              </option>
            ))}
          </select>
        </label>
        <span className="ms-auto flex items-center gap-1">
          {(['−', '+'] as const).map((sign) => (
            <button
              key={sign}
              className="rounded border px-2 py-0.5"
              onClick={() => {
                const next = Math.min(1.8, Math.max(0.8, scale + (sign === '+' ? 0.1 : -0.1)));
                setScale(next);
                try {
                  localStorage.setItem('quran_scale', String(next));
                } catch {}
              }}
            >
              {sign === '+' ? L.bigger : L.smaller}
            </button>
          ))}
        </span>
      </div>
      {error && <p className="mb-3 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      {surah !== 1 && surah !== 9 && (
        <p className="mb-4 text-center font-quran" style={{ fontSize: `${1.8 * scale}rem` }}>
          بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ
        </p>
      )}

      <div className="font-quran leading-[2.2] text-justify" dir="rtl">
        {ayahs.map((a) => (
          <span
            key={a.number}
            id={`ayah-${a.number}`}
            onClick={() => setMenu(menu === a.number ? null : a.number)}
            className={`cursor-pointer rounded px-1 ${current === a.number ? (playing ? 'bg-amber-200' : 'bg-amber-100') : ''}`}
            style={{ fontSize: size }}
          >
            {a.text} <span className="text-brand" style={{ fontSize: `${1.2 * scale}rem` }}>﴿{arabicNumber(a.number)}﴾</span>
            {a.sajda && ' ۩'}
            {marks.has(a.number) && ' 🔖'}{' '}
            {menu === a.number && (
              <span className="mx-1 inline-flex gap-1 align-middle font-sans text-xs" onClick={(e) => e.stopPropagation()}>
                <button className="rounded border bg-white px-2 py-0.5" onClick={() => { setMenu(null); play(a.number); }}>
                  {L.fromHere}
                </button>
                <button className="rounded border bg-white px-2 py-0.5" onClick={() => { setMenu(null); void mark(a.number); }}>
                  {marks.has(a.number) ? L.unmark : L.mark}
                </button>
                <button
                  className="rounded border bg-white px-2 py-0.5"
                  onClick={() => {
                    setMenu(null);
                    void navigator.clipboard?.writeText(`${a.text} ﴿${arabicNumber(a.number)}﴾`);
                  }}
                >
                  {L.copy}
                </button>
              </span>
            )}
          </span>
        ))}
      </div>
    </div>
  );
}
