'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { CheckCircle2, Mic, Play, RotateCcw, Send, Square } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { QURAN_DATA, parseSurahFile, type Ayah } from '@/lib/quran/mushaf';
import { fallbackSurah } from '@/lib/quran/actions';
import { AYAH_COUNTS, SURAH_NAMES, surahLabel } from '@/lib/quran/data';
import { arabicNumber } from '@/lib/quran/reader';
import { LiveMatcher, stableWords, type LiveEvent } from '@/lib/quran/live-recite';
import { toWav16k } from '@/lib/quran/wav';
import { fmt } from '@/lib/i18n/config';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';

const TYPES = ['new_memorization', 'recent_review', 'distant_review'] as const;
const STALL_MS = 9000; // silence on one word = forgotten
const SETTLE_MS = 2500; // an unexpected word nothing followed = said wrong
const field = 'mt-1 w-full rounded-md border bg-white px-3 py-2 text-sm';

// the Web Speech API is not in the TypeScript DOM types everywhere
type Recognition = {
  lang: string;
  continuous: boolean;
  interimResults: boolean;
  maxAlternatives: number;
  start(): void;
  stop(): void;
  abort(): void;
  onresult: ((e: { results: ArrayLike<{ isFinal: boolean; 0: { transcript: string } }> }) => void) | null;
  onerror: ((e: { error: string }) => void) | null;
  onend: (() => void) | null;
};
const recognitionCtor = (): (new () => Recognition) | null => {
  if (typeof window === 'undefined') return null;
  const w = window as unknown as { SpeechRecognition?: new () => Recognition; webkitSpeechRecognition?: new () => Recognition };
  return w.SpeechRecognition ?? w.webkitSpeechRecognition ?? null;
};

/** A short low "wrong" sound, made on the spot (no file to load). */
function beep() {
  try {
    const Ctx = window.AudioContext ?? (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    const ctx = new Ctx();
    [0, 0.18].forEach((at, i) => {
      const o = ctx.createOscillator();
      const g = ctx.createGain();
      o.type = 'square';
      o.frequency.value = i ? 220 : 330;
      g.gain.setValueAtTime(0.0001, ctx.currentTime + at);
      g.gain.exponentialRampToValueAtTime(0.18, ctx.currentTime + at + 0.02);
      g.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + at + 0.16);
      o.connect(g).connect(ctx.destination);
      o.start(ctx.currentTime + at);
      o.stop(ctx.currentTime + at + 0.17);
    });
    setTimeout(() => void ctx.close(), 600);
  } catch {}
  try {
    navigator.vibrate?.([120, 60, 120]);
  } catch {}
}

type Phase = 'setup' | 'loading' | 'live' | 'result' | 'sending' | 'sent';

/**
 * Reciting from memory with the device following along: the chosen ayahs are
 * hidden, each word uncovers when it is said right, and a forgotten or wrong
 * word stops the student with a red mark and a sound. The result (and a
 * recording, when the browser can make one alongside) goes to the teacher.
 */
