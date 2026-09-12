import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { updateAnnouncement, deleteAnnouncement } from '../actions';

export default async function EditAnnouncementPage({
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

  const { data: announcement } = await supabase
    .from('announcements')
    .select('id, title, body, audience')
    .eq('organization_id', org.id)
    .eq('id', id)
    .maybeSingle();

  if (!announcement) notFound();

  return (
    <div className="max-w-lg">
      <h1 className="mb-6 text-2xl font-bold">تعديل إعلان</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={updateAnnouncement} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="id" value={announcement.id} />

        <label className="text-sm font-medium text-gray-700">
          العنوان
          <input
            name="title"
            required
            defaultValue={announcement.title}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          النص
          <textarea
            name="body"
            required
            rows={5}
            defaultValue={announcement.body}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          الجمهور
          <select
            name="audience"
            defaultValue={announcement.audience}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          >
            <option value="all">الكل</option>
            <option value="teachers">المعلمون</option>
            <option value="students">الطلاب</option>
            <option value="guardians">أولياء الأمور</option>
          </select>
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الحفظ..."
        >
          حفظ التعديلات
        </SubmitButton>
      </form>

      <form action={deleteAnnouncement} className="mt-3">
        <input type="hidden" name="id" value={announcement.id} />
        <ConfirmSubmitButton
          confirmMessage="متأكد إنك بدك تحذف هذا الإعلان؟"
          pendingText="جاري الحذف..."
          className="rounded border border-red-200 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
        >
          حذف الإعلان
        </ConfirmSubmitButton>
      </form>
    </div>
  );
}
