import { SubmitButton } from '@/components/submit-button';
import { saveAnnouncement } from '@/lib/comms/actions';
import { getI18n } from '@/lib/i18n/server';

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

export async function AnnouncementForm({
  orgId,
  circles,
  isAdmin,
  item,
  error,
}: {
  orgId: string;
  circles: { id: string; name: string }[];
  isAdmin: boolean;
  item?: { id: string; title: string; body: string; audience: string; circle_id: string | null; pinned: boolean; draft: boolean; expires_on: string | null };
  error?: string;
}) {
  const { t: T } = await getI18n();
  const S = T.staff;
  return (
    <form action={saveAnnouncement} className="flex max-w-xl flex-col gap-3 rounded-lg border bg-white p-6">
      <input type="hidden" name="orgId" value={orgId} />
      <input type="hidden" name="back" value="/announcements" />
      {item && <input type="hidden" name="id" value={item.id} />}
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      <label className="text-sm font-medium text-gray-700">
        {S.annc.title}
        <input name="title" required defaultValue={item?.title} className={field} />
      </label>
      <label className="text-sm font-medium text-gray-700">
        {S.annc.body}
        <textarea name="body" required rows={5} defaultValue={item?.body} className={field} />
      </label>
      <div className="grid gap-3 sm:grid-cols-2">
        <label className="text-sm font-medium text-gray-700">
          {S.annc.audience}
          <select name="audience" defaultValue={item?.audience ?? (isAdmin ? 'all' : 'guardians')} className={field}>
            {Object.entries(T.labels.audience)
              .filter(([v]) => isAdmin || v !== 'teachers')
              .map(([v, l]) => (
                <option key={v} value={v}>
                  {l}
                </option>
              ))}
          </select>
        </label>
        <label className="text-sm font-medium text-gray-700">
          {isAdmin ? S.annc.circleOpt : S.annc.yourCircle}
          <select name="circleId" required={!isAdmin} defaultValue={item?.circle_id ?? ''} className={field}>
            {isAdmin && <option value="">{S.annc.allCircles}</option>}
            {!isAdmin && (
              <option value="" disabled>
                {S.annc.pickCircle}
              </option>
            )}
            {circles.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </label>
      </div>
      <label className="text-sm font-medium text-gray-700">
        {S.annc.expires}
        <input type="date" name="expiresOn" defaultValue={item?.expires_on ?? ''} className={field} />
      </label>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" name="pinned" defaultChecked={item?.pinned} /> {S.annc.pin}
      </label>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" name="publish" defaultChecked={item ? !item.draft : true} /> {S.annc.publish}
      </label>
      <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText={T.staff.common.saving}>
        {item ? S.common.save : S.common.add}
      </SubmitButton>
    </form>
  );
}
