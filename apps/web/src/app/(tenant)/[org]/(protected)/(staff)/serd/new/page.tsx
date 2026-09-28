import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { SerdPartsFields } from '@/components/serd-parts-fields';
import { partsLabel, type SerdRow } from '@/lib/serd/format';
import { submitSerd } from '../actions';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

interface Setup {
  pass_percent: number;
  default_denominators: number[];
  error_types: { id: string; name: string; errors_per_unit: number; percent_per_unit: number; is_active: boolean }[];
  stages: { denominators: number[] }[];
}

export default async function NewSerdPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string; session?: string }>;
}) {
  const { org: slug } = await params;
  const { error, session } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();

  const [{ data: setupData }, { data: students }, { data: scheduled }] = await Promise.all([
    supabase.rpc('serd_grading_setup', { p_org: org.id }),
    supabase.from('students_profile').select('id, full_name, student_code').eq('organization_id', org.id).order('full_name'),
    session ? supabase.rpc('teacher_scheduled_serd', { p_org: org.id }) : Promise.resolve({ data: [] }),
  ]);
  const setup = setupData as Setup | null;
  const task = ((scheduled ?? []) as SerdRow[]).find((s) => s.id === session);

  // The picker offers every amount any stage may use; the server re-checks the
  // student's own stage when it grades.
  const dens = Array.from(
    new Set([1, ...(setup?.default_denominators ?? []), ...(setup?.stages ?? []).flatMap((s) => s.denominators)]),
  );
  const today = new Date().toISOString().slice(0, 10);

  return (
    <div className="max-w-2xl">
      <a href="/serd" className="text-sm text-brand hover:underline">
        {S.serd.back}
      </a>
      <h1 className="mb-1 mt-2 text-2xl font-bold">{task ? S.serd.recordScheduled : S.serd.recordNew}</h1>
      {task && (
        <p className="mb-4 text-sm text-gray-600">
          {task.student_name} — {partsLabel(task.parts, T.labels)}
        </p>
      )}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={submitSerd} className="flex flex-col gap-4 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />
        {task && <input type="hidden" name="sessionId" value={task.id} />}

        {task ? (
          <input type="hidden" name="studentId" value={task.student_id ?? ''} />
        ) : (
          <>
            <label className="text-sm font-medium text-gray-700">
              {S.serd.student}
              <select name="studentId" defaultValue="" className={field}>
                <option value="">{S.serd.outsider}</option>
                {(students ?? []).map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.full_name} ({s.student_code})
                  </option>
                ))}
              </select>
            </label>
            <label className="text-sm font-medium text-gray-700">
              {S.serd.outsiderName}
              <input name="studentName" className={field} />
            </label>
          </>
        )}

        <label className="text-sm font-medium text-gray-700">
          {S.serd.date}
          <input type="date" name="date" defaultValue={today} max={today} className={field} />
        </label>

        <div>
          <p className="mb-1 text-sm font-medium text-gray-700">{S.serd.parts}</p>
          <SerdPartsFields denominators={dens} initial={task?.parts} />
        </div>

        <fieldset>
          <legend className="mb-1 text-sm font-medium text-gray-700">{S.serd.errors}</legend>
          <div className="grid gap-2 sm:grid-cols-2">
            {(setup?.error_types ?? [])
              .filter((t) => t.is_active)
              .map((t) => (
                <label key={t.id} className="flex items-center justify-between gap-3 rounded border px-3 py-2 text-sm">
                  <span>
                    {t.name}
                    <span className="block text-xs text-gray-500">
                      {fmt(S.serd.perUnit, { n: t.errors_per_unit, p: t.percent_per_unit })}
                    </span>
                  </span>
                  <input
                    type="number"
                    min={0}
                    defaultValue={0}
                    name={`err_${t.id}`}
                    className="w-20 rounded border px-2 py-1 text-center"
                  />
                </label>
              ))}
          </div>
          <p className="mt-2 text-xs text-gray-500">
            {fmt(S.serd.scoreHint, { n: setup?.pass_percent ?? 80 })}
          </p>
        </fieldset>

        <label className="text-sm font-medium text-gray-700">
          {S.serd.notesOptional}
          <textarea name="notes" rows={2} defaultValue={task?.notes ?? ''} className={field} />
        </label>

        <SubmitButton
          className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText={S.serd.sending}
        >
          {S.serd.submit}
        </SubmitButton>
      </form>
    </div>
  );
}
