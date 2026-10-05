'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { BookOpen, ChevronLeft, ChevronRight, ClipboardCheck, Eye, EyeOff, Mic, Pause, Play, Repeat, SkipBack, SkipForward, X } from 'lucide-react';
import {
  QURAN_DATA,
  ayahFileUrl,
  parseSurahFile,
  reciterLabel,
  timingsFit,
  toPages,
  wordIndexAt,
  wordRanges,
  type Ayah,
  type AyahReciter,
  type SurahDetail,
  type SurahTimings,
  type SyncMode,
} from '@/lib/quran/mushaf';
import { arabicNumber } from '@/lib/quran/reader';
import { fallbackSurah, savePosition, toggleBookmark } from '@/lib/quran/actions';
import { fmt } from '@/lib/i18n/config';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';
import { RangePanel, RecitePanel, TestPanel, usePeople, type ReciteLabels, type WordMark } from '@/components/quran-recite';

const SIZES = [1.55, 1.8, 2.05]; // rem - three sizes, like the app (24 / 28 / 32)
const GOLD = '#A87A12';

function read<T extends string>(key: string, ok: readonly T[], fallback: T): T {
  try {
    const v = localStorage.getItem(key) as T | null;
    return v && ok.includes(v) ? v : fallback;
  } catch {
    return fallback;
  }
}
function store(key: string, value: string) {
  try {
    localStorage.setItem(key, value);
  } catch {}
}

/**
 * The mushaf for one surah: Madinah pages turned like paper, three ways of
 * listening (whole surah / following the ayah / following the word) and a
 * self-test mode that hides the ayahs and uncovers them as you go. Also: repeating
 * a passage, reciting to the system (students and guardians) and testing a
 * student with the result saved to their record (staff).
 */
