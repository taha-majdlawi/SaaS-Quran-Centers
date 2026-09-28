'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { safeBack, withParam } from '@/lib/calendar/actions-shared';
import { staffStrings } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

const s = (formData: FormData, key: string) => ((formData.get(key) as string) ?? '').trim();

async function run(back: string, fn: string, args: Record<string, unknown>, ok: string | ((data: unknown) => string)): Promise<never> {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc(fn, args);
  if (error) redirect(withParam(back, 'error', error.message) as never);
  redirect(withParam(back, 'ok', typeof ok === 'function' ? ok(data) : ok) as never);
}

// ---- gatherings ----------------------------------------------------------

export async function submitGathering(formData: FormData) {
  const names = s(formData, 'names')
    .split(/\r?\n|،|,/)
    .map((n) => n.trim())
    .filter(Boolean);
  const G = (await staffStrings()).gather;
  await run('/gatherings', 'submit_gathering', {
    p_org: s(formData, 'orgId'),
    p_title: s(formData, 'title'),
    p_type: s(formData, 'type') || null,
    p_date: s(formData, 'date') || null,
    p_location: s(formData, 'location') || null,
    p_notes: s(formData, 'notes') || null,
    p_names: names,
  }, (d) => fmt(G.okUploaded, { n: (d as { names_count: number }).names_count }));
}

export async function deleteGathering(formData: FormData) {
  await run('/gatherings', 'delete_gathering', { p_id: s(formData, 'id') }, (await staffStrings()).gather.okDeleted);
}

export async function updateGathering(formData: FormData) {
  const id = s(formData, 'id');
  await run(`/gatherings/${id}`, 'admin_update_gathering', {
    p_id: id,
    p_title: s(formData, 'title'),
    p_type: s(formData, 'type') || null,
    p_date: s(formData, 'date'),
    p_location: s(formData, 'location') || null,
    p_notes: s(formData, 'notes') || null,
  }, (await staffStrings()).gather.okSaved);
}

export async function addGatheringEntry(formData: FormData) {
  const id = s(formData, 'gatheringId');
  await run(`/gatherings/${id}`, 'gathering_add_entry', { p_gathering: id, p_name: s(formData, 'name') }, (await staffStrings()).gather.okNameAdded);
}

export async function deleteGatheringEntry(formData: FormData) {
  await run(safeBack(formData.get('back'), '/gatherings'), 'gathering_delete_entry', { p_entry: s(formData, 'entryId') }, (await staffStrings()).gather.okNameDeleted);
}

export async function matchGatheringEntry(formData: FormData) {
  const back = safeBack(formData.get('back'), '/gatherings');
  const G = (await staffStrings()).gather;
  await run(back, 'admin_match_gathering_entry', { p_entry: s(formData, 'entryId'), p_student: s(formData, 'studentId') }, (d) => {
    const r = d as { center_attendance: boolean; note: string | null };
    return r.center_attendance ? G.okLinkedAttended : (r.note ?? G.okLinked);
  });
}

export async function skipGatheringEntry(formData: FormData) {
  await run(safeBack(formData.get('back'), '/gatherings'), 'admin_skip_gathering_entry', { p_entry: s(formData, 'entryId') }, (await staffStrings()).gather.okSkipped);
}

export async function unmatchGatheringEntry(formData: FormData) {
  await run(safeBack(formData.get('back'), '/gatherings'), 'admin_unmatch_gathering_entry', { p_entry: s(formData, 'entryId') }, (d) => String(d));
}

// ---- external recitations --------------------------------------------------

export async function submitExternalRecitation(formData: FormData) {
  await run('/external-recitations', 'submit_external_recitation', {
    p_org: s(formData, 'orgId'),
    p_name: s(formData, 'name'),
    p_type: s(formData, 'type'),
    p_surah: Number(s(formData, 'surah')),
    p_from: Number(s(formData, 'ayahFrom')),
    p_to: Number(s(formData, 'ayahTo')),
    p_grade: s(formData, 'grade'),
    p_notes: s(formData, 'notes') || null,
    p_recorded_at: null,
    p_client_ref: s(formData, 'clientRef') || null,
  }, (await staffStrings()).extRec.okUploaded);
}

export async function deleteExternalRecitation(formData: FormData) {
  await run('/external-recitations', 'delete_external_recitation', { p_id: s(formData, 'id') }, (await staffStrings()).extRec.okDeleted);
}

export async function matchExternalRecitation(formData: FormData) {
  const X = (await staffStrings()).extRec;
  await run('/external-recitations', 'admin_match_external_recitation', { p_id: s(formData, 'id'), p_student: s(formData, 'studentId') },
    (d) => fmt(X.okLinked, { n: (d as { points_awarded: number }).points_awarded }));
}

export async function rejectExternalRecitation(formData: FormData) {
  await run('/external-recitations', 'admin_reject_external_recitation', { p_id: s(formData, 'id'), p_reason: s(formData, 'reason') || null }, (await staffStrings()).extRec.okRejected);
}
