import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { CalendarEntryInfo } from '@/components/calendar-entry-info';
import { CONSENT_LABELS, CONSENT_STYLES, type CalDetails } from '@/lib/calendar/format';
import { familyJoinWaitlist, familyLeaveWaitlist, familyRegister, familyUnregister } from '../actions';

const ROOT = process.env.NEXT_PUBLIC_ROOT_DOMAIN ?? 'bustan-alquran.com';

const OK_TEXT: Record<string, string> = {
  registered: 'تم التسجيل ✓',
  removed: 'أُلغي التسجيل',
  waiting: 'أُضيف إلى قائمة الانتظار ✓',
  left: 'خرج من قائمة الانتظار',
};

export default async function MyCalendarEntryPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ ok?: string; error?: string }>;
}) {
  const { org: slug, id } = await params;
  const { ok, error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const back = `/my/calendar/${id}`;

  const { data } = await supabase.rpc('calendar_entry_details', { p_org: org.id, p_entry: id });
  if (!data) notFound();
  const entry = data as CalDetails;
  const state = entry.registration_state;

  const hidden = (studentId: string) => (
    <>
      <input type="hidden" name="orgId" value={org.id} />
      <input type="hidden" name="entryId" value={id} />
      <input type="hidden" name="studentId" value={studentId} />
      <input type="hidden" name="back" value={back} />
    </>
  );

  return (
    <div className="mx-auto max-w-3xl p-6">
      <a href="/my/calendar" className="text-sm text-brand hover:underline">
        ← التقويم
      </a>
      <div className="mt-2 flex flex-col gap-4">
        {ok && OK_TEXT[ok] && <p className="rounded bg-green-50 px-3 py-2 text-sm text-green-700">{OK_TEXT[ok]}</p>}
        {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
        <CalendarEntryInfo entry={entry} />

        {entry.supports_registration && (
          <section className="flex flex-col gap-2">
            {entry.mine.map((m) => (
              <div key={m.student_id} className="rounded-lg border bg-white p-4 text-sm">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <b>{m.student_name}</b>
                  {m.registration_id ? (
                    <span className="rounded bg-green-50 px-2 py-0.5 text-xs text-green-700">مسجّل ✓</span>
                  ) : m.waiting ? (
                    <span className="rounded bg-amber-50 px-2 py-0.5 text-xs text-amber-700">في قائمة الانتظار</span>
                  ) : null}
                </div>

                {m.registration_id && entry.requires_guardian_consent && (
                  <div className="mt-2 text-xs">
                    <span className={`rounded px-2 py-0.5 ${CONSENT_STYLES[m.consent_status ?? ''] ?? ''}`}>
                      موافقة ولي الأمر: {CONSENT_LABELS[m.consent_status ?? 'not_required']}
                    </span>
                    {m.consent_status === 'pending' && (
                      <p className="mt-2 text-gray-600">
                        أرسل هذا الرابط لولي الأمر ليوافق:
                        <code className="mr-1 select-all rounded bg-gray-100 px-2 py-1" dir="ltr">
                          https://{ROOT}/consent/{m.consent_token}
                        </code>
                      </p>
                    )}
                  </div>
                )}
                {m.result_rank && (
                  <p className="mt-2 text-xs">
                    النتيجة: الترتيب {m.result_rank}
                    {m.result_note && ` — ${m.result_note}`}
                  </p>
                )}

                <div className="mt-3 flex flex-wrap gap-2">
                  {m.registration_id ? (
                    (m.source === 'self' || m.source === 'guardian') && state !== 'ended' ? (
                      <form action={familyUnregister}>
                        <input type="hidden" name="registrationId" value={m.registration_id} />
                        <input type="hidden" name="back" value={back} />
                        <SubmitButton className="rounded border border-red-200 px-3 py-1.5 text-red-600" pendingText="...">
                          إلغاء التسجيل
                        </SubmitButton>
                      </form>
                    ) : (
                      <span className="text-xs text-gray-500">سجّله المعلم أو المشرف — للإلغاء تواصل معه</span>
                    )
                  ) : state === 'open' ? (
                    <form action={familyRegister}>
                      {hidden(m.student_id)}
                      <SubmitButton className="rounded bg-brand px-3 py-1.5 font-semibold text-white" pendingText="...">
                        تسجيل
                      </SubmitButton>
                    </form>
                  ) : state === 'full' && !m.waiting ? (
                    <form action={familyJoinWaitlist}>
                      {hidden(m.student_id)}
                      <SubmitButton className="rounded border px-3 py-1.5 text-brand" pendingText="...">
                        انضم لقائمة الانتظار
                      </SubmitButton>
                    </form>
                  ) : m.waiting ? (
                    <form action={familyLeaveWaitlist}>
                      {hidden(m.student_id)}
                      <SubmitButton className="rounded border px-3 py-1.5" pendingText="...">
                        اخرج من قائمة الانتظار
                      </SubmitButton>
                    </form>
                  ) : null}
                </div>
              </div>
            ))}
          </section>
        )}
      </div>
    </div>
  );
}
