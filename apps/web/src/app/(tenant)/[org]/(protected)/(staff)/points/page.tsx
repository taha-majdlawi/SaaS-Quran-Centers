import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { saveGrades } from './actions';
import { deletePointReason, recomputePoints, saveAttendancePoints, savePointReason, savePointsMode } from '@/lib/points/actions';
import { getI18n } from '@/lib/i18n/server';

interface Grade {
  key: string;
  label: string;
  points: number;
  sort_order: number;
  is_active: boolean;
}

interface Reason {
  id: string;
  name: string;
  points: number;
  kind: 'bonus' | 'penalty';
  is_active: boolean;
}

const STATUSES = ['present', 'absent', 'late', 'excused'] as const;
const input = 'rounded border px-3 py-2 text-sm';
const card = 'mb-6 rounded-lg border bg-white p-6';

// The center's points (0096): how a recitation scores (fixed per recitation, or by pages), the
// grades, attendance points, and the reasons a teacher adds or deducts for. Every recitation /
// entry keeps the points it got when recorded, so nothing here rewrites history.
export default async function PointsPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string; saved?: string; ok?: string }>;
}) {
  const { org: slug } = await params;
  const { error, saved, ok } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const P = S.points;
  const supabase = await createClient();
  const isAdmin = org.myRole === 'admin';

  const [{ data }, { data: settingRows }, { data: attRows }, { data: reasonRows }] = await Promise.all([
    supabase.from('recitation_grades').select('key, label, points, sort_order, is_active').eq('organization_id', org.id).order('sort_order'),
    supabase.from('organization_settings').select('key, value').eq('organization_id', org.id).in('key', ['points_mode', 'attendance_points_from']),
    supabase.from('attendance_point_values').select('status, points').eq('organization_id', org.id),
    supabase.from('point_reasons').select('id, name, points, kind, is_active').eq('organization_id', org.id).order('sort_order').order('created_at'),
  ]);
  const grades = (data ?? []) as Grade[];
  const settings = Object.fromEntries(((settingRows ?? []) as { key: string; value: string }[]).map((r) => [r.key, r.value]));
  const perPage = settings.points_mode === 'per_page';
  const attFrom = /^\d{4}-\d{2}-\d{2}$/.test(settings.attendance_points_from ?? '') ? settings.attendance_points_from : '';
  const attValue = Object.fromEntries(((attRows ?? []) as { status: string; points: number }[]).map((r) => [r.status, r.points]));
  const reasons = (reasonRows ?? []) as Reason[];

  return (
    <div className="max-w-3xl">
      <h1 className="mb-1 text-2xl font-bold">{P.title}</h1>
      <p className="mb-6 text-sm text-gray-500">{P.intro}</p>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {(saved || ok) && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{ok || P.saved}</p>}

      {/* how a recitation scores */}
      <form action={savePointsMode} className={card}>
        <input type="hidden" name="orgId" value={org.id} />
        <h2 className="mb-1 font-semibold">{P.modeTitle}</h2>
        <p className="mb-3 text-xs text-gray-500">{P.modeNote}</p>
        <fieldset disabled={!isAdmin} className="flex min-w-0 flex-col gap-2">
          {(
            [
              ['per_recitation', P.modePerRec, P.modePerRecHint],
              ['per_page', P.modePerPage, P.modePerPageHint],
            ] as const
          ).map(([value, label, hint]) => (
            <label key={value} className="flex cursor-pointer gap-3 rounded-lg border p-3 has-[:checked]:border-brand has-[:checked]:bg-brand/5">
              <input type="radio" name="mode" value={value} defaultChecked={(value === 'per_page') === perPage} className="mt-1" />
              <span>
                <span className="block text-sm font-semibold">{label}</span>
                <span className="block text-xs text-gray-500">{hint}</span>
              </span>
            </label>
          ))}
          <label className="mt-1 flex items-start gap-2 text-sm">
            <input type="checkbox" name="suggest" defaultChecked className="mt-1 h-4 w-4" />
            <span>
              {P.modeSuggest}
              <span className="block text-xs text-gray-500">{P.modeSuggestHint}</span>
            </span>
          </label>
          {isAdmin && (
            <SubmitButton className="mt-1 self-start rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50" pendingText={S.common.saving}>
              {P.modeSave}
            </SubmitButton>
          )}
        </fieldset>
      </form>

      {/* the grades */}
      <form action={saveGrades} className={card}>
        <input type="hidden" name="orgId" value={org.id} />
        <fieldset disabled={!isAdmin} className="flex min-w-0 flex-col gap-3">
          <div className="grid grid-cols-[1fr_6rem_4rem] gap-3 text-xs font-semibold text-gray-500">
            <span>{P.colName}</span>
            <span>{perPage ? P.colPointsPerPage : P.colPoints}</span>
            <span>{P.colActive}</span>
          </div>

          {grades.map((g) => (
            <div key={g.key} className="grid grid-cols-[1fr_6rem_4rem] items-center gap-3">
              <input type="hidden" name="key" value={g.key} />
              <input type="hidden" name="sort" value={g.sort_order} />
              <input name="label" defaultValue={g.label} required className={input} />
              <input type="number" name="points" min={0} defaultValue={g.points} className={input} />
              <input type="checkbox" name={`active_${g.key}`} defaultChecked={g.is_active} className="h-4 w-4" />
            </div>
          ))}

          <hr className="my-2" />
          <p className="text-sm font-semibold text-gray-700">{P.addTitle}</p>
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-[1fr_1fr_6rem]">
            <input name="newKey" placeholder={P.keyPh} dir="ltr" className={input} />
            <input name="newLabel" placeholder={P.labelPh} className={input} />
            <input type="number" name="newPoints" min={0} placeholder={P.pointsPh} className={input} />
          </div>

          {isAdmin && (
            <SubmitButton className="mt-2 self-start rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50" pendingText={S.common.saving}>
              {P.save}
            </SubmitButton>
          )}
        </fieldset>
      </form>

      {/* attendance */}
      <form action={saveAttendancePoints} className={card}>
        <input type="hidden" name="orgId" value={org.id} />
        <h2 className="mb-1 font-semibold">{P.attTitle}</h2>
        <p className="mb-3 text-xs text-gray-500">{P.attHint}</p>
        {!attFrom && <p className="mb-3 rounded bg-gray-50 px-3 py-2 text-xs text-gray-600">{P.attOff}</p>}
        <fieldset disabled={!isAdmin} className="flex min-w-0 flex-col gap-3">
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {STATUSES.map((st) => (
              <label key={st} className="flex flex-col gap-1 text-xs text-gray-600">
                {T.labels.attendance[st] ?? st}
                <input type="number" dir="ltr" name={st} min={-100} max={100} defaultValue={attValue[st] ?? 0} className={input} />
              </label>
            ))}
          </div>
          <label className="flex flex-col gap-1 text-xs text-gray-600 sm:max-w-xs">
            {P.attFrom}
            <input type="date" name="from" defaultValue={attFrom} className={input} />
            <span className="text-gray-400">{P.attFromHint}</span>
          </label>
          {isAdmin && (
            <SubmitButton className="self-start rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50" pendingText={S.common.saving}>
              {P.attSave}
            </SubmitButton>
          )}
        </fieldset>
      </form>

      {/* reasons to add / deduct */}
      <section className={card}>
        <h2 className="mb-1 font-semibold">{P.reasonsTitle}</h2>
        <p className="mb-4 text-xs text-gray-500">{P.reasonsHint}</p>
        <div className="grid gap-6 md:grid-cols-2">
          {(['bonus', 'penalty'] as const).map((kind) => (
            <div key={kind} className="min-w-0">
              <h3 className={`mb-2 text-sm font-semibold ${kind === 'bonus' ? 'text-green-700' : 'text-red-700'}`}>
                {kind === 'bonus' ? P.bonusTitle : P.penaltyTitle}
              </h3>
              <ul className="flex flex-col gap-2">
                {reasons
                  .filter((r) => r.kind === kind)
                  .map((r) => (
                    <li key={r.id}>
                      <form action={savePointReason} className="flex flex-wrap items-center gap-2">
                        <input type="hidden" name="orgId" value={org.id} />
                        <input type="hidden" name="id" value={r.id} />
                        <input type="hidden" name="kind" value={kind} />
                        <fieldset disabled={!isAdmin} className="contents">
                          <input name="name" defaultValue={r.name} required maxLength={60} aria-label={P.reasonName} className={`${input} min-w-0 flex-1`} />
                          <input type="number" name="points" min={1} max={100} defaultValue={r.points} aria-label={P.colPoints} className={`${input} w-16`} />
                          <input type="checkbox" name="active" defaultChecked={r.is_active} aria-label={P.colActive} title={P.colActive} className="h-4 w-4" />
                          {isAdmin && (
                            <>
                              <SubmitButton className="rounded border px-2.5 py-1.5 text-xs text-gray-700 hover:bg-gray-50">{P.saveRow}</SubmitButton>
                              <SubmitButton formAction={deletePointReason} formNoValidate className="rounded px-2 py-1.5 text-xs text-red-600 hover:bg-red-50">
                                {P.deleteRow}
                              </SubmitButton>
                            </>
                          )}
                        </fieldset>
                      </form>
                    </li>
                  ))}
              </ul>
              {isAdmin && (
                <form action={savePointReason} className="mt-3 flex flex-wrap items-center gap-2 border-t pt-3">
                  <input type="hidden" name="orgId" value={org.id} />
                  <input type="hidden" name="kind" value={kind} />
                  <input name="name" required maxLength={60} placeholder={P.reasonNew} className={`${input} min-w-0 flex-1`} />
                  <input type="number" name="points" min={1} max={100} defaultValue={2} aria-label={P.colPoints} className={`${input} w-16`} />
                  <SubmitButton className="rounded bg-brand px-3 py-1.5 text-xs font-semibold text-white">{P.saveRow}</SubmitButton>
                </form>
              )}
            </div>
          ))}
        </div>
      </section>

      {isAdmin && (
        <form action={recomputePoints} className={card}>
          <input type="hidden" name="orgId" value={org.id} />
          <h2 className="mb-1 font-semibold">{P.repairTitle}</h2>
          <p className="mb-3 text-xs text-gray-500">{P.repairHint}</p>
          <SubmitButton className="rounded border px-4 py-2 text-sm text-gray-700 hover:bg-gray-50" pendingText={S.common.saving}>
            {P.repairBtn}
          </SubmitButton>
        </form>
      )}

      {!isAdmin && <p className="mt-3 text-xs text-gray-400">{P.adminOnly}</p>}
    </div>
  );
}
