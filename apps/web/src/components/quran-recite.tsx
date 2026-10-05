'use client';

import { useEffect, useRef, useState } from 'react';
import { Check, Mic, RotateCcw, Send, Square, X } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { toWav16k } from '@/lib/quran/wav';
import type { ReciteResult } from '@/lib/quran/recite';
import { arabicNumber } from '@/lib/quran/reader';
import { fmt } from '@/lib/i18n/config';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';

export type ReciteLabels = Dictionary['quran']['recite'];
export type WordMark = 'missing' | 'wrong' | 'mistake';

export interface People {
  mode: 'staff' | 'family' | 'none';
  students: { id: string; name: string; circle?: string | null }[];
}

const TYPES = ['new_memorization', 'recent_review', 'distant_review'] as const;
const MAX_MINUTES = 5;
const field = 'rounded-lg border bg-white px-2 py-1.5 text-sm';

/** Who may recite / be tested here, loaded once when a panel first opens. */
export function usePeople(orgId: string, wanted: boolean) {
  const [people, setPeople] = useState<People | null>(null);
  const [grades, setGrades] = useState<{ key: string; label: string }[]>([]);
  useEffect(() => {
    if (!wanted || people) return;
    const supabase = createClient();
    void Promise.all([
      supabase.rpc('recitation_people', { p_org: orgId }),
      supabase.from('recitation_grades').select('key, label').eq('organization_id', orgId).eq('is_active', true).order('sort_order'),
    ]).then(([p, g]) => {
      setPeople((p.data as People | null) ?? { mode: 'none', students: [] });
      setGrades((g.data ?? []) as { key: string; label: string }[]);
    });
  }, [orgId, wanted, people]);
  return { people, grades };
}

function RangeFields({
  from,
  to,
  max,
  onChange,
  L,
}: {
  from: number;
  to: number;
  max: number;
  onChange: (from: number, to: number) => void;
  L: ReciteLabels;
}) {
  const clamp = (n: number) => Math.min(max, Math.max(1, Math.round(n) || 1));
  return (
    <>
      <label className="flex items-center gap-1">
        {L.from}
        <input type="number" min={1} max={max} value={from} onChange={(e) => onChange(clamp(+e.target.value), to)} className={`${field} w-16`} />
      </label>
      <label className="flex items-center gap-1">
        {L.to}
        <input type="number" min={1} max={max} value={to} onChange={(e) => onChange(from, clamp(+e.target.value))} className={`${field} w-16`} />
      </label>
    </>
  );
}

/** Repeating a passage: the reader plays from..to, `times` times. */
export function RangePanel({
  max,
  initial,
  onApply,
  onClose,
  L,
}: {
  max: number;
  initial: { from: number; to: number; times: number };
  onApply: (r: { from: number; to: number; times: number } | null) => void;
  onClose: () => void;
  L: ReciteLabels;
}) {
  const [r, setR] = useState(initial);
  return (
    <div className="mx-auto mb-3 flex max-w-[720px] flex-wrap items-center gap-2 rounded-xl border bg-white p-3 text-sm">
      <span className="font-semibold">{L.rangeTitle}</span>
      <RangeFields from={r.from} to={r.to} max={max} onChange={(from, to) => setR({ ...r, from, to })} L={L} />
      <label className="flex items-center gap-1">
        {L.times}
        <select value={r.times} onChange={(e) => setR({ ...r, times: +e.target.value })} className={field}>
          {[1, 2, 3, 5, 7, 10, 20, 30].map((n) => (
            <option key={n} value={n}>
              ×{n}
            </option>
          ))}
        </select>
      </label>
      <button onClick={() => onApply({ ...r, from: Math.min(r.from, r.to), to: Math.max(r.from, r.to) })} className="rounded-lg bg-brand px-3 py-1.5 font-semibold text-white">
        <Check size={15} className="inline" /> {L.rangeTitle}
      </button>
      <button onClick={() => onApply(null)} className="rounded-lg border px-3 py-1.5">
        {L.rangeOff}
      </button>
      <button onClick={onClose} className="ms-auto rounded-lg p-1.5 text-gray-500 hover:bg-gray-100" aria-label={L.cancel}>
        <X size={16} />
      </button>
      <p className="w-full text-xs text-gray-500">{fmt(L.rangeHint, { from: r.from, to: r.to, times: r.times })}</p>
    </div>
  );
}

