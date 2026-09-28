import { SubmitButton } from '@/components/submit-button';
import { saveChallenge } from '@/app/(tenant)/[org]/(protected)/(staff)/circle-challenges/actions';
import { getI18n } from '@/lib/i18n/server';

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

export async function ChallengeForm({
  orgId,
  challenge,
  error,
}: {
  orgId: string;
  challenge?: { id: string; title: string; description: string | null; metric: string; starts_on: string; ends_on: string };
  error?: string;
}) {
  const { t: T } = await getI18n();
  const S = T.staff;
  const today = new Date().toISOString().slice(0, 10);
  return (
    <form action={saveChallenge} className="flex max-w-lg flex-col gap-3 rounded-lg border bg-white p-6">
      <input type="hidden" name="orgId" value={orgId} />
      {challenge && <input type="hidden" name="id" value={challenge.id} />}
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      <label className="text-sm font-medium text-gray-700">
        {S.challenges.title}
        <input name="title" required defaultValue={challenge?.title} className={field} />
      </label>
      <label className="text-sm font-medium text-gray-700">
        {S.challenges.description}
        <textarea name="description" rows={2} defaultValue={challenge?.description ?? ''} className={field} />
      </label>
      <label className="text-sm font-medium text-gray-700">
        {S.challenges.metric}
        <select name="metric" defaultValue={challenge?.metric ?? 'points'} className={field}>
          {Object.entries(T.labels.metric).map(([v, l]) => (
            <option key={v} value={v}>
              {l}
            </option>
          ))}
        </select>
      </label>
      <div className="grid grid-cols-2 gap-3">
        <label className="text-sm font-medium text-gray-700">
          {S.challenges.from}
          <input type="date" name="startsOn" required defaultValue={challenge?.starts_on ?? today} className={field} />
        </label>
        <label className="text-sm font-medium text-gray-700">
          {S.challenges.to}
          <input type="date" name="endsOn" required defaultValue={challenge?.ends_on ?? today} className={field} />
        </label>
      </div>
      <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText={S.common.saving}>
        {challenge ? S.common.save : S.common.add}
      </SubmitButton>
    </form>
  );
}
