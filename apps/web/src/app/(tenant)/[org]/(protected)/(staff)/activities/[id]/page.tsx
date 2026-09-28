import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { updateActivity, deleteActivity } from '../actions';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

function toDatetimeLocal(iso: string | null) {
  return iso ? iso.slice(0, 16) : '';
}

export default async function EditActivityPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug, id } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();

  const { data: activity } = await supabase
    .from('activities')
    .select('id, title, description, scheduled_at')
    .eq('organization_id', org.id)
    .eq('id', id)
    .maybeSingle();

  if (!activity) notFound();

  return (
    <div className="max-w-lg">
      <h1 className="mb-6 text-2xl font-bold">{S.activities.editTitle}</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={updateActivity} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="id" value={activity.id} />

        <label className="text-sm font-medium text-gray-700">
          {S.activities.title}
          <input
            name="title"
            required
            defaultValue={activity.title}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.activities.description}
          <textarea
            name="description"
            rows={3}
            defaultValue={activity.description ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.activities.when}
          <input
            type="datetime-local"
            name="scheduledAt"
            defaultValue={toDatetimeLocal(activity.scheduled_at)}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText={S.common.saving}
        >
          {S.activities.saveChanges}
        </SubmitButton>
      </form>

      <form action={deleteActivity} className="mt-3">
        <input type="hidden" name="id" value={activity.id} />
        <ConfirmSubmitButton
          confirmMessage={fmt(S.activities.confirmDelete, { title: activity.title })}
          pendingText={S.common.deleting}
          className="rounded border border-red-200 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
        >
          {S.activities.deleteBtn}
        </ConfirmSubmitButton>
      </form>
    </div>
  );
}