export function QuranReader({
  orgId,
  surah,
  surahName,
  reciters,
  bookmarked: initialBookmarks,
  startAyah,
  role,
  typeLabels,
  labels: L,
  recite: R,
}: {
  orgId: string;
  surah: number;
  /** Arabic name, for the page header and the banner. */
  surahName: string;
  /** Ayah-by-ayah reciters the center offers, its default first. */
  reciters: AyahReciter[];
  bookmarked: number[];
  startAyah?: number;
  /** staff test students, the family recites */
  role: 'staff' | 'family';
  /** t.labels.recitationType */
  typeLabels: Record<string, string>;
  /** t.quran.ui */
  labels: Dictionary['quran']['ui'];
  /** t.quran.recite */
  recite: ReciteLabels;
}) {
  const [detail, setDetail] = useState<SurahDetail | null>(null);
  const [failed, setFailed] = useState(false);
  const pages = useMemo(() => (detail ? toPages(detail.ayahs) : []), [detail]);
  const [pageIdx, setPageIdx] = useState(0);

  const [size, setSize] = useState(1);
  const [mode, setMode] = useState<SyncMode>('ayah');
  const [reciterId, setReciterId] = useState(reciters[0]?.id ?? '');
  const [surahAudio, setSurahAudio] = useState(0);
  const [repeat, setRepeat] = useState(1);

  const [playing, setPlaying] = useState(false);
  const [current, setCurrent] = useState<number | null>(null);
  const [word, setWord] = useState(-1);
  const [timings, setTimings] = useState<SurahTimings | null>(null);
  const [timingsMissing, setTimingsMissing] = useState(false);

  const [testMode, setTestMode] = useState(false);
  const [revealed, setRevealed] = useState<Set<number>>(new Set());
  const [marks, setMarks] = useState<Set<number>>(new Set(initialBookmarks));
  const [menu, setMenu] = useState<number | null>(null);
  const [error, setError] = useState('');

  // passage repeat, reciting, the teacher's test
  const [panel, setPanel] = useState<'range' | 'recite' | 'test' | null>(null);
  const [range, setRange] = useState<{ from: number; to: number; times: number } | null>(null);
  const [loopNo, setLoopNo] = useState(1);
  const [hideAll, setHideAll] = useState(false);
  const [wordMarks, setWordMarks] = useState<Map<string, WordMark>>(new Map());
  const testing = panel === 'test';
  const { people, grades } = usePeople(orgId, panel === 'recite' || panel === 'test');

  const audio = useRef<HTMLAudioElement | null>(null);
  const warm = useRef<HTMLAudioElement | null>(null);
  const repeatsDone = useRef(0);
  const lastSaved = useRef<number | null>(null);
  const reciter = reciters.find((r) => r.id === reciterId) ?? reciters[0];
  const ayahCount = detail?.ayahs.length ?? 0;

  // --- load the surah: our own file first, the public API until it is uploaded
  useEffect(() => {
    let alive = true;
    (async () => {
      let d: SurahDetail | null = null;
      try {
        const res = await fetch(`${QURAN_DATA}/surah_${surah}.json`);
        if (res.ok) d = parseSurahFile(surah, await res.json());
      } catch {}
      if (!d?.ayahs.length) d = await fallbackSurah(surah).catch(() => null);
      if (!alive) return;
      if (!d?.ayahs.length) return setFailed(true);
      setDetail(d);
      const start = startAyah ? d.ayahs.find((a) => a.number === startAyah) : null;
      if (start) {
        setPageIdx(Math.max(0, toPages(d.ayahs).findIndex((p) => p.page === start.page)));
        setCurrent(start.number);
      }
    })();
    return () => {
      alive = false;
    };
  }, [surah, startAyah]);

  // --- remembered choices (per browser)
  useEffect(() => {
    setSize(Number(read('quran_size', ['0', '1', '2'], '1')));
    setMode(read('quran_sync', ['none', 'ayah', 'word'] as const, 'ayah'));
    const r = read('quran_reciter', reciters.map((x) => x.id), reciters[0]?.id ?? '');
    setReciterId(r);
  }, [reciters]);

  // --- word timings for the chosen reciter (word mode only)
  useEffect(() => {
    setTimings(null);
    setTimingsMissing(false);
    if (mode !== 'word' || !reciter) return;
    let alive = true;
    fetch(`${QURAN_DATA}/audio/timings/${encodeURIComponent(reciter.id)}/surah_${surah}.json`)
      .then((r) => (r.ok ? r.json() : null))
      .catch(() => null)
      .then((t) => {
        if (!alive) return;
        if (t && typeof t === 'object') setTimings(t as SurahTimings);
        else setTimingsMissing(true);
      });
    return () => {
      alive = false;
    };
  }, [mode, reciter, surah]);

  // --- where the reader stopped: the first ayah of the page, saved as pages turn
  const pageFirstAyah = pages[pageIdx]?.ayahs[0]?.number;
  useEffect(() => {
    if (!pageFirstAyah) return;
    const n = current ?? pageFirstAyah;
    const id = setTimeout(() => {
      if (lastSaved.current !== n) {
        lastSaved.current = n;
        void savePosition(orgId, surah, n);
      }
    }, 1500);
    return () => clearTimeout(id);
  }, [pageFirstAyah, current, orgId, surah]);

  useEffect(() => {
    const el = audio.current;
    return () => el?.pause();
  }, []);

  // --- the page follows the recitation
  useEffect(() => {
    if (current == null || !detail) return;
    const a = detail.ayahs.find((x) => x.number === current);
    if (!a) return;
    const i = pages.findIndex((p) => p.page === a.page);
    if (i >= 0) setPageIdx(i);
  }, [current, detail, pages]);

  // --- following the word: compare the position in the ayah's file with its timings
  useEffect(() => {
    if (!playing || mode !== 'word' || current == null || !timings) return;
    let raf = 0;
    const tick = () => {
      const el = audio.current;
      if (el) setWord(wordIndexAt(timings[String(current)], el.currentTime * 1000));
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [playing, mode, current, timings]);

  const ayahText = useCallback((n: number) => detail?.ayahs.find((a) => a.number === n)?.text ?? '', [detail]);
  const fits = (n: number) => mode === 'word' && !!timings && timingsFit(ayahText(n), timings[String(n)]);

  // --- self-test: what the recitation has reached is uncovered
  useEffect(() => {
    if (!testMode || !playing || current == null || mode === 'none') return;
    setRevealed((prev) => {
      const next = new Set(prev);
      for (let i = 1; i < current; i++) next.add(i);
      if (!fits(current)) next.add(current);
      else if (word >= 0 && word >= (timings?.[String(current)]?.length ?? 0) - 1) next.add(current);
      return next.size === prev.size ? prev : next;
    });
  }, [testMode, playing, current, word, mode, timings]);

  // --- playback
  const playAyah = (n: number, el = audio.current) => {
    if (!el || !reciter) return;
    setError('');
    setCurrent(n);
    setWord(-1);
    el.src = ayahFileUrl(reciter, surah, n);
    el.play().catch(() => setError(L.playFailed));
    // fetch the next file while this one plays - the step between ayahs stays short
    if (n < ayahCount) {
      warm.current ??= new Audio();
      warm.current.preload = 'auto';
      warm.current.src = ayahFileUrl(reciter, surah, n + 1);
    }
  };

  const start = (n: number) => {
    repeatsDone.current = 0;
    if (range && (n < range.from || n > range.to)) n = range.from;
    if (range && n === range.from) setLoopNo(1);
    if (mode === 'none') {
      const link = detail?.audio[surahAudio]?.link;
      const el = audio.current;
      if (!link || !el) return setError(L.noSurahAudio);
      if (el.src !== link) el.src = link;
      el.play().catch(() => setError(L.playFailed));
      return;
    }
    playAyah(n);
  };

  const onEnded = () => {
    if (mode === 'none' || current == null) return setPlaying(false);
    repeatsDone.current += 1;
    if (repeatsDone.current < repeat) {
      audio.current!.currentTime = 0;
      void audio.current!.play();
    } else if (range && current === range.to) {
      // the end of the passage: again from its start, `times` times
      repeatsDone.current = 0;
      if (loopNo < range.times) {
        setLoopNo(loopNo + 1);
        playAyah(range.from);
      } else {
        setLoopNo(1);
        setPlaying(false);
        setWord(-1);
      }
    } else if (current < ayahCount) {
      repeatsDone.current = 0;
      playAyah(current + 1);
    } else {
      setPlaying(false);
      setWord(-1);
      if (testMode) setRevealed((p) => new Set([...p, current]));
    }
  };

  const toggle = () => {
    const el = audio.current;
    if (!el) return;
    if (playing) return el.pause();
    if (el.src && !el.ended && (mode === 'none' || current != null)) {
      void el.play().catch(() => setError(L.playFailed));
      return;
    }
    start(current ?? pages[pageIdx]?.ayahs[0]?.number ?? 1);
  };

  const stopAudio = () => {
    const el = audio.current;
    if (el) {
      el.pause();
      el.removeAttribute('src');
      el.load();
    }
    setPlaying(false);
    setWord(-1);
  };

  const changeMode = (m: SyncMode) => {
    stopAudio();
    setMode(m);
    store('quran_sync', m);
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

  const turn = useCallback((delta: number) => setPageIdx((i) => Math.min(pages.length - 1, Math.max(0, i + delta))), [pages.length]);

  // keyboard: in an Arabic book the next page is on the left
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.target as HTMLElement)?.closest('input,select,textarea')) return;
      if (e.key === 'ArrowLeft') turn(1);
      if (e.key === 'ArrowRight') turn(-1);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [turn]);

  const touchX = useRef<number | null>(null);

  const isRevealed = (n: number) => !(testMode || hideAll) || revealed.has(n);

  const wordText = (n: number, i: number) => {
    const t = ayahText(n);
    const r = wordRanges(t)[i];
    return r ? t.slice(r[0], r[1]) : '';
  };
  const tapWord = (n: number, i: number) => {
    if (!revealed.has(n)) return toggleReveal(n);
    setWordMarks((m) => {
      const next = new Map(m);
      const k = `${n}:${i}`;
      if (next.has(k)) next.delete(k);
      else next.set(k, 'mistake');
      return next;
    });
  };
  const pageRange = () => {
    const p = pages[pageIdx];
    return { from: p?.ayahs[0]?.number ?? 1, to: p?.ayahs[p.ayahs.length - 1]?.number ?? 1 };
  };
  const openPanel = (k: 'range' | 'recite' | 'test') => {
    if (panel === k) return closePanel();
    closePanel();
    setPanel(k);
    if (k === 'test') {
      stopAudio();
      setTestMode(true);
      setRevealed(new Set());
    }
  };
  const closePanel = () => {
    if (panel === 'test') setTestMode(false);
    setHideAll(false);
    setWordMarks(new Map());
    setPanel(null);
  };
  const toggleReveal = (n: number) =>
    setRevealed((p) => {
      const next = new Set(p);
      if (next.has(n)) next.delete(n);
      else next.add(n);
      return next;
    });

  if (failed) return <p className="rounded-lg bg-red-50 px-3 py-4 text-center text-sm text-red-600">{L.loadFailed}</p>;
  if (!detail) return <div className="mx-auto h-[70vh] max-w-[720px] animate-pulse rounded-2xl border bg-white" aria-label={L.loading} />;

  const page = pages[pageIdx];
  const px = SIZES[size] * 16;
  const hiddenStyle: React.CSSProperties = {
    color: 'transparent',
    textShadow: `0 0 ${(0.3 * px).toFixed(1)}px rgba(23,36,30,.55), 0 0 ${(0.55 * px).toFixed(1)}px rgba(23,36,30,.3)`,
  };
  const pageAllRevealed = page.ayahs.every((a) => isRevealed(a.number));
  const sajdas = page.ayahs.filter((a) => a.sajda);

  const renderAyah = (a: Ayah) => {
    const on = mode !== 'none' && current === a.number;
    const shown = isRevealed(a.number);
    const wordMode = on && fits(a.number);
    const marked = testing || [...wordMarks.keys()].some((k) => k.startsWith(`${a.number}:`));
    let body: React.ReactNode = a.text;
    if (marked && !wordMode) {
      // the checked or tested ayah word by word: a mark per word, the teacher taps a word to mark it
      const parts: React.ReactNode[] = [];
      let at = 0;
      wordRanges(a.text).forEach(([s, e], i) => {
        if (s > at) parts.push(a.text.slice(at, s));
        const m = wordMarks.get(`${a.number}:${i}`);
        const style: React.CSSProperties | undefined = !shown
          ? hiddenStyle
          : m === 'missing' || m === 'mistake'
            ? { color: '#B42318', textDecoration: 'underline wavy #B42318', textUnderlineOffset: '0.35em', background: m === 'mistake' ? '#FDE7E5' : undefined }
            : m === 'wrong'
              ? { color: '#C2410C', textDecoration: 'underline wavy #C2410C', textUnderlineOffset: '0.35em' }
              : undefined;
        parts.push(
          <span
            key={i}
            style={style}
            onClick={
              testing
                ? (ev) => {
                    ev.stopPropagation();
                    tapWord(a.number, i);
                  }
                : undefined
            }
          >
            {a.text.slice(s, e)}
          </span>,
        );
        at = e;
      });
      if (at < a.text.length) parts.push(a.text.slice(at));
      body = parts;
    } else if (wordMode) {
      // the ayah written word by word, each word styled on its own - the text itself is untouched
      const ranges = wordRanges(a.text);
      const parts: React.ReactNode[] = [];
      let at = 0;
      ranges.forEach(([s, e], i) => {
        if (s > at) parts.push(a.text.slice(at, s));
        const spoken = i === word;
        const visible = shown || i <= word;
        parts.push(
          <span key={i} style={visible ? (spoken ? { color: GOLD } : undefined) : hiddenStyle}>
            {a.text.slice(s, e)}
          </span>,
        );
        at = e;
      });
      if (at < a.text.length) parts.push(a.text.slice(at));
      body = parts;
    } else if (!shown) {
      body = <span style={hiddenStyle}>{a.text}</span>;
    }
    return (
      <span
        key={a.number}
        id={`ayah-${a.number}`}
        onClick={() => (testMode ? toggleReveal(a.number) : setMenu(menu === a.number ? null : a.number))}
        className={`cursor-pointer rounded-md [box-decoration-break:clone] ${on ? 'bg-amber-100/80' : menu === a.number ? 'bg-gray-100' : ''}`}
      >
        {body}
        {/* the end-of-ayah sign is real text (U+06DD + digits drawn inside by the font), never a widget */}
        <span className="text-brand">{` ۝${arabicNumber(a.number)}`}</span>
        {marks.has(a.number) && <span className="text-[0.6em]"> 🔖</span>}{' '}
      </span>
    );
  };

  const isFirstPage = pageIdx === 0;
  const hasBasmala = surah !== 1 && surah !== 9;

  return (
    <div>
      <audio
        ref={audio}
        onEnded={onEnded}
        onPause={() => setPlaying(false)}
        onPlay={() => setPlaying(true)}
        onError={() => audio.current?.getAttribute('src') && setError(L.playFailed)}
        preload="none"
      />

      {/* player */}
      <div className="sticky top-14 z-10 mx-auto mb-4 flex max-w-[720px] flex-wrap items-center gap-2 rounded-xl border bg-white/95 p-2.5 text-sm shadow-sm backdrop-blur print:hidden">
        <button onClick={toggle} className="flex items-center gap-1.5 rounded-lg bg-brand px-3.5 py-2 font-semibold text-white" aria-label={playing ? L.pause : L.play}>
          {playing ? <Pause size={16} /> : <Play size={16} />} {playing ? L.pause : L.play}
        </button>
        {mode !== 'none' && (
          <>
            <button onClick={() => current && current > 1 && start(current - 1)} className="rounded-lg border p-2" aria-label={L.prevAyah} title={L.prevAyah}>
              <SkipBack size={16} className="rtl:-scale-x-100" />
            </button>
            <button onClick={() => (current ?? 0) < ayahCount && start((current ?? 0) + 1)} className="rounded-lg border p-2" aria-label={L.nextAyah} title={L.nextAyah}>
              <SkipForward size={16} className="rtl:-scale-x-100" />
            </button>
          </>
        )}
        <select value={mode} onChange={(e) => changeMode(e.target.value as SyncMode)} className="rounded-lg border px-2 py-1.5" aria-label={L.sync}>
          <option value="none">{L.syncNone}</option>
          <option value="ayah">{L.syncAyah}</option>
          <option value="word">{L.syncWord}</option>
        </select>
        {mode === 'none' ? (
          detail.audio.length > 0 && (
            <select
              value={surahAudio}
              onChange={(e) => {
                stopAudio();
                setSurahAudio(Number(e.target.value));
              }}
              className="max-w-[14rem] rounded-lg border px-2 py-1.5"
              aria-label={L.reciter}
            >
              {detail.audio.map((a, i) => (
                <option key={i} value={i}>
                  {a.reciter}
                  {a.rewaya ? ` — ${a.rewaya}` : ''}
                </option>
              ))}
            </select>
          )
        ) : (
          <>
            <select
              value={reciter?.id}
              onChange={(e) => {
                stopAudio();
                setReciterId(e.target.value);
                store('quran_reciter', e.target.value);
              }}
              className="max-w-[14rem] rounded-lg border px-2 py-1.5"
              aria-label={L.reciter}
            >
              {reciters.map((r) => (
                <option key={r.id} value={r.id}>
                  {reciterLabel(r)}
                </option>
              ))}
            </select>
            <label className="flex items-center gap-1 text-gray-600">
              {L.repeat}
              <select value={repeat} onChange={(e) => setRepeat(Number(e.target.value))} className="rounded-lg border px-1 py-1.5">
                {[1, 2, 3, 5, 10].map((n) => (
                  <option key={n} value={n}>
                    ×{n}
                  </option>
                ))}
              </select>
            </label>
          </>
        )}
        <span className="ms-auto flex items-center gap-1.5">
          <span className="flex overflow-hidden rounded-lg border" role="group" aria-label={L.fontSize}>
            {SIZES.map((_, i) => (
              <button
                key={i}
                onClick={() => {
                  setSize(i);
                  store('quran_size', String(i));
                }}
                className={`px-2 py-1 ${size === i ? 'bg-brand text-white' : 'bg-white'}`}
                style={{ fontSize: `${0.75 + i * 0.12}rem` }}
                aria-pressed={size === i}
              >
                أ
              </button>
            ))}
          </span>
          <button
            onClick={() => {
              setTestMode((v) => !v);
              setRevealed(new Set());
            }}
            className={`flex items-center gap-1 rounded-lg border px-2.5 py-1.5 ${testMode ? 'border-brand bg-brand/10 font-semibold text-brand' : ''}`}
            aria-pressed={testMode}
          >
            {testMode ? <EyeOff size={15} /> : <Eye size={15} />} {L.testMode}
          </button>
        </span>
        <span className="flex w-full flex-wrap items-center gap-1.5 border-t pt-2">
          <button
            onClick={() => openPanel('range')}
            className={`flex items-center gap-1 rounded-lg border px-2.5 py-1.5 ${range ? 'border-brand bg-brand/10 font-semibold text-brand' : ''}`}
            aria-pressed={!!range}
          >
            <Repeat size={15} /> {range ? `${R.rangeTitle}: ${arabicNumber(range.from)}–${arabicNumber(range.to)} ×${range.times}` : R.rangeTitle}
          </button>
          {range && playing && <span className="text-xs text-gray-500">{fmt(R.loop, { n: loopNo, total: range.times })}</span>}
          {role === 'family' ? (
            <button
              onClick={() => openPanel('recite')}
              className={`ms-auto flex items-center gap-1 rounded-lg px-3 py-1.5 font-semibold ${panel === 'recite' ? 'bg-brand text-white' : 'border border-brand text-brand'}`}
            >
              <Mic size={15} /> {R.recite}
            </button>
          ) : (
            <button
              onClick={() => openPanel('test')}
              className={`ms-auto flex items-center gap-1 rounded-lg px-3 py-1.5 font-semibold ${panel === 'test' ? 'bg-brand text-white' : 'border border-brand text-brand'}`}
            >
              <ClipboardCheck size={15} /> {R.testStudent}
            </button>
          )}
        </span>
      </div>

      {panel === 'range' && (
        <RangePanel
          max={ayahCount}
          initial={range ?? { ...pageRange(), times: 3 }}
          onApply={(r) => {
            stopAudio();
            setRange(r);
            setLoopNo(1);
            if (r && mode === 'none') changeMode('ayah');
            setPanel(null);
          }}
          onClose={() => setPanel(null)}
          L={R}
        />
      )}
      {panel === 'recite' && (
        <RecitePanel
          orgId={orgId}
          surah={surah}
          max={ayahCount}
          initial={pageRange()}
          people={people}
          typeLabels={typeLabels}
          onHide={(h) => {
            if (h) stopAudio();
            setRevealed(new Set());
            setHideAll(h);
          }}
          onMarks={setWordMarks}
          onClose={closePanel}
          L={R}
        />
      )}
      {panel === 'test' && (
        <TestPanel
          orgId={orgId}
          surah={surah}
          max={ayahCount}
          initial={pageRange()}
          people={people}
          grades={grades}
          typeLabels={typeLabels}
          mistakes={[...wordMarks.keys()]}
          wordText={wordText}
          onReset={() => {
            setWordMarks(new Map());
            setRevealed(new Set());
          }}
          onClose={closePanel}
          L={R}
        />
      )}

      {error && <p className="mx-auto mb-3 max-w-[720px] rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {mode === 'word' && timingsMissing && (
        <p className="mx-auto mb-3 max-w-[720px] rounded-lg bg-amber-50 px-3 py-2 text-sm text-amber-800">{L.noTimings}</p>
      )}
      {testMode && !testing && <p className="mx-auto mb-3 max-w-[720px] rounded-lg bg-brand/5 px-3 py-2 text-sm text-brand">{L.testHint}</p>}

      {/* the page */}
      <article
        className="mx-auto max-w-[720px] rounded-2xl border border-[#E7DFC9] bg-[#FFFDF6] px-5 py-4 shadow-soft sm:px-8"
        onTouchStart={(e) => (touchX.current = e.touches[0].clientX)}
        onTouchEnd={(e) => {
          if (touchX.current == null) return;
          const dx = e.changedTouches[0].clientX - touchX.current;
          touchX.current = null;
          // like paper: pull the page to the right to reach the next one
          if (Math.abs(dx) > 60) turn(dx > 0 ? 1 : -1);
        }}
        dir="rtl"
        lang="ar"
      >
        <header className="mb-3 flex items-center justify-between border-b border-[#E7DFC9] pb-2 text-sm text-gray-500">
          <span className="font-quran text-lg text-ink">سورة {surahName}</span>
          <span className="flex items-center gap-2">
            {testMode && (
              <button
                onClick={() =>
                  setRevealed((p) => {
                    const next = new Set(p);
                    page.ayahs.forEach((a) => (pageAllRevealed ? next.delete(a.number) : next.add(a.number)));
                    return next;
                  })
                }
                className="rounded-full border px-2.5 py-0.5 text-xs text-brand"
              >
                {pageAllRevealed ? L.hidePage : L.revealPage}
              </button>
            )}
            <span className="rounded-full bg-[#F3EBD3] px-2.5 py-0.5 text-xs">الجزء {arabicNumber(page.juz)}</span>
            <span className="rounded-full bg-[#F3EBD3] px-2.5 py-0.5 text-xs">صفحة {arabicNumber(page.page)}</span>
          </span>
        </header>

        {isFirstPage && (
          <>
            <div className="mb-3 rounded-xl border border-[#D9C78F] bg-[#F6EED4] px-4 py-2 text-center">
              <p className="font-quran text-2xl leading-[2.4] text-ink">سورة {surahName}</p>
              <p className="pb-1 text-xs text-gray-600">
                {[detail.place, `آياتها ${arabicNumber(ayahCount)}`].filter(Boolean).join(' · ')}
              </p>
            </div>
            {hasBasmala && (
              <p className="mb-2 text-center font-quran text-ink" style={{ fontSize: `${SIZES[size] * 1.05}rem` }}>
                بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ
              </p>
            )}
          </>
        )}

        <p className="text-justify font-quran text-ink" style={{ fontSize: `${SIZES[size]}rem`, lineHeight: 2.25 }}>
          {page.ayahs.map(renderAyah)}
        </p>

        {sajdas.length > 0 && (
          <p className="mt-3 border-t border-[#E7DFC9] pt-2 text-center text-sm text-gray-600">
            <span className="font-quran">۩</span> {fmt(L.sajda, { list: sajdas.map((a) => arabicNumber(a.number)).join('، ') })}
          </p>
        )}
      </article>

      {/* page turning */}
      <nav className="mx-auto mt-3 flex max-w-[720px] items-center justify-between text-sm print:hidden" dir="rtl">
        <button onClick={() => turn(-1)} disabled={pageIdx === 0} className="flex items-center gap-1 rounded-lg border bg-white px-3 py-2 disabled:opacity-40">
          <ChevronRight size={16} /> {L.prevPage}
        </button>
        <span className="flex items-center gap-1 text-gray-500">
          <BookOpen size={14} /> {arabicNumber(pageIdx + 1)} / {arabicNumber(pages.length)}
        </span>
        <button onClick={() => turn(1)} disabled={pageIdx >= pages.length - 1} className="flex items-center gap-1 rounded-lg border bg-white px-3 py-2 disabled:opacity-40">
          {L.nextPage} <ChevronLeft size={16} />
        </button>
      </nav>

      {/* what to do with the tapped ayah */}
      {menu != null && (
        <div className="fixed inset-x-0 bottom-0 z-40 border-t bg-white p-3 shadow-[0_-4px_16px_rgba(0,0,0,0.08)] print:hidden">
          <div className="mx-auto flex max-w-[720px] flex-wrap items-center gap-2 text-sm">
            <span className="me-auto font-semibold">{fmt(L.ayahOf, { surah: surahName, ayah: arabicNumber(menu) })}</span>
            {mode !== 'none' && (
              <button
                className="rounded-lg bg-brand px-3 py-1.5 font-semibold text-white"
                onClick={() => {
                  const n = menu;
                  setMenu(null);
                  start(n);
                }}
              >
                {L.fromHere}
              </button>
            )}
            <button
              className="rounded-lg border px-3 py-1.5"
              onClick={() => {
                const n = menu;
                setMenu(null);
                void mark(n);
              }}
            >
              {marks.has(menu) ? L.unmark : L.mark}
            </button>
            <button
              className="rounded-lg border px-3 py-1.5"
              onClick={() => {
                const n = menu;
                setMenu(null);
                void navigator.clipboard?.writeText(`${ayahText(n)} ﴿${arabicNumber(n)}﴾ [${surahName}]`);
              }}
            >
              {L.copy}
            </button>
            <button className="rounded-lg p-1.5 text-gray-500 hover:bg-gray-100" onClick={() => setMenu(null)} aria-label={L.close}>
              <X size={16} />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
