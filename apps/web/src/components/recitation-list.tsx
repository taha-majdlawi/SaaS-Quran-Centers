import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { RecitationWords } from '@/components/recitation-words';
import { RecheckButton } from '@/components/recheck-button';
import { reviewRecitation } from '@/lib/quran/recitation-actions';
import { surahLabel } from '@/lib/quran/data';
import { fmt } from '@/lib/i18n/config';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';

export interface Recitation {
  id: string;
  kind: 'self' | 'teacher_test';
  source?: 'recording' | 'live';
  type: string;
  surah: number;
  ayah_from: number;
  ayah_to: number;
  audio_path: string | null;
  audio_deleted_at?: string | null;
  status: 'draft' | 'submitted' | 'approved' | 'rejected';
  auto_score: number | null;
  auto_result: { words?: { a: number; i: number; s: string; h?: string }[]; ok?: number; missing?: number; wrong?: number; unavailable?: boolean } | null;
  mistakes: { ayah: number; word: number; text?: string }[] | null;
  grade: string | null;
  student_note: string | null;
  teacher_note: string | null;
  submitted_at: string | null;
  reviewed_at: string | null;
  created_at: string;
  student: string | null;
  circle: string | null;
  reviewer: string | null;
}

const STATUS_CLS: Record<string, string> = {
  draft: 'bg-gray-100 text-gray-600',
  submitted: 'bg-amber-100 text-amber-800',
  approved: 'bg-green-100 text-green-700',
  rejected: 'bg-red-100 text-red-700',
};
const field = 'rounded border px-2 py-1.5 text-sm';

/** Signed links to the recordings the caller may hear (storage policy, 0085). */
export async function recitationAudio(items: Recitation[]): Promise<Map<string, string>> {
  const paths = items.map((r) => r.audio_path).filter((p): p is string => !!p);
  if (!paths.length) return new Map();
  const supabase = await createClient();
  const { data } = await supabase.storage.from('recitations').createSignedUrls(paths, 3600);
  return new Map((data ?? []).filter((d) => d.signedUrl && d.path).map((d) => [d.path!, d.signedUrl as string]));
}

