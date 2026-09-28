import { SubmitButton } from '@/components/submit-button';
import { saveBadge } from '@/app/(tenant)/[org]/(protected)/(staff)/badges/actions';
import { getI18n } from '@/lib/i18n/server';

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

export interface BadgeRow {
  id: string;
  name: string;
  description: string | null;
  icon: string;
  color: string;
  rule_type: string;
  threshold: number;
  param: string | null;
  duration_days: number | null;
  is_active: boolean;
  sort_order: number;
}

/** Create / edit form. `threshold` means: points / count / days / % / the juz number (1-30), per rule. */
export async function BadgeForm({
  orgId,
  badge,
  grades,
  error,
}: {
  orgId: string;
  badge?: BadgeRow;
  grades: { key: string; label: string }[];
  error?: string;
}) {
  const { t: T } = await getI18n();
  const S = T.staff;
  return (
    <form action={saveBadge} className="flex max-w-lg flex-col gap-3 rounded-lg border bg-white p-6">
      <input type="hidden" name="orgId" value={orgId} />
      {badge && <input type="hidden" name="id" value={badge.id} />}
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      <div className="grid grid-cols-[4rem_1fr_4rem] gap-3">
        <label className="text-sm font-medium text-gray-700">
          {S.badges.icon}
          <input name="icon" defaultValue={badge?.icon ?? '🏅'} className={`${field} text-center text-xl`} maxLength={4} />
        </label>
        <label className="text-sm font-medium text-gray-700">
          {S.badges.name}
          <input name="name" required defaultValue={badge?.name} className={field} />
        </label>
        <label className="text-sm font-medium text-gray-700">
          {S.badges.color}
          <input type="color" name="color" defaultValue={badge?.color ?? '#f59e0b'} className="mt-1 h-10 w-full rounded border" />
        </label>
      </div>
      <label className="text-sm font-medium text-gray-700">
        {S.badges.description}
        <textarea name="description" rows={2} defaultValue={badge?.description ?? ''} className={field} />
      </label>
      <label className="text-sm font-medium text-gray-700">
        {S.badges.rule}
        <select name="ruleType" defaultValue={badge?.rule_type ?? 'manual'} className={field}>
          {Object.entries(S.badges.rules).map(([v, l]) => (
            <option key={v} value={v}>
              {l}
            </option>
          ))}
        </select>
      </label>
      <div className="grid grid-cols-2 gap-3">
        <label className="text-sm font-medium text-gray-700">
          {S.badges.threshold}
          <input type="number" name="threshold" min={0} defaultValue={badge?.threshold ?? 0} className={field} />
        </label>
        <label className="text-sm font-medium text-gray-700">
          {S.badges.gradeParam}
          <select name="param" defaultValue={badge?.param ?? ''} className={field}>
            <option value="">—</option>
            {grades.map((g) => (
              <option key={g.key} value={g.key}>
                {g.label}
              </option>
            ))}
          </select>
        </label>
      </div>
      <p className="text-xs text-gray-500">
        {S.badges.thresholdHint}
      </p>
      <div className="grid grid-cols-2 gap-3">
        <label className="text-sm font-medium text-gray-700">
          {S.badges.duration}
          <input type="number" name="durationDays" min={1} defaultValue={badge?.duration_days ?? ''} className={field} />
        </label>
        <label className="text-sm font-medium text-gray-700">
          {S.badges.order}
          <input type="number" name="sortOrder" defaultValue={badge?.sort_order ?? 0} className={field} />
        </label>
      </div>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" name="isActive" defaultChecked={badge?.is_active ?? true} /> {S.badges.active}
      </label>
      <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText={S.common.saving}>
        {badge ? S.common.save : S.common.add}
      </SubmitButton>
    </form>
  );
}
