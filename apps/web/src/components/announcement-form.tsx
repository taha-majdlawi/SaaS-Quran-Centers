import { SubmitButton } from '@/components/submit-button';
import { AUDIENCE_LABELS } from '@/lib/calendar/format';
import { saveAnnouncement } from '@/lib/comms/actions';

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

export function AnnouncementForm({
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
  return (
    <form action={saveAnnouncement} className="flex max-w-xl flex-col gap-3 rounded-lg border bg-white p-6">
      <input type="hidden" name="orgId" value={orgId} />
      <input type="hidden" name="back" value="/announcements" />
      {item && <input type="hidden" name="id" value={item.id} />}
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      <label className="text-sm font-medium text-gray-700">
        العنوان
        <input name="title" required defaultValue={item?.title} className={field} />
      </label>
      <label className="text-sm font-medium text-gray-700">
        النص
        <textarea name="body" required rows={5} defaultValue={item?.body} className={field} />
      </label>
      <div className="grid gap-3 sm:grid-cols-2">
        <label className="text-sm font-medium text-gray-700">
          الجمهور
          <select name="audience" defaultValue={item?.audience ?? (isAdmin ? 'all' : 'guardians')} className={field}>
            {Object.entries(AUDIENCE_LABELS)
              .filter(([v]) => isAdmin || v !== 'teachers')
              .map(([v, l]) => (
                <option key={v} value={v}>
                  {l}
                </option>
              ))}
          </select>
        </label>
        <label className="text-sm font-medium text-gray-700">
          {isAdmin ? 'حلقة محددة (اختياري)' : 'حلقتك'}
          <select name="circleId" required={!isAdmin} defaultValue={item?.circle_id ?? ''} className={field}>
            {isAdmin && <option value="">كل الحلقات</option>}
            {!isAdmin && (
              <option value="" disabled>
                اختر الحلقة
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
        ينتهي في (اختياري)
        <input type="date" name="expiresOn" defaultValue={item?.expires_on ?? ''} className={field} />
      </label>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" name="pinned" defaultChecked={item?.pinned} /> تثبيت في الأعلى
      </label>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" name="publish" defaultChecked={item ? !item.draft : true} /> نشر الآن (يصل إشعار للجمهور عند أول نشر)
      </label>
      <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText="جاري الحفظ...">
        {item ? 'حفظ' : 'إضافة'}
      </SubmitButton>
    </form>
  );
}
