import { CheckCircle2, Clock, Mic } from 'lucide-react';
import { AYAH_COUNTS, surahLabel } from '@/lib/quran/data';
import { fmt } from '@/lib/i18n/config';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';

type State = 'todo' | 'sent' | 'done';
export interface Wird {
  date: string;
  working_day: boolean;
  complete: boolean;
  new: { surah: number; ayah_from: number; ayah_to: number; state: State } | null;
  review: { surah_from: number; ayah_from: number; surah_to: number; ayah_to: number; pages: number; approved: boolean; state: State } | null;
}

/** ورد اليوم: the new portion and the review portion, each with a "recite now" that opens the mushaf on it (student_wird, 0086). */
export function WirdCard({
  wird,
  base,
  canRecite,
  studentId,
  locale,
  W,
}: {
  wird: Wird | null;
  base: string;
  canRecite: boolean;
  studentId?: string;
  locale: string;
  W: Dictionary['wird'];
}) {
  const link = (surah: number, from: number, to: number, type: string) =>
    canRecite ? `/my/recite?s=${studentId ?? ''}&surah=${surah}&from=${from}&to=${to}&type=${type}` : `${base}/${surah}?ayah=${from}`;
  if (!wird) return null;
  const parts: { key: string; title: string; label: string; note?: string; state: State; href: string }[] = [];
  if (wird.new) {
    const n = wird.new;
    parts.push({
      key: 'new',
      title: W.newPart,
      label: `${surahLabel(n.surah, locale)} ${n.ayah_from}–${n.ayah_to}`,
      state: n.state,
      href: link(n.surah, n.ayah_from, n.ayah_to, 'new_memorization'),
    });
  }
  if (wird.review) {
    const r = wird.review;
    const sameSurah = r.surah_from === r.surah_to;
    const to = sameSurah ? r.ayah_to : AYAH_COUNTS[r.surah_from - 1];
    parts.push({
      key: 'review',
      title: W.reviewPart,
      label: sameSurah
        ? `${surahLabel(r.surah_from, locale)} ${r.ayah_from}–${r.ayah_to}`
        : `${surahLabel(r.surah_from, locale)} ${r.ayah_from} — ${surahLabel(r.surah_to, locale)} ${r.ayah_to}`,
      note: `${fmt(W.pages, { n: r.pages })} · ${r.approved ? W.fromTeacher : W.suggested}`,
      state: r.state,
      href: link(r.surah_from, r.ayah_from, to, 'recent_review'),
    });
  }

  const badge = (s: State) =>
    s === 'done' ? (
      <span className="flex items-center gap-1 text-xs font-semibold text-green-700"><CheckCircle2 size={14} /> {W.done}</span>
    ) : s === 'sent' ? (
      <span className="flex items-center gap-1 text-xs font-semibold text-amber-700"><Clock size={14} /> {W.sent}</span>
    ) : (
      <span className="text-xs text-gray-500">{W.todo}</span>
    );

  return (
    <section className="rounded-lg border bg-white p-4">
      <h2 className="mb-2 font-bold">{W.title}</h2>
      {!wird.working_day && <p className="mb-2 text-xs text-gray-500">{W.dayOff}</p>}
      {wird.complete && <p className="mb-2 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{W.complete}</p>}
      {parts.length === 0 ? (
        <p className="text-sm text-gray-500">{W.none}</p>
      ) : (
        <ul className="divide-y">
          {parts.map((p) => (
            <li key={p.key} className="flex flex-wrap items-center gap-x-3 gap-y-1 py-2.5">
              <div className="min-w-0 flex-1">
                <p className="text-xs text-gray-500">{p.title}{p.note ? ` · ${p.note}` : ''}</p>
                <p className="font-semibold">{p.label}</p>
              </div>
              {badge(p.state)}
              {p.state === 'todo' && (
                <a href={p.href as never} className="flex items-center gap-1 rounded-md bg-brand px-3 py-1.5 text-sm font-semibold text-white">
                  {canRecite && <Mic size={14} />} {canRecite ? W.recite : W.open}
                </a>
              )}
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