/** Recorded recitations and teacher tests: the inbox (staff, with the decision forms) and the student's own list. */
export function RecitationList({
  items,
  audio,
  mode,
  grades,
  typeLabels,
  locale,
  R,
}: {
  items: Recitation[];
  audio: Map<string, string>;
  mode: 'staff' | 'family';
  grades: { key: string; label: string }[];
  typeLabels: Record<string, string>;
  locale: string;
  R: Dictionary['quran']['recite'];
}) {
  if (!items.length) return <p className="rounded-lg border bg-white p-6 text-center text-gray-500">{R.none}</p>;
  const gradeLabel = new Map(grades.map((g) => [g.key, g.label]));
  const statusLabel: Record<string, string> = { draft: R.statusDraft, submitted: R.statusSubmitted, approved: R.statusApproved, rejected: R.statusRejected };
  const date = (s: string | null) => (s ? new Date(s).toLocaleDateString(locale === 'ar' ? 'ar' : locale, { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }) : '');
  const mushafBase = mode === 'staff' ? '/quran' : '/my/quran';

  return (
    <ul className="space-y-3">
      {items.map((r) => {
        const flagged =
          r.kind === 'teacher_test'
            ? (r.mistakes ?? []).map((m) => ({ a: m.ayah, i: m.word, s: 'mistake' }))
            : (r.auto_result?.words ?? []).filter((w) => w.s !== 'ok');
        const url = r.audio_path ? audio.get(r.audio_path) : undefined;
        return (
          <li key={r.id} className="space-y-2 rounded-lg border bg-white p-4">
            <div className="flex flex-wrap items-center gap-2">
              {mode === 'staff' && <span className="font-semibold">{r.student}</span>}
              <a href={`${mushafBase}/${r.surah}?ayah=${r.ayah_from}` as never} className="text-brand hover:underline">
                {fmt(R.ayahRange, { surah: surahLabel(r.surah, locale), from: r.ayah_from, to: r.ayah_to })}
              </a>
              <span className="text-xs text-gray-500">{typeLabels[r.type] ?? r.type}</span>
              {r.kind === 'teacher_test' && <span className="rounded bg-brand/10 px-2 py-0.5 text-xs text-brand">{R.teacherTest}</span>}
              {r.source === 'live' && <span className="rounded bg-sky-50 px-2 py-0.5 text-xs text-sky-700">{R.liveBadge}</span>}
              <span className={`ms-auto rounded px-2 py-0.5 text-xs ${STATUS_CLS[r.status]}`}>{statusLabel[r.status]}</span>
            </div>
            <p className="flex flex-wrap gap-x-4 text-xs text-gray-500">
              <span>{date(r.submitted_at ?? r.created_at)}</span>
              {mode === 'staff' && r.circle && <span>{r.circle}</span>}
              {r.kind === 'self' && (
                <span className={r.auto_score != null ? 'font-semibold text-gray-700' : ''}>
                  {r.auto_score != null ? fmt(R.autoScore, { n: r.auto_score }) : R.noAuto}
                  {r.auto_result?.words && ` · ${r.auto_result.missing ?? 0} ${R.missing} · ${r.auto_result.wrong ?? 0} ${R.wrong}`}
                </span>
              )}
              {r.kind === 'teacher_test' && <span>{fmt(R.mistakes, { n: (r.mistakes ?? []).length })}</span>}
              {r.grade && <span>{gradeLabel.get(r.grade) ?? r.grade}</span>}
              {r.reviewer && r.kind === 'self' && r.status !== 'submitted' && <span>{fmt(R.reviewedBy, { name: r.reviewer })}</span>}
            </p>
            {mode === 'staff' && r.source === 'live' && r.kind === 'self' && r.auto_score != null && (
              <p className="text-xs text-sky-700">{R.liveDeviceNote}</p>
            )}
            {url && <audio controls preload="none" src={url} className="h-9 w-full" />}
            {!r.audio_path && r.audio_deleted_at && <p className="text-xs text-gray-400">{R.audioDeleted}</p>}
            {mode === 'staff' && r.kind === 'self' && r.status === 'submitted' && !r.auto_result && <RecheckButton id={r.id} label={R.recheck} />}
            {flagged.length > 0 && <RecitationWords surah={r.surah} items={flagged} missingLabel={r.kind === 'teacher_test' ? R.markedMistakes.replace('{list}', '') : R.missingWords} wrongLabel={R.heardAs} />}
            {r.student_note && <p className="text-sm text-gray-600">{fmt(R.studentNote, { note: r.student_note })}</p>}
            {r.teacher_note && <p className="rounded bg-gray-50 px-3 py-2 text-sm">{fmt(R.teacherNote, { note: r.teacher_note })}</p>}

            {mode === 'staff' && r.status === 'submitted' && (
              <div className="grid gap-2 border-t pt-3 sm:grid-cols-2">
                <form action={reviewRecitation} className="flex flex-wrap items-center gap-2">
                  <input type="hidden" name="id" value={r.id} />
                  <input type="hidden" name="decision" value="approve" />
                  <select name="grade" required defaultValue={grades[0]?.key} className={field} aria-label={R.grade}>
                    {grades.map((g) => (
                      <option key={g.key} value={g.key}>
                        {g.label}
                      </option>
                    ))}
                  </select>
                  <select name="type" defaultValue={r.type} className={field} aria-label={R.type}>
                    {Object.entries(typeLabels).map(([k, v]) => (
                      <option key={k} value={k}>
                        {v}
                      </option>
                    ))}
                  </select>
                  <input name="note" maxLength={500} placeholder={R.testNote} className={`${field} min-w-0 flex-1`} />
                  <SubmitButton className="rounded bg-brand px-4 py-1.5 text-sm font-semibold text-white">{R.approve}</SubmitButton>
                </form>
                <form action={reviewRecitation} className="flex flex-wrap items-center gap-2">
                  <input type="hidden" name="id" value={r.id} />
                  <input type="hidden" name="decision" value="reject" />
                  <input name="note" required maxLength={500} placeholder={R.rejectNote} className={`${field} min-w-0 flex-1`} />
                  <SubmitButton className="rounded border border-red-300 px-4 py-1.5 text-sm text-red-700">{R.reject}</SubmitButton>
                </form>
              </div>
            )}
          </li>
        );
      })}
    </ul>
  );
}
