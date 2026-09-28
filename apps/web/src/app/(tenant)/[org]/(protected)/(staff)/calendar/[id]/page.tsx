import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { CalendarEntryInfo } from '@/components/calendar-entry-info';
import { CONSENT_LABELS, CONSENT_STYLES, SOURCE_LABELS, type CalDetails } from '@/lib/calendar/format';
import { recordConsent, setResult, staffRegister, staffUnregister } from '../actions';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

const ROOT = process.env.NEXT_PUBLIC_ROOT_DOMAIN ?? 'bustan-alquran.com';

interface Candidate {
  student_id: string;
  student_name: string;
  student_code: string;
  circle_name: string | null;
  registered: boolean;
}

export default async function CalendarEntryPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ ok?: string; error?: string }>;
}) {
  const { org: slug, id } = await params;
  const { ok, error } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();
  const isAdmin = org.myRole === 'admin';
  const back = `/calendar/${id}`;

  const { data } = await supabase.rpc('calendar_entry_details', { p_org: org.id, p_entry: id });
  if (!data) notFound();
  const entry = data as CalDetails;

  const canRegister = entry.supports_registration && entry.registration_state !== 'ended';
  const { data: cands } = canRegister ? await supabase.rpc('entry_candidates', { p_org: org.id, p_entry: id }) : { data: [] };
  const candidates = ((cands ?? []) as Candidate[]).filter((c) => !c.registered);

  const OK_TEXT: Record<string, string> = S.cal.ok;

  return (
    <div className="max-w-4xl">
      <div className="mb-3 flex items-center justify-between">
        <a href="/calendar" className="text-sm text-brand hover:underline">
          {S.cal.back}
        </a>
        {isAdmin && (
          <a href={`/calendar/${id}/edit` as never} className="rounded border px-3 py-1 text-sm text-brand">
            {S.cal.edit}
          </a>
        )}
      </div>
      {ok && OK_TEXT[ok] && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{OK_TEXT[ok]}</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <CalendarEntryInfo entry={entry} />

      {entry.supports_registration && (
        <>
          <section className="mt-6">
            <h2 className="mb-2 font-semibold">{fmt(S.cal.participants, { n: entry.participants.length })}</h2>
            <div className="flex flex-col gap-2">
              {entry.participants.map((p) => (
                <div key={p.registration_id} className="rounded-lg border bg-white p-3 text-sm">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <div>
                      <b>{p.student_name}</b>
                      <span className="text-xs text-gray-500">
                        {' '}
                        · {p.student_code}
                        {p.circle_name && ` · ${p.circle_name}`} · {T.labels.source[p.source]}
                      </span>
                    </div>
                    {entry.requires_guardian_consent && (
                      <span className={`rounded px-2 py-0.5 text-xs ${CONSENT_STYLES[p.consent_status] ?? ''}`}>
                        {T.labels.consent[p.consent_status]}
                        {p.consent_method === 'staff' && S.cal.byPhone}
                      </span>
                    )}
                  </div>

                  {p.consent_status === 'pending' && (
                    <div className="mt-2 flex flex-wrap items-center gap-2 text-xs">
                      <span className="text-gray-500">{S.cal.consentLink}</span>
                      <code className="select-all rounded bg-gray-100 px-2 py-1" dir="ltr">
                        https://{ROOT}/consent/{p.consent_token}
                      </code>
                      {(['approved', 'declined'] as const).map((d) => (
                        <form key={d} action={recordConsent}>
                          <input type="hidden" name="registrationId" value={p.registration_id} />
                          <input type="hidden" name="decision" value={d} />
                          <input type="hidden" name="back" value={back} />
                          <SubmitButton className="rounded border px-2 py-1" pendingText="...">
                            {d === 'approved' ? S.cal.recordConsent : S.cal.recordDecline}
                          </SubmitButton>
                        </form>
                      ))}
                    </div>
                  )}

                  <div className="mt-2 flex flex-wrap items-end gap-3">
                    {isAdmin && (
                      <form action={setResult} className="flex items-end gap-2 text-xs">
                        <input type="hidden" name="registrationId" value={p.registration_id} />
                        <input type="hidden" name="back" value={back} />
                        <label className="text-gray-600">
                          {S.cal.rank}
                          <input type="number" name="rank" min={1} defaultValue={p.result_rank ?? ''} className="mt-1 block w-16 rounded border px-2 py-1" />
                        </label>
                        <label className="text-gray-600">
                          {S.cal.note}
                          <input name="note" defaultValue={p.result_note ?? ''} className="mt-1 block w-40 rounded border px-2 py-1" />
                        </label>
                        <SubmitButton className="rounded border px-2 py-1" pendingText="...">
                          {S.cal.saveResult}
                        </SubmitButton>
                      </form>
                    )}
                    {!isAdmin && p.result_rank && <span className="text-xs">{fmt(S.cal.rankIs, { n: p.result_rank })}</span>}
                    <form action={staffUnregister} className="ms-auto">
                      <input type="hidden" name="registrationId" value={p.registration_id} />
                      <input type="hidden" name="back" value={back} />
                      <ConfirmSubmitButton confirmMessage={S.cal.unregisterConfirm} pendingText="..." className="rounded border border-red-200 px-2 py-1 text-xs text-red-600">
                        {S.cal.unregister}
                      </ConfirmSubmitButton>
                    </form>
                  </div>
                </div>
              ))}
              {!entry.participants.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">{S.cal.noParticipants}</p>}
            </div>
          </section>

          {entry.waitlist.length > 0 && (
            <section className="mt-6">
              <h2 className="mb-2 font-semibold">{fmt(S.cal.waitlist, { n: entry.waitlist.length })}</h2>
              <ol className="list-decimal rounded-lg border bg-white p-3 ps-8 text-sm">
                {entry.waitlist.map((w) => (
                  <li key={w.student_id}>{w.student_name}</li>
                ))}
              </ol>
              <p className="mt-1 text-xs text-gray-500">{S.cal.promoteHint}</p>
            </section>
          )}

          {canRegister && candidates.length > 0 && (
            <section className="mt-6">
              <h2 className="mb-2 font-semibold">{S.cal.registerStudent}</h2>
              <form action={staffRegister} className="flex flex-wrap items-end gap-2 rounded-lg border bg-white p-3">
                <input type="hidden" name="orgId" value={org.id} />
                <input type="hidden" name="entryId" value={id} />
                <input type="hidden" name="back" value={back} />
                <select name="studentId" required defaultValue="" className="min-w-64 rounded border px-3 py-2 text-sm">
                  <option value="" disabled>
                    {S.cal.pickStudent}
                  </option>
                  {candidates.map((c) => (
                    <option key={c.student_id} value={c.student_id}>
                      {c.student_name} ({c.student_code}){c.circle_name ? ` — ${c.circle_name}` : ''}
                    </option>
                  ))}
                </select>
                <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText="...">
                  {S.cal.register}
                </SubmitButton>
              </form>
            </section>
          )}
        </>
      )}
    </div>
  );
}
