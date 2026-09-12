import { getOrgContext } from '@/lib/tenant/get-org-context';
import { SubmitButton } from '@/components/submit-button';
import { createChallenge } from '../actions';

export default async function NewChallengePage({
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
    <div className="max-w-md">
      <h1 className="mb-6 text-2xl font-bold">منافسة جديدة</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={createChallenge} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />

        <label className="text-sm font-medium text-gray-700">
          العنوان
          <input name="title" required placeholder="منافسة الحفظ الشهرية" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          المعيار
          <input name="metric" required placeholder="عدد الأجزاء المحفوظة" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          تاريخ البداية
          <input type="date" name="startsOn" required className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          تاريخ النهاية
          <input type="date" name="endsOn" required className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الإضافة..."
        >
          إضافة المنافسة
        </SubmitButton>
      </form>
    </div>
  );
}
