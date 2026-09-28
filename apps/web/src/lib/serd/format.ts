import { ar } from '@/lib/i18n/dictionaries/ar';
import { fmt } from '@/lib/i18n/config';

// Shared bits for the serd (سرد) pages. Everything the server decides (score,
// points, what is permitted) is computed in SQL; this file only names things.

export const JUZ_NAMES = [
  'آلم', 'سيقول', 'تلك الرسل', 'لن تنالوا', 'والمحصنات', 'لا يحب الله', 'وإذا سمعوا', 'ولو أننا', 'قال الملأ',
  'واعلموا', 'يعتذرون', 'وما من دابة', 'وما أبرئ', 'ربما', 'سبحان الذي', 'قال ألم', 'اقترب للناس', 'قد أفلح',
  'وقال الذين', 'أمّن خلق', 'اتل ما أوحي', 'ومن يقنت', 'وما لي', 'فمن أظلم', 'إليه يرد', 'حم', 'قال فما خطبكم',
  'قد سمع', 'تبارك الذي', 'عمّ',
];

export const DEN_NAMES: Record<number, string> = { 1: 'الجزء كاملاً', 2: 'النصف', 4: 'الربع', 8: 'الثُمن' };
const ORDINALS = ['الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع', 'الثامن'];

export const STATUS_LABELS: Record<string, string> = ar.labels.serdStatus;

export const STATUS_STYLES: Record<string, string> = {
  scheduled: 'bg-blue-50 text-blue-700',
  submitted: 'bg-amber-50 text-amber-700',
  approved: 'bg-green-50 text-green-700',
  rejected: 'bg-red-50 text-red-700',
};

export function portionLabel(den: number, index: number): string {
  return den <= 1 ? '' : `${DEN_NAMES[den] ?? ''} ${ORDINALS[index - 1] ?? ''}`.trim();
}

/** 'النصف الأول' / '1st half' - `labels` is t.labels on translated screens. */
export function portionText(den: number, index: number, labels: typeof ar.labels = ar.labels): string {
  if (labels === ar.labels) return portionLabel(den, index);
  return den <= 1 ? '' : fmt(labels.portion, { den: labels.portionDen[den] ?? '', ord: labels.portionOrd[index - 1] ?? '' });
}

/** Every amount a picker may offer given the permitted denominators (whole is always there). */
export function portionOptions(dens: number[], labels: typeof ar.labels = ar.labels): { value: string; label: string }[] {
  const out = [{ value: '1:1', label: labels.portionWhole }];
  for (const d of [2, 4, 8]) {
    if (!dens.includes(d)) continue;
    for (let i = 1; i <= d; i++) out.push({ value: `${d}:${i}`, label: portionText(d, i, labels) });
  }
  return out;
}

export interface SerdPart {
  juz: number;
  juz_name?: string;
  den: number;
  index: number;
  eighths?: number;
  label?: string;
}

export interface SerdRow {
  id: string;
  student_id: string | null;
  student_name: string;
  student_code: string | null;
  circle_name: string | null;
  circle_teacher_name: string | null;
  examiner_name: string | null;
  assigned_teacher_name: string | null;
  assigned_teacher_id: string | null;
  assigned_to_me?: boolean;
  overdue?: boolean;
  session_date: string;
  status: string;
  score_percent: number | null;
  points_awarded: number;
  pass_percent_applied: number | null;
  notes: string | null;
  reject_reason: string | null;
  parts: SerdPart[];
  total_eighths: number;
  errors: { name: string; count: number; deducted: number }[];
}

type Labels = typeof ar.labels;

/** 'جزء 3 — تلك الرسل (النصف الأول)'. `labels` is t.labels on translated screens (no juz names outside Arabic). */
export function partLabel(p: SerdPart, labels: Labels = ar.labels): string {
  const arabic = labels === ar.labels;
  const base = `${fmt(labels.juz, { n: p.juz })}${arabic && p.juz_name ? ` — ${p.juz_name}` : ''}`;
  const label = portionText(p.den, p.index, labels);
  return label ? `${base} (${label})` : base;
}

export const partsLabel = (parts: SerdPart[], labels: Labels = ar.labels) => parts.map((p) => partLabel(p, labels)).join(labels.listSep);

/** '3.5' - how much Quran an amount of eighths comes to. */
export function juzEquivalent(eighths: number): string {
  const v = eighths / 8;
  return Number.isInteger(v) ? String(v) : v.toFixed(v * 10 === Math.round(v * 10) ? 1 : 2);
}

/** Reads the parts a form posted: parallel juz[] / portion[] fields ('den:index'). */
export function readParts(formData: FormData): { juz: number; den: number; index: number }[] {
  const juz = formData.getAll('juz') as string[];
  const portion = formData.getAll('portion') as string[];
  return juz
    .map((j, i) => {
      const [den, index] = (portion[i] ?? '1:1').split(':').map(Number);
      return { juz: Number(j), den: den || 1, index: index || 1 };
    })
    .filter((p) => p.juz > 0);
}

export const fmtDate = (iso: string | null, lang = 'ar') => (iso ? new Date(iso).toLocaleDateString(lang) : '—');
