import { getOrgContext } from '@/lib/tenant/get-org-context';
import { SubmitButton } from '@/components/submit-button';
import { createStage } from '../actions';
import { getI18n } from '@/lib/i18n/server';

export default async function NewStagePage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;

  return (
    <div className="max-w-md">
      <h1 className="mb-6 text-2xl font-bold">{S.stages.addTitle}</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={createStage} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />

        <label className="text-sm font-medium text-gray-700">
          {S.stages.name}
          <input name="name" required placeholder={S.stages.namePh} className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.stages.code}
          <input name="code" placeholder="TM" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.stages.order}
          <input
            type="number"
            name="sortOrder"
            defaultValue={0}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText={S.common.adding}
        >
          {S.stages.submit}
        </SubmitButton>
      </form>
    </div>
  );
}
