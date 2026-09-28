'use server';

import { createClient } from '@/lib/supabase/server';
import { parseCsv } from '@/lib/csv';
import { staffStrings } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

export interface ImportState {
  created: number;
  errors: string[];
}

const ALIASES: Record<string, string[]> = {
  name: ['name', 'full_name', 'fullname', 'الاسم', 'اسم الطالب'],
  circle: ['circle', 'الحلقة', 'حلقة'],
  code: ['code', 'student_code', 'الرقم', 'رقم الطالب', 'الكود'],
  birth: ['birth_date', 'birth', 'تاريخ الميلاد', 'الميلاد'],
  phone: ['phone', 'الهاتف', 'الجوال', 'رقم الهاتف'],
  whatsapp: ['whatsapp', 'واتساب', 'الواتساب'],
  address: ['address', 'العنوان'],
};
const MAX_ROWS = 500;

export async function importStudents(_prev: ImportState | null, formData: FormData): Promise<ImportState> {
  const orgId = (formData.get('orgId') as string) ?? '';
  const I = (await staffStrings()).studentsImport;
  const file = formData.get('file');
  const pasted = ((formData.get('csv') as string) ?? '').trim();
  const text = file instanceof File && file.size > 0 ? await file.text() : pasted;
  if (!text) return { created: 0, errors: [I.eEmpty] };

  const rows = parseCsv(text);
  if (rows.length < 2) return { created: 0, errors: [I.eShort] };
  if (rows.length - 1 > MAX_ROWS) return { created: 0, errors: [fmt(I.eMax, { n: MAX_ROWS })] };

  const header = rows[0].map((h) => h.trim().toLowerCase());
  const col = (key: string) => header.findIndex((h) => ALIASES[key].includes(h));
  const idx = Object.fromEntries(Object.keys(ALIASES).map((k) => [k, col(k)]));
  if (idx.name < 0) return { created: 0, errors: [I.eNoName] };

  const supabase = await createClient();
  const { data: circles } = await supabase.from('circles').select('id, name, stage_id').eq('organization_id', orgId);
  const byName = new Map((circles ?? []).map((c) => [(c.name as string).trim().toLowerCase(), c]));

  let created = 0;
  const errors: string[] = [];
  for (let i = 1; i < rows.length; i++) {
    const r = rows[i];
    const get = (k: string) => (idx[k] >= 0 ? (r[idx[k]] ?? '').trim() : '');
    const line = i + 1;
    const name = get('name');
    if (!name) {
      errors.push(fmt(I.eBlank, { line }));
      continue;
    }
    const circle = get('circle') ? byName.get(get('circle').toLowerCase()) : undefined;
    if (get('circle') && !circle) {
      errors.push(fmt(I.eCircle, { line, name, circle: get('circle') }));
      continue;
    }
    if (!circle) {
      errors.push(fmt(I.eNeedCircle, { line, name }));
      continue;
    }
    let code = get('code');
    if (!code) {
      const { data: next, error: codeError } = await supabase.rpc('next_student_code', { org_id: orgId, target_stage_id: circle.stage_id });
      if (codeError || !next) {
        errors.push(fmt(I.eCode, { line, name }));
        continue;
      }
      code = next as string;
    }
    const birth = get('birth');
    if (birth && !/^\d{4}-\d{2}-\d{2}$/.test(birth)) {
      errors.push(fmt(I.eBirth, { line, name }));
      continue;
    }
    const { error } = await supabase.from('students_profile').insert({
      organization_id: orgId,
      full_name: name,
      student_code: code,
      circle_id: circle.id,
      birth_date: birth || null,
      phone: get('phone') || null,
      whatsapp: get('whatsapp') || null,
      address: get('address') || null,
    });
    if (error) {
      errors.push(fmt(I.eRow, { line, name, error: error.code === '23505' ? I.eTaken : error.message }));
      // a plan limit / permission problem will repeat for every row: stop early
      if (/الحد الأقصى|حساب عرض|row-level/.test(error.message)) break;
      continue;
    }
    created++;
  }
  return { created, errors: errors.slice(0, 50) };
}
