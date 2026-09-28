import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { saveGrades } from './actions';
import { getI18n } from '@/lib/i18n/server';

interface Grade {
  key: string;
  label: string;
  points: number;
  sort_order: number;
  is_active: boolean;
}

// eqraa hard-codes "excellent 20 / very good 15 / good 10 / acceptable 5".
// Here every center owns its grade names AND points; each recitation freezes
// the points it was worth when logged, so edits never change history.
export default async function PointsPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string; saved?: string }>;
}) {
  const { org: slug } = await params;
  const { error, saved } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();
  const isAdmin = org.myRole === 'admin';

  const { data } = await supabase
    .from('recitation_grades')
    .select('key, label, points, sort_order, is_active')
    .eq('organization_id', org.id)
    .order('sort_order');
  const grades = (data ?? []) as Grade[];

  return (
    <div className="max-w-2xl">
      <h1 className="mb-1 text-2xl font-bold">{S.points.title}</h1>
      <p className="mb-6 text-sm text-gray-500">
        {S.points.intro}
      </p>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {saved && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{S.points.saved}</p>}

      <form action={saveGrades} className="rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />
        <fieldset disabled={!isAdmin} className="flex flex-col gap-3">
          <div className="grid grid-cols-[1fr_6rem_5rem] gap-3 text-xs font-semibold text-gray-500">
            <span>{S.points.colName}</span>
            <span>{S.points.colPoints}</span>
            <span>{S.points.colActive}</span>
          </div>

          {grades.map((g) => (
            <div key={g.key} className="grid grid-cols-[1fr_6rem_5rem] items-center gap-3">
              <input type="hidden" name="key" value={g.key} />
              <input type="hidden" name="sort" value={g.sort_order} />
              <input name="label" defaultValue={g.label} required className="rounded border px-3 py-2 text-sm" />
              <input
                type="number"
                name="points"
                min={0}
                defaultValue={g.points}
                className="rounded border px-3 py-2 text-sm"
              />
              <input type="checkbox" name={`active_${g.key}`} defaultChecked={g.is_active} className="h-4 w-4" />
            </div>
          ))}

          <hr className="my-2" />
          <p className="text-sm font-semibold text-gray-700">{S.points.addTitle}</p>
          <div className="grid grid-cols-[1fr_1fr_6rem] gap-3">
            <input
              name="newKey"
              placeholder={S.points.keyPh}
              dir="ltr"
              className="rounded border px-3 py-2 text-sm"
            />
            <input name="newLabel" placeholder={S.points.labelPh} className="rounded border px-3 py-2 text-sm" />
            <input type="number" name="newPoints" min={0} placeholder={S.points.pointsPh} className="rounded border px-3 py-2 text-sm" />
          </div>

          {isAdmin && (
            <SubmitButton
              className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
              pendingText={S.common.saving}
            >
              {S.points.save}
            </SubmitButton>
          )}
        </fieldset>
      </form>

      {!isAdmin && <p className="mt-3 text-xs text-gray-400">{S.points.adminOnly}</p>}
    </div>
  );
}