export function LiveRecite({
  orgId,
  students,
  initial,
  typeLabels,
  locale,
  L,
}: {
  orgId: string;
  students: { id: string; name: string }[];
  initial: { student?: string; surah?: number; from?: number; to?: number; type?: string };
  typeLabels: Record<string, string>;
  locale: string;
  L: Dictionary['live'];
}) {
  const [studentId, setStudentId] = useState(students.find((s) => s.id === initial.student)?.id ?? students[0]?.id ?? '');
  const [surah, setSurah] = useState(initial.surah && initial.surah >= 1 && initial.surah <= 114 ? initial.surah : 1);
  const count = AYAH_COUNTS[surah - 1];
  const [from, setFrom] = useState(initial.from ?? 1);
  const [to, setTo] = useState(initial.to ?? Math.min(count, (initial.from ?? 1) + 4));
  const [type, setType] = useState<string>(TYPES.includes(initial.type as never) ? (initial.type as string) : 'new_memorization');
  const [withAudio, setWithAudio] = useState(false);
  const [phase, setPhase] = useState<Phase>('setup');
  const [error, setError] = useState('');
  const [supported, setSupported] = useState(true);
  const [, setTick] = useState(0); // re-render when the matcher moves
  const [stop, setStop] = useState<Extract<LiveEvent, { kind: 'mistake' }> | null>(null);
  const [listening, setListening] = useState(false);
  const [note, setNote] = useState('');
  const [audioUrl, setAudioUrl] = useState('');

  const matcher = useRef<LiveMatcher | null>(null);
  const rec = useRef<Recognition | null>(null);
  const active = useRef(false); // the session is on (not paused, not finished)
  const processed = useRef(0); // words of the current recognition session already fed
  const lastProgress = useRef(0);
  const lastHeard = useRef(0);
  const heard = useRef<string[]>([]);
  const media = useRef<{ recorder: MediaRecorder; chunks: Blob[]; started: number } | null>(null);
  const audio = useRef<{ blob: Blob; seconds: number } | null>(null);
  const range = { from: Math.min(from, to), to: Math.max(from, to) };

  useEffect(() => {
    setSupported(!!recognitionCtor());
    setWithAudio(!/Android|iPhone|iPad/i.test(navigator.userAgent)); // phones: one thing on the microphone at a time
  }, []);
  useEffect(() => {
    // a new surah: keep the passage inside it
    setFrom((f) => Math.min(f, count));
    setTo((t) => Math.min(t, count));
  }, [count]);

  const rerender = () => setTick((n) => n + 1);

  const stopListening = useCallback(() => {
    active.current = false;
    setListening(false);
    try {
      rec.current?.abort();
    } catch {}
  }, []);

  const handle = useCallback(
    (ev: LiveEvent | null) => {
      if (!ev) return;
      lastProgress.current = Date.now();
      rerender();
      if (ev.kind === 'mistake') {
        stopListening();
        setStop(ev);
        beep();
      } else if (ev.kind === 'done') {
        finish();
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [stopListening],
  );

  const listen = useCallback(() => {
    const Ctor = recognitionCtor();
    if (!Ctor) return;
    const r = new Ctor();
    r.lang = 'ar-SA';
    r.continuous = true;
    r.interimResults = true;
    r.maxAlternatives = 1;
    processed.current = 0;
    r.onresult = (e) => {
      if (!active.current) return;
      const list = Array.from(e.results).map((x) => ({ transcript: x[0].transcript, final: x.isFinal }));
      const words = stableWords(list);
      for (; processed.current < words.length && active.current; processed.current++) {
        heard.current.push(words[processed.current]);
        lastHeard.current = Date.now();
        handle(matcher.current!.feed(words[processed.current]));
      }
    };
    r.onerror = (e) => {
      if (e.error === 'not-allowed' || e.error === 'service-not-allowed') {
        stopListening();
        setError(L.micDenied);
      } else if (e.error === 'network') {
        stopListening();
        setError(L.network);
      }
    };
    // the browser ends a session after a pause: carry on while the recitation is on
    r.onend = () => {
      if (active.current) setTimeout(() => active.current && listen(), 120);
    };
    rec.current = r;
    active.current = true;
    setListening(true);
    lastProgress.current = Date.now();
    try {
      r.start();
    } catch {}
  }, [handle, stopListening, L.micDenied, L.network]);

  // silence on one word for too long = forgotten
  useEffect(() => {
    if (phase !== 'live') return;
    const id = setInterval(() => {
      const m = matcher.current;
      if (!active.current || !m || m.done) return;
      if (m.pending && Date.now() - lastHeard.current > SETTLE_MS) return handle(m.settle());
      const wait = m.pos === 0 ? STALL_MS * 1.6 : STALL_MS;
      if (Date.now() - lastProgress.current > wait) handle(m.forgot());
    }, 1000);
    return () => clearInterval(id);
  }, [phase, handle]);

  useEffect(
    () => () => {
      active.current = false;
      try {
        rec.current?.abort();
      } catch {}
      media.current?.recorder.stream.getTracks().forEach((t) => t.stop());
    },
    [],
  );

  const begin = async () => {
    setError('');
    if (!supported) return setError(L.unsupported);
    setPhase('loading');
    let detail = null;
    try {
      const res = await fetch(`${QURAN_DATA}/surah_${surah}.json`);
      if (res.ok) detail = parseSurahFile(surah, await res.json());
    } catch {}
    if (!detail?.ayahs.length) detail = await fallbackSurah(surah).catch(() => null);
    const ayahs = (detail?.ayahs ?? []).filter((a: Ayah) => a.number >= range.from && a.number <= range.to);
    if (!ayahs.length) {
      setPhase('setup');
      return setError(L.error);
    }
    matcher.current = new LiveMatcher(ayahs);
    heard.current = [];
    audio.current = null;
    setAudioUrl('');
    setStop(null);
    if (withAudio) {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        const chunks: Blob[] = [];
        const recorder = new MediaRecorder(stream);
        recorder.ondataavailable = (e) => e.data.size && chunks.push(e.data);
        recorder.start(1000);
        media.current = { recorder, chunks, started: Date.now() };
      } catch {
        media.current = null; // reciting still works without the recording
      }
    }
    setPhase('live');
    listen();
  };

  const resume = () => {
    setStop(null);
    if (matcher.current?.done) return finish();
    listen();
  };

  const forgot = () => handle(matcher.current?.forgot() ?? null);

  function finish() {
    stopListening();
    setStop(null);
    matcher.current?.finish();
    const m = media.current;
    media.current = null;
    if (m && m.recorder.state !== 'inactive') {
      m.recorder.onstop = async () => {
        m.recorder.stream.getTracks().forEach((t) => t.stop());
        try {
          const { wav, seconds } = await toWav16k(new Blob(m.chunks, { type: m.recorder.mimeType }));
          audio.current = { blob: wav, seconds };
          setAudioUrl(URL.createObjectURL(wav));
        } catch {}
      };
      m.recorder.stop();
    }
    setPhase('result');
  }

  const send = async () => {
    const m = matcher.current;
    if (!m) return;
    setPhase('sending');
    setError('');
    const supabase = createClient();
    try {
      let path: string | null = null;
      if (audio.current) {
        path = `${orgId}/${studentId}/${crypto.randomUUID()}.wav`;
        const up = await supabase.storage.from('recitations').upload(path, audio.current.blob, { contentType: 'audio/wav' });
        if (up.error) path = null; // the result still goes
      }
      const { error: e } = await supabase.rpc('submit_live_recitation', {
        p_org: orgId,
        p_student: studentId,
        p_type: type,
        p_surah: surah,
        p_ayah_from: range.from,
        p_ayah_to: range.to,
        p_result: m.result(),
        p_transcript: heard.current.join(' '),
        p_audio_path: path,
        p_duration: audio.current?.seconds ?? null,
        p_note: note || null,
        p_client_ref: crypto.randomUUID(),
      });
      if (e) throw e;
      setPhase('sent');
    } catch (e) {
      setError((e as { message?: string })?.message || L.error);
      setPhase('result');
    }
  };

  const m = matcher.current;
  const res = m?.result();

  // ---- setup
  if (phase === 'setup' || phase === 'loading') {
    return (
      <div className="space-y-4 rounded-xl border bg-white p-4">
        <p className="text-sm text-gray-600">{L.hint}</p>
        {!supported && <p className="rounded-md bg-amber-50 px-3 py-2 text-sm text-amber-800">{L.unsupported}</p>}
        <div className="grid gap-3 sm:grid-cols-2">
          {students.length > 1 && (
            <label className="text-sm sm:col-span-2">
              {L.student}
              <select value={studentId} onChange={(e) => setStudentId(e.target.value)} className={field}>
                {students.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.name}
                  </option>
                ))}
              </select>
            </label>
          )}
          <label className="text-sm">
            {L.surah}
            <select value={surah} onChange={(e) => setSurah(Number(e.target.value))} className={field}>
              {SURAH_NAMES.map((n, i) => (
                <option key={i} value={i + 1}>
                  {i + 1}. {locale === 'ar' ? n : surahLabel(i + 1, locale)}
                </option>
              ))}
            </select>
          </label>
          <label className="text-sm">
            {L.type}
            <select value={type} onChange={(e) => setType(e.target.value)} className={field}>
              {TYPES.map((k) => (
                <option key={k} value={k}>
                  {typeLabels[k] ?? k}
                </option>
              ))}
            </select>
          </label>
          <label className="text-sm">
            {L.from}
            <input type="number" min={1} max={count} value={from} onChange={(e) => setFrom(Math.min(count, Math.max(1, Number(e.target.value) || 1)))} className={field} />
          </label>
          <label className="text-sm">
            {L.to}
            <input type="number" min={1} max={count} value={to} onChange={(e) => setTo(Math.min(count, Math.max(1, Number(e.target.value) || 1)))} className={field} />
          </label>
        </div>
        <label className="flex items-center gap-2 text-sm text-gray-700">
          <input type="checkbox" checked={withAudio} onChange={(e) => setWithAudio(e.target.checked)} /> {L.attachAudio}
        </label>
        <button
          onClick={begin}
          disabled={!studentId || phase === 'loading' || !supported}
          className="flex w-full items-center justify-center gap-2 rounded-md bg-brand px-4 py-3 font-semibold text-white disabled:opacity-50"
        >
          <Mic size={18} /> {phase === 'loading' ? L.loading : L.start}
        </button>
        {error && <p className="rounded-md bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      </div>
    );
  }

  // ---- the passage, hidden until said
  const words = m?.words ?? [];
  const reached = words.filter((w) => w.state !== 'hidden').length;
  const stopped = stop ? stop.at.map((i) => words[i]?.text).filter(Boolean).join(' ') : '';
  const byAyah = new Map<number, typeof words>();
  words.forEach((w) => byAyah.set(w.a, [...(byAyah.get(w.a) ?? []), w]));

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-3 rounded-xl border bg-white px-4 py-3 text-sm">
        <span className="font-semibold">
          {surahLabel(surah, locale)} {range.from}–{range.to}
        </span>
        <span className="text-gray-500">{fmt(L.progress, { n: reached, total: words.length })}</span>
        <span className={m && m.mistakes ? 'font-semibold text-red-700' : 'text-gray-500'}>{fmt(L.mistakesN, { n: m?.mistakes ?? 0 })}</span>
        {phase === 'live' && (
          <span className={`ms-auto flex items-center gap-1.5 ${listening ? 'text-green-700' : 'text-gray-500'}`}>
            <span className={`h-2.5 w-2.5 rounded-full ${listening ? 'animate-pulse bg-green-600' : 'bg-gray-400'}`} />
            {listening ? L.listening : L.paused}
          </span>
        )}
      </div>

      <div className="h-1.5 overflow-hidden rounded bg-gray-100">
        <div className="h-full bg-brand transition-all" style={{ width: `${words.length ? (reached / words.length) * 100 : 0}%` }} />
      </div>

      <article dir="rtl" lang="ar" className="rounded-2xl border border-[#E7DFC9] bg-[#FFFDF6] px-5 py-5 text-justify font-quran text-[1.7rem] leading-[2.3] text-ink sm:px-8">
        {[...byAyah.entries()].map(([a, ws]) => (
          <span key={a}>
            {ws.map((w, k) => {
              const cls =
                w.state === 'hidden'
                  ? 'text-transparent [text-shadow:0_0_9px_rgba(23,36,30,.5)]'
                  : w.state === 'ok'
                    ? 'text-ink transition-colors'
                    : 'rounded bg-red-50 text-red-700 underline decoration-red-600 decoration-wavy underline-offset-8';
              const isNext = phase === 'live' && words.indexOf(w) === m?.pos;
              return (
                <span key={k}>
                  <span className={`${cls} ${isNext ? 'rounded outline outline-1 outline-offset-4 outline-amber-300' : ''}`}>{w.text}</span>{' '}
                </span>
              );
            })}
            <span className="text-brand">{`۝${arabicNumber(a)}`} </span>
          </span>
        ))}
      </article>

      {/* the controls stay in sight at the bottom of the screen: the stop, finish-and-send, the result and its send button */}
      <div className="sticky bottom-0 z-20 -mx-4 max-h-[65vh] space-y-3 overflow-y-auto border-t bg-white/95 px-4 py-3 shadow-[0_-6px_18px_rgba(0,0,0,0.08)] backdrop-blur sm:mx-0 sm:rounded-t-xl sm:border">
      {stop && (
        <div className="rounded-xl border-2 border-red-300 bg-red-50 p-4" role="alert">
          <p className="font-bold text-red-800">{stop.type === 'missing' ? L.stopMissing : L.stopWrong}</p>
          <p className="mt-1 text-red-900">
            {L.correctIs}{' '}
            <span className="font-quran text-2xl" lang="ar">
              {stopped}
            </span>
          </p>
          {stop.heard && <p className="text-sm text-red-700">{fmt(L.heard, { w: stop.heard })}</p>}
          <button onClick={resume} className="mt-3 flex items-center gap-1.5 rounded-md bg-red-700 px-4 py-2 font-semibold text-white">
            <Play size={15} className="rtl:-scale-x-100" /> {L.continue}
          </button>
        </div>
      )}

      {phase === 'live' && !stop && (
        <div className="flex flex-wrap gap-2">
          <button onClick={forgot} className="rounded-md border px-4 py-2 text-sm">
            {L.forgot}
          </button>
          <button onClick={finish} className="ms-auto flex items-center gap-1.5 rounded-md bg-brand px-4 py-2 text-sm font-semibold text-white">
            <Square size={13} /> {L.finish}
          </button>
        </div>
      )}

      {(phase === 'result' || phase === 'sending') && res && (
        <div className="space-y-3 rounded-xl border bg-white p-4">
          <p className="flex items-baseline gap-3">
            <span className="font-bold">{L.result}</span>
            <span className="text-2xl font-bold text-brand">{fmt(L.score, { n: res.score })}</span>
          </p>
          {m && m.mistakes > 0 && (
            <p className="text-sm">
              <span className="text-gray-500">{L.mistakeList} </span>
              {m.words
                .filter((w) => w.state === 'missing' || w.state === 'wrong')
                .map((w, k) => (
                  <span key={k} className="me-2 font-quran text-xl text-red-700" lang="ar">
                    {w.text}
                  </span>
                ))}
            </p>
          )}
          {audioUrl && <audio controls src={audioUrl} className="h-9 w-full" />}
          <p className="text-xs text-gray-500">{L.resultNote}</p>
          <input value={note} onChange={(e) => setNote(e.target.value)} maxLength={300} placeholder={L.note} className={field} />
          <div className="flex flex-wrap gap-2">
            <button onClick={send} disabled={phase === 'sending'} className="flex items-center gap-1.5 rounded-md bg-brand px-5 py-2.5 font-semibold text-white disabled:opacity-50">
              <Send size={15} className="rtl:-scale-x-100" /> {phase === 'sending' ? L.sending : L.send}
            </button>
            <button onClick={() => setPhase('setup')} className="flex items-center gap-1.5 rounded-md border px-4 py-2.5">
              <RotateCcw size={15} /> {L.again}
            </button>
          </div>
        </div>
      )}

      {phase === 'sent' && (
        <div className="space-y-3 rounded-xl border border-green-200 bg-green-50 p-4">
          <p className="flex items-center gap-2 font-semibold text-green-800">
            <CheckCircle2 size={18} /> {L.sent}
          </p>
          <div className="flex flex-wrap gap-2">
            <button onClick={() => setPhase('setup')} className="rounded-md bg-brand px-4 py-2 font-semibold text-white">
              {L.again}
            </button>
            <a href={`/my/recitations?s=${studentId}` as never} className="rounded-md border bg-white px-4 py-2">
              {L.mine}
            </a>
          </div>
        </div>
      )}

      {error && <p className="rounded-md bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      </div>
    </div>
  );
}
