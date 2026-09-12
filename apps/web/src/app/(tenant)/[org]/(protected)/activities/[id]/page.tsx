import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { updateActivity, deleteActivity } from '../actions';

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
      <h1 className="mb-6 text-2xl font-bold">تعديل نشاط</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={updateActivity} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="id" value={activity.id} />

        <label className="text-sm font-medium text-gray-700">
          العنوان
          <input
            name="title"
            required
            defaultValue={activity.title}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          الوصف
          <textarea
            name="description"
            rows={3}
            defaultValue={activity.description ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          الموعد (اختياري)
          <input
            type="datetime-local"
            name="scheduledAt"
            defaultValue={toDatetimeLocal(activity.scheduled_at)}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الحفظ..."
        >
          حفظ التعديلات
        </SubmitButton>
      </form>

      <form action={deleteActivity} className="mt-3">
        <input type="hidden" name="id" value={activity.id} />
        <ConfirmSubmitButton
          confirmMessage={`متأكد إنك بدك تحذف نشاط "${activity.title}"؟`}
          pendingText="جاري الحذف..."
          className="rounded border border-red-200 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
        >
          حذف النشاط
        </ConfirmSubmitButton>
      </form>
    </div>
  );
}
