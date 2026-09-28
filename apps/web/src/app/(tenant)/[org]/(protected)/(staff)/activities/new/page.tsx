import { getOrgContext } from '@/lib/tenant/get-org-context';
import { SubmitButton } from '@/components/submit-button';
import { createActivity } from '../actions';
import { getI18n } from '@/lib/i18n/server';

export default async function NewActivityPage({
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
    <div className="max-w-lg">
      <h1 className="mb-6 text-2xl font-bold">{S.activities.newTitle}</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={createActivity} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />

        <label className="text-sm font-medium text-gray-700">
          {S.activities.title}
          <input name="title" required className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.activities.description}
          <textarea name="description" rows={3} className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.activities.when}
          <input type="datetime-local" name="scheduledAt" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText={S.common.adding}
        >
          {S.activities.addBtn}
        </SubmitButton>
      </form>
    </div>
  );
}
