import { getOrgContext } from '@/lib/tenant/get-org-context';
import { SubmitButton } from '@/components/submit-button';
import { createAnnouncement } from '../actions';

export default async function NewAnnouncementPage({
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
      <h1 className="mb-6 text-2xl font-bold">إعلان جديد</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={createAnnouncement} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />

        <label className="text-sm font-medium text-gray-700">
          العنوان
          <input name="title" required className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          النص
          <textarea name="body" required rows={5} className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          الجمهور
          <select name="audience" className="mt-1 w-full rounded border px-3 py-2 text-sm">
            <option value="all">الكل</option>
            <option value="teachers">المعلمون</option>
            <option value="students">الطلاب</option>
            <option value="guardians">أولياء الأمور</option>
          </select>
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري النشر..."
        >
          نشر الإعلان
        </SubmitButton>
      </form>
    </div>
  );
}
