import { SubmitButton } from '@/components/submit-button';
import { METRIC_LABELS } from '@/lib/engagement/format';
import { saveChallenge } from '@/app/(tenant)/[org]/(protected)/(staff)/circle-challenges/actions';

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

export function ChallengeForm({
  orgId,
  challenge,
  error,
}: {
  orgId: string;
  challenge?: { id: string; title: string; description: string | null; metric: string; starts_on: string; ends_on: string };
  error?: string;
}) {
  const today = new Date().toISOString().slice(0, 10);
  return (
    <form action={saveChallenge} className="flex max-w-lg flex-col gap-3 rounded-lg border bg-white p-6">
      <input type="hidden" name="orgId" value={orgId} />
      {challenge && <input type="hidden" name="id" value={challenge.id} />}
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      <label className="text-sm font-medium text-gray-700">
        العنوان
        <input name="title" required defaultValue={challenge?.title} className={field} />
      </label>
      <label className="text-sm font-medium text-gray-700">
        الوصف
        <textarea name="description" rows={2} defaultValue={challenge?.description ?? ''} className={field} />
      </label>
      <label className="text-sm font-medium text-gray-700">
        المقياس
        <select name="metric" defaultValue={challenge?.metric ?? 'points'} className={field}>
          {Object.entries(METRIC_LABELS).map(([v, l]) => (
            <option key={v} value={v}>
              {l}
            </option>
          ))}
        </select>
      </label>
      <div className="grid grid-cols-2 gap-3">
        <label className="text-sm font-medium text-gray-700">
          من
          <input type="date" name="startsOn" required defaultValue={challenge?.starts_on ?? today} className={field} />
        </label>
        <label className="text-sm font-medium text-gray-700">
          إلى
          <input type="date" name="endsOn" required defaultValue={challenge?.ends_on ?? today} className={field} />
        </label>
      </div>
      <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText="جاري الحفظ...">
        {challenge ? 'حفظ' : 'إضافة'}
      </SubmitButton>
    </form>
  );
}