type Phase = 'setup' | 'recording' | 'working' | 'result' | 'sent';

/**
 * The student (or their guardian) recites a passage from memory: record, the
 * site checks it, the result shows on the page, then it goes to the teacher.
 */
export function RecitePanel({
  orgId,
  surah,
  max,
  initial,
  people,
  typeLabels,
  onHide,
  onMarks,
  onClose,
  L,
}: {
  orgId: string;
  surah: number;
  max: number;
  initial: { from: number; to: number };
  people: People | null;
  typeLabels: Record<string, string>;
  onHide: (hidden: boolean) => void;
  onMarks: (marks: Map<string, WordMark>) => void;
  onClose: () => void;
  L: ReciteLabels;
}) {
  const [range, setRange] = useState(initial);
  const [type, setType] = useState<string>('new_memorization');
  const [studentId, setStudentId] = useState('');
  const [phase, setPhase] = useState<Phase>('setup');
  const [status, setStatus] = useState('');
  const [error, setError] = useState('');
  const [seconds, setSeconds] = useState(0);
  const [result, setResult] = useState<(ReciteResult & { unavailable?: boolean }) | null>(null);
  const [audioUrl, setAudioUrl] = useState('');
  const [note, setNote] = useState('');
  const rec = useRef<MediaRecorder | null>(null);
  const saved = useRef<{ id: string; path: string } | null>(null);

  useEffect(() => {
    if (!studentId && people?.students[0]) setStudentId(people.students[0].id);
  }, [people, studentId]);
  useEffect(() => () => rec.current?.stream.getTracks().forEach((t) => t.stop()), []);
  useEffect(() => {
    if (phase !== 'recording') return;
    const id = setInterval(() => setSeconds((s) => s + 1), 1000);
    return () => clearInterval(id);
  }, [phase]);
  useEffect(() => {
    if (phase === 'recording' && seconds >= MAX_MINUTES * 60) rec.current?.stop();
  }, [phase, seconds]);

  const start = async () => {
    setError('');
    if (!navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === 'undefined') return setError(L.micMissing);
    let stream: MediaStream;
    try {
      stream = await navigator.mediaDevices.getUserMedia({ audio: { echoCancellation: true, noiseSuppression: true } });
    } catch {
      return setError(L.micDenied);
    }
    const chunks: Blob[] = [];
    const r = new MediaRecorder(stream);
    r.ondataavailable = (e) => e.data.size && chunks.push(e.data);
    r.onstop = () => {
      stream.getTracks().forEach((t) => t.stop());
      void finish(new Blob(chunks, { type: r.mimeType }));
    };
    rec.current = r;
    r.start(1000);
    setSeconds(0);
    setPhase('recording');
    onMarks(new Map());
    onHide(true);
  };

  const finish = async (blob: Blob) => {
    setPhase('working');
    setStatus(L.uploading);
    const supabase = createClient();
    try {
      const { wav, seconds: secs } = await toWav16k(blob);
      setAudioUrl(URL.createObjectURL(wav));
      const path = `${orgId}/${studentId}/${crypto.randomUUID()}.wav`;
      const up = await supabase.storage.from('recitations').upload(path, wav, { contentType: 'audio/wav' });
      if (up.error) throw up.error;
      const { data: id, error: e } = await supabase.rpc('create_recitation', {
        p_org: orgId,
        p_student: studentId,
        p_type: type,
        p_surah: surah,
        p_ayah_from: Math.min(range.from, range.to),
        p_ayah_to: Math.max(range.from, range.to),
        p_audio_path: path,
        p_duration: secs,
        p_client_ref: crypto.randomUUID(),
      });
      if (e) throw e;
      saved.current = { id: id as string, path };
      setStatus(L.checking);
      const res = await fetch('/api/recitations/check', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ id }) });
      const body = (await res.json().catch(() => ({}))) as { result?: ReciteResult & { unavailable?: boolean } };
      const r = body.result ?? ({ unavailable: true } as ReciteResult & { unavailable: true });
      setResult(r);
      if (r.words) onMarks(new Map(r.words.filter((w) => w.s !== 'ok').map((w) => [`${w.a}:${w.i}`, w.s as WordMark])));
      onHide(false);
      setPhase('result');
    } catch {
      onHide(false);
      setError(L.uploadFailed);
      setPhase('setup');
    }
  };

  const send = async () => {
    if (!saved.current) return;
    setPhase('working');
    setStatus(L.uploading);
    const { error: e } = await createClient().rpc('submit_recitation', { p_id: saved.current.id, p_note: note || null });
    if (e) {
      setError(e.message || L.error);
      setPhase('result');
    } else setPhase('sent');
  };

  const again = async () => {
    const s = saved.current;
    saved.current = null;
    if (s) {
      const supabase = createClient();
      await supabase.rpc('discard_recitation', { p_id: s.id });
      await supabase.storage.from('recitations').remove([s.path]);
    }
    onMarks(new Map());
    setResult(null);
    setAudioUrl('');
    setPhase('setup');
  };

  const close = () => {
    if (phase === 'recording') rec.current?.stop();
    onHide(false);
    onMarks(new Map());
    onClose();
  };

  const busy = phase !== 'setup';
  const mm = `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;

  return (
    <div className="mx-auto mb-3 max-w-[720px] rounded-xl border bg-white p-3 text-sm">
      <div className="flex flex-wrap items-center gap-2">
        <span className="font-semibold">{L.reciteTitle}</span>
        {people && people.students.length > 1 && (
          <select value={studentId} onChange={(e) => setStudentId(e.target.value)} disabled={busy} className={field} aria-label={L.student}>
            {people.students.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
        )}
        <RangeFields from={range.from} to={range.to} max={max} onChange={(from, to) => !busy && setRange({ from, to })} L={L} />
        <select value={type} onChange={(e) => setType(e.target.value)} disabled={busy} className={field} aria-label={L.type}>
          {TYPES.map((k) => (
            <option key={k} value={k}>
              {typeLabels[k] ?? k}
            </option>
          ))}
        </select>
        <button onClick={close} className="ms-auto rounded-lg p-1.5 text-gray-500 hover:bg-gray-100" aria-label={L.cancel}>
          <X size={16} />
        </button>
      </div>

      {phase === 'setup' && (
        <div className="mt-3 flex flex-wrap items-center gap-3">
          <button onClick={start} disabled={!studentId} className="flex items-center gap-1.5 rounded-lg bg-brand px-4 py-2 font-semibold text-white disabled:opacity-50">
            <Mic size={16} /> {L.start}
          </button>
          <p className="text-xs text-gray-500">{L.reciteHint}</p>
        </div>
      )}

      {phase === 'recording' && (
        <div className="mt-3 flex items-center gap-3">
          <button onClick={() => rec.current?.stop()} className="flex items-center gap-1.5 rounded-lg bg-red-600 px-4 py-2 font-semibold text-white">
            <Square size={14} /> {L.stop}
          </button>
          <span className="flex items-center gap-2 text-red-600">
            <span className="h-2.5 w-2.5 animate-pulse rounded-full bg-red-600" /> {L.recording} <span className="tabular-nums">{mm}</span>
          </span>
        </div>
      )}

      {phase === 'working' && <p className="mt-3 animate-pulse text-gray-600">{status}</p>}

      {phase === 'result' && result && (
        <div className="mt-3 space-y-2">
          {result.unavailable || !result.words ? (
            <p className="rounded-lg bg-amber-50 px-3 py-2 text-amber-800">{L.unavailable}</p>
          ) : (
            <>
              <p className="flex flex-wrap items-baseline gap-x-4 gap-y-1">
                <span className="text-lg font-bold text-brand">{fmt(L.score, { n: result.score })}</span>
                <span>
                  {result.ok} {L.correct}
                </span>
                <span className="text-red-600">
                  {result.missing} {L.missing}
                </span>
                <span className="text-orange-600">
                  {result.wrong} {L.wrong}
                </span>
                {result.extra > 0 && (
                  <span className="text-gray-500">
                    {result.extra} {L.extra}
                  </span>
                )}
              </p>
              <p className="text-xs text-gray-500">{L.legend}</p>
            </>
          )}
          {audioUrl && <audio controls src={audioUrl} className="h-9 w-full" />}
          <p className="text-xs text-gray-500">{L.autoNote}</p>
          <input value={note} onChange={(e) => setNote(e.target.value)} maxLength={300} placeholder={L.note} className={`${field} w-full`} />
          <div className="flex flex-wrap gap-2">
            <button onClick={send} className="flex items-center gap-1.5 rounded-lg bg-brand px-4 py-2 font-semibold text-white">
              <Send size={15} className="rtl:-scale-x-100" /> {L.send}
            </button>
            <button onClick={again} className="flex items-center gap-1.5 rounded-lg border px-3 py-2">
              <RotateCcw size={15} /> {L.again}
            </button>
          </div>
        </div>
      )}

      {phase === 'sent' && (
        <div className="mt-3 flex flex-wrap items-center gap-3">
          <p className="rounded-lg bg-green-50 px-3 py-2 text-green-700">{L.sent}</p>
          <button
            onClick={() => {
              saved.current = null;
              setResult(null);
              setNote('');
              onMarks(new Map());
              setPhase('setup');
            }}
            className="rounded-lg border px-3 py-2"
          >
            {L.again}
          </button>
        </div>
      )}

      {error && <p className="mt-2 rounded-lg bg-red-50 px-3 py-2 text-red-600">{error}</p>}
    </div>
  );
}

/**
 * The teacher tests a student in the mushaf: the ayahs hidden, the mistakes
 * marked on the words, the result saved straight into the student's record.
 */
export function TestPanel({
  orgId,
  surah,
  max,
  initial,
  people,
  grades,
  typeLabels,
  mistakes,
  wordText,
  onReset,
  onClose,
  L,
}: {
  orgId: string;
  surah: number;
  max: number;
  initial: { from: number; to: number };
  people: People | null;
  grades: { key: string; label: string }[];
  typeLabels: Record<string, string>;
  /** "ayah:word" keys marked by tapping the page */
  mistakes: string[];
  wordText: (ayah: number, word: number) => string;
  onReset: () => void;
  onClose: () => void;
  L: ReciteLabels;
}) {
  const [range, setRange] = useState(initial);
  const [type, setType] = useState<string>('new_memorization');
  const [studentId, setStudentId] = useState('');
  const [grade, setGrade] = useState('');
  const [note, setNote] = useState('');
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<{ ok: boolean; text: string } | null>(null);

  useEffect(() => {
    if (!studentId && people?.students[0]) setStudentId(people.students[0].id);
  }, [people, studentId]);
  useEffect(() => {
    if (!grade && grades[0]) setGrade(grades[0].key);
  }, [grades, grade]);

  const save = async () => {
    if (range.from > range.to) return setMsg({ ok: false, text: L.badRange });
    setBusy(true);
    setMsg(null);
    const list = mistakes
      .map((k) => k.split(':').map(Number))
      .filter(([a]) => a >= range.from && a <= range.to)
      .map(([a, w]) => ({ ayah: a, word: w, text: wordText(a, w) }));
    const { data, error } = await createClient().rpc('record_teacher_test', {
      p_org: orgId,
      p_student: studentId,
      p_type: type,
      p_surah: surah,
      p_ayah_from: range.from,
      p_ayah_to: range.to,
      p_grade: grade,
      p_mistakes: list,
      p_note: note || null,
      p_client_ref: crypto.randomUUID(),
    });
    setBusy(false);
    if (error) return setMsg({ ok: false, text: error.message || L.error });
    const name = people?.students.find((s) => s.id === studentId)?.name ?? '';
    setMsg({ ok: true, text: fmt(L.saved, { name, points: (data as { points_awarded?: number })?.points_awarded ?? 0 }) });
    setNote('');
    onReset();
  };

  if (people && !people.students.length) {
    return (
      <div className="mx-auto mb-3 flex max-w-[720px] items-center justify-between rounded-xl border bg-white p-3 text-sm">
        <span className="text-gray-500">{L.noStudents}</span>
        <button onClick={onClose} className="rounded-lg p-1.5 text-gray-500 hover:bg-gray-100" aria-label={L.cancel}>
          <X size={16} />
        </button>
      </div>
    );
  }

  const inRange = mistakes.filter((k) => {
    const a = Number(k.split(':')[0]);
    return a >= range.from && a <= range.to;
  });

  return (
    <div className="mx-auto mb-3 max-w-[720px] space-y-2 rounded-xl border bg-white p-3 text-sm">
      <div className="flex flex-wrap items-center gap-2">
        <span className="font-semibold">{L.testTitle}</span>
        <select value={studentId} onChange={(e) => setStudentId(e.target.value)} className={`${field} max-w-[14rem]`} aria-label={L.chooseStudent}>
          {(people?.students ?? []).map((s) => (
            <option key={s.id} value={s.id}>
              {s.name}
              {s.circle ? ` — ${s.circle}` : ''}
            </option>
          ))}
        </select>
        <button onClick={onClose} className="ms-auto rounded-lg p-1.5 text-gray-500 hover:bg-gray-100" aria-label={L.cancel}>
          <X size={16} />
        </button>
      </div>
      <div className="flex flex-wrap items-center gap-2">
        <RangeFields from={range.from} to={range.to} max={max} onChange={(from, to) => setRange({ from, to })} L={L} />
        <select value={type} onChange={(e) => setType(e.target.value)} className={field} aria-label={L.type}>
          {TYPES.map((k) => (
            <option key={k} value={k}>
              {typeLabels[k] ?? k}
            </option>
          ))}
        </select>
        <select value={grade} onChange={(e) => setGrade(e.target.value)} className={field} aria-label={L.grade}>
          {grades.map((g) => (
            <option key={g.key} value={g.key}>
              {g.label}
            </option>
          ))}
        </select>
        <span className="rounded-full bg-red-50 px-2.5 py-1 font-semibold text-red-700">{fmt(L.mistakes, { n: arabicNumber(inRange.length) })}</span>
      </div>
      <p className="text-xs text-gray-500">{L.testHint}</p>
      <div className="flex flex-wrap gap-2">
        <input value={note} onChange={(e) => setNote(e.target.value)} maxLength={500} placeholder={L.testNote} className={`${field} min-w-0 flex-1`} />
        <button onClick={save} disabled={busy || !studentId || !grade} className="flex items-center gap-1.5 rounded-lg bg-brand px-4 py-2 font-semibold text-white disabled:opacity-50">
          <Check size={15} /> {L.save}
        </button>
      </div>
      {msg && <p className={`rounded-lg px-3 py-2 ${msg.ok ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-600'}`}>{msg.text}</p>}
    </div>
  );
}
