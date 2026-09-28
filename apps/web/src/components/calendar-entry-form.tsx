import { SubmitButton } from '@/components/submit-button';
import { type CalEntry, type CalType } from '@/lib/calendar/format';
import { saveEntry } from '@/app/(tenant)/[org]/(protected)/(staff)/calendar/actions';
import { getI18n } from '@/lib/i18n/server';

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

/** Create / edit form for one calendar entry (admin). */
export async function CalendarEntryForm({
  orgId,
  types,
  circles,
  stages,
  entry,
  defaultDate,
  error,
}: {
  orgId: string;
  types: CalType[];
  circles: { id: string; name: string }[];
  stages: { id: string; name: string }[];
  entry?: CalEntry;
  defaultDate?: string;
  error?: string;
}) {
  const today = defaultDate ?? new Date().toISOString().slice(0, 10);
  const { t: T } = await getI18n();
  const S = T.staff;
  return (
    <form action={saveEntry} className="flex max-w-2xl flex-col gap-4 rounded-lg border bg-white p-6">
      <input type="hidden" name="orgId" value={orgId} />
      {entry && <input type="hidden" name="id" value={entry.id} />}
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <label className="text-sm font-medium text-gray-700">
        {S.cal.fType}
        <select name="typeId" required defaultValue={entry?.type_id ?? ''} className={field}>
          <option value="" disabled>
            {S.cal.pickType}
          </option>
          {types
            .filter((t) => t.is_active || t.id === entry?.type_id)
            .map((t) => (
              <option key={t.id} value={t.id}>
                {t.name}
                {t.supports_registration ? S.cal.withReg : ''}
                {!t.default_is_working ? S.cal.notWorking : ''}
              </option>
            ))}
        </select>
      </label>

      <label className="text-sm font-medium text-gray-700">
        {S.cal.fTitle}
        <input name="title" required defaultValue={entry?.title} className={field} />
      </label>
      <label className="text-sm font-medium text-gray-700">
        {S.cal.fDescription}
        <textarea name="description" rows={3} defaultValue={entry?.description ?? ''} className={field} />
      </label>

      <div className="grid grid-cols-3 gap-3">
        <label className="text-sm font-medium text-gray-700">
          {S.cal.fFrom}
          <input type="date" name="startDate" required defaultValue={entry?.start_date ?? today} className={field} />
        </label>
        <label className="text-sm font-medium text-gray-700">
          {S.cal.fTo}
          <input type="date" name="endDate" defaultValue={entry?.end_date ?? ''} className={field} />
        </label>
        <label className="text-sm font-medium text-gray-700">
          {S.cal.fTime}
          <input type="time" name="startsAt" defaultValue={entry?.starts_at?.slice(0, 5) ?? ''} className={field} />
        </label>
      </div>
      <label className="text-sm font-medium text-gray-700">
        {S.cal.fPlace}
        <input name="location" defaultValue={entry?.location ?? ''} className={field} />
      </label>

      <fieldset className="rounded border p-3">
        <legend className="px-1 text-sm font-medium text-gray-700">{S.cal.whoSees}</legend>
        <div className="grid gap-3 sm:grid-cols-3">
          <label className="text-sm text-gray-700">
            {S.cal.fAudience}
            <select name="audience" defaultValue={entry?.audience ?? 'all'} className={field}>
              {Object.entries(T.labels.audience).map(([v, l]) => (
                <option key={v} value={v}>
                  {l}
                </option>
              ))}
            </select>
          </label>
          <label className="text-sm text-gray-700">
            {S.cal.fCircle}
            <select name="circleId" defaultValue={entry?.circle_id ?? ''} className={field}>
              <option value="">{S.cal.allCircles}</option>
              {circles.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </label>
          <label className="text-sm text-gray-700">
            {S.cal.fStage}
            <select name="stageId" defaultValue={entry?.stage_id ?? ''} className={field}>
              <option value="">{S.cal.allStages}</option>
              {stages.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name}
                </option>
              ))}
            </select>
          </label>
        </div>
      </fieldset>

      <fieldset className="rounded border p-3">
        <legend className="px-1 text-sm font-medium text-gray-700">{S.cal.fWork}</legend>
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" name="workingOverride" defaultChecked={false} /> {S.cal.override}
        </label>
        <label className="mt-2 flex items-center gap-2 text-sm">
          <input type="checkbox" name="isWorkingDay" defaultChecked={entry?.is_working_day ?? true} /> {S.cal.workDay}
        </label>
        <p className="mt-1 text-xs text-gray-500">
          {S.cal.workHint}
        </p>
      </fieldset>

      <fieldset className="rounded border p-3">
        <legend className="px-1 text-sm font-medium text-gray-700">{S.cal.fReg}</legend>
        <div className="grid gap-3 sm:grid-cols-3">
          <label className="text-sm text-gray-700">
            {S.cal.seats}
            <input type="number" name="capacity" min={1} defaultValue={entry?.capacity ?? ''} placeholder={S.cal.noLimit} className={field} />
          </label>
          <label className="text-sm text-gray-700">
            {S.cal.closeOn}
            <input type="date" name="deadline" defaultValue={entry?.registration_deadline ?? ''} className={field} />
          </label>
          <label className="flex items-end gap-2 pb-2 text-sm text-gray-700">
            <input type="checkbox" name="registrationOpen" defaultChecked={entry?.registration_open ?? true} /> {S.cal.regOpen}
          </label>
        </div>
      </fieldset>

      <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50" pendingText={S.common.saving}>
        {entry ? S.cal.saveChanges : S.common.add}
      </SubmitButton>
    </form>
  );
}
