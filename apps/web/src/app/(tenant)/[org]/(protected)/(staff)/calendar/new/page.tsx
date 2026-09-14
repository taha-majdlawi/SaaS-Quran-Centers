import { getOrgContext } from '@/lib/tenant/get-org-context';
import { SubmitButton } from '@/components/submit-button';
import { createEvent } from '../actions';

export default async function NewEventPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);

  return (
    <div className="max-w-lg">
      <h1 className="mb-6 text-2xl font-bold">فعالية جديدة</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={createEvent} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />

        <label className="text-sm font-medium text-gray-700">
          العنوان
          <input name="title" required className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          الوصف
          <textarea name="description" rows={3} className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          التاريخ والوقت
          <input
            type="datetime-local"
            name="startsAt"
            required
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          المكان
          <input name="location" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="flex items-center gap-2 text-sm font-medium text-gray-700">
          <input type="checkbox" name="requiresConsent" />
          تحتاج موافقة ولي الأمر (رحلة مثلًا)
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الإضافة..."
        >
          إضافة الفعالية
        </SubmitButton>
      </form>
    </div>
  );
}
