import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { DEN_NAMES } from '@/lib/serd/format';
import { deleteErrorType, saveErrorType, saveSerdSettings, saveStagePolicy } from '../actions';
import { getI18n } from '@/lib/i18n/server';

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

interface Setup {
  pass_percent: number;
  points_per_juz: number;
  default_denominators: number[];
  error_types: { id: string; name: string; errors_per_unit: number; percent_per_unit: number; is_active: boolean }[];
  stages: { stage_id: string; denominators: number[]; pass_percent: number | null }[];
}

async function Denominators({ selected }: { selected: number[] }) {
  const { t: T } = await getI18n();
  const S = T.staff;
  return (
    <div className="flex flex-wrap gap-3 text-sm">
      <span className="rounded border bg-gray-50 px-3 py-1.5 text-gray-500">{S.serd.wholeAlways}</span>
      {[2, 4, 8].map((d) => (
        <label key={d} className="flex items-center gap-1 rounded border px-3 py-1.5">
          <input type="checkbox" name="den" value={d} defaultChecked={selected.includes(d)} /> {T.labels.portionDen[d] ?? DEN_NAMES[d]}
        </label>
      ))}
    </div>
  );
}

export default async function SerdSettingsPage({
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

  const [{ data }, { data: stages }] = await Promise.all([
    supabase.rpc('serd_grading_setup', { p_org: org.id }),
    supabase.from('stages').select('id, name').eq('organization_id', org.id).order('name'),
  ]);
  const setup = data as Setup | null;
  const policyByStage = new Map((setup?.stages ?? []).map((s) => [s.stage_id, s]));

  return (
    <div className="max-w-3xl">
      <a href="/serd" className="text-sm text-brand hover:underline">
        {S.serd.back}
      </a>
      <h1 className="mb-1 mt-2 text-2xl font-bold">{S.serd.settingsTitle}</h1>
      <p className="mb-6 text-sm text-gray-500">
        {S.serd.settingsIntro}
      </p>
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {saved && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{S.serd.savedOk}</p>}

      <form action={saveSerdSettings} className="mb-8 flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />
        <h2 className="font-semibold">{S.serd.general}</h2>
        <div className="grid grid-cols-2 gap-3">
          <label className="text-sm font-medium text-gray-700">
            {S.serd.passPercent}
            <input type="number" name="passPercent" min={0} max={100} step="0.5" defaultValue={setup?.pass_percent ?? 80} className={field} />
          </label>
          <label className="text-sm font-medium text-gray-700">
            {S.serd.pointsPerJuz}
            <input type="number" name="pointsPerJuz" min={0} defaultValue={setup?.points_per_juz ?? 50} className={field} />
          </label>
        </div>
        <p className="text-xs text-gray-500">{S.serd.pointsHint}</p>
        <div>
          <p className="mb-1 text-sm font-medium text-gray-700">{S.serd.defaultAmounts}</p>
          <Denominators selected={setup?.default_denominators ?? [1]} />
        </div>
        <SubmitButton className="self-start rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText={S.common.saving}>
          {S.common.save}
        </SubmitButton>
      </form>

      <section className="mb-8 rounded-lg border bg-white p-6">
        <h2 className="mb-1 font-semibold">{S.serd.errorTypes}</h2>
        <p className="mb-4 text-xs text-gray-500">{S.serd.errorExample}</p>
        <div className="flex flex-col gap-3">
          {(setup?.error_types ?? []).map((t, i) => (
            <div key={t.id} className="flex flex-wrap items-end gap-2 rounded bg-gray-50 p-3">
              <form action={saveErrorType} className="flex flex-wrap items-end gap-2">
                <input type="hidden" name="orgId" value={org.id} />
                <input type="hidden" name="id" value={t.id} />
                <input type="hidden" name="sortOrder" value={i + 1} />
                <label className="text-xs text-gray-600">
                  {S.serd.name}
                  <input name="name" defaultValue={t.name} required className="mt-1 block w-44 rounded border px-2 py-1.5 text-sm" />
                </label>
                <label className="text-xs text-gray-600">
                  {S.serd.every}
                  <input type="number" name="errorsPerUnit" min={1} defaultValue={t.errors_per_unit} className="mt-1 block w-20 rounded border px-2 py-1.5 text-sm" />
                </label>
                <label className="text-xs text-gray-600">
                  {S.serd.deduct}
                  <input type="number" name="percentPerUnit" min={0} max={100} step="0.25" defaultValue={t.percent_per_unit} className="mt-1 block w-20 rounded border px-2 py-1.5 text-sm" />
                </label>
                <label className="flex items-center gap-1 pb-1.5 text-xs text-gray-600">
                  <input type="checkbox" name="isActive" defaultChecked={t.is_active} /> {S.serd.active}
                </label>
                <SubmitButton className="rounded border px-3 py-1.5 text-sm text-brand" pendingText="...">
                  {S.common.save}
                </SubmitButton>
              </form>
              <form action={deleteErrorType}>
                <input type="hidden" name="orgId" value={org.id} />
                <input type="hidden" name="id" value={t.id} />
                <ConfirmSubmitButton
                  confirmMessage={S.serd.deleteErrorConfirm}
                  pendingText="..."
                  className="rounded border border-red-200 px-3 py-1.5 text-sm text-red-600"
                >
                  {S.common.delete}
                </ConfirmSubmitButton>
              </form>
            </div>
          ))}
        </div>

        <form action={saveErrorType} className="mt-4 flex flex-wrap items-end gap-2 border-t pt-4">
          <input type="hidden" name="orgId" value={org.id} />
          <input type="hidden" name="isActive" value="on" />
          <input type="hidden" name="sortOrder" value={(setup?.error_types.length ?? 0) + 1} />
          <label className="text-xs text-gray-600">
            {S.serd.newType}
            <input name="name" required placeholder={S.serd.newTypePh} className="mt-1 block w-44 rounded border px-2 py-1.5 text-sm" />
          </label>
          <label className="text-xs text-gray-600">
            {S.serd.every}
            <input type="number" name="errorsPerUnit" min={1} defaultValue={3} className="mt-1 block w-20 rounded border px-2 py-1.5 text-sm" />
          </label>
          <label className="text-xs text-gray-600">
            {S.serd.deduct}
            <input type="number" name="percentPerUnit" min={0} max={100} step="0.25" defaultValue={1} className="mt-1 block w-20 rounded border px-2 py-1.5 text-sm" />
          </label>
          <SubmitButton className="rounded bg-brand px-3 py-1.5 text-sm font-semibold text-white" pendingText="...">
            {S.common.add}
          </SubmitButton>
        </form>
      </section>

      <section className="rounded-lg border bg-white p-6">
        <h2 className="mb-1 font-semibold">{S.serd.byStage}</h2>
        <p className="mb-4 text-xs text-gray-500">
          {S.serd.byStageHint}
        </p>
        <div className="flex flex-col gap-3">
          {(stages ?? []).map((st) => {
            const p = policyByStage.get(st.id);
            return (
              <form key={st.id} action={saveStagePolicy} className="flex flex-col gap-2 rounded bg-gray-50 p-3">
                <input type="hidden" name="orgId" value={org.id} />
                <input type="hidden" name="stageId" value={st.id} />
                <p className="text-sm font-semibold">{st.name}</p>
                <Denominators selected={p?.denominators ?? []} />
                <div className="flex items-end gap-2">
                  <label className="text-xs text-gray-600">
                    {S.serd.stagePass}
                    <input type="number" name="passPercent" min={0} max={100} step="0.5" defaultValue={p?.pass_percent ?? ''} className="mt-1 block w-24 rounded border px-2 py-1.5 text-sm" />
                  </label>
                  <SubmitButton className="rounded border px-3 py-1.5 text-sm text-brand" pendingText="...">
                    {S.common.save}
                  </SubmitButton>
                </div>
              </form>
            );
          })}
          {!stages?.length && <p className="text-sm text-gray-400">{S.serd.noStages}</p>}
        </div>
      </section>
    </div>
  );
}
