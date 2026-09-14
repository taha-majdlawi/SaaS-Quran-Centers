import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { createSerdSession } from '../actions';

export default async function NewSerdSessionPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data: students } = await supabase
    .from('students_profile')
    .select('id, full_name')
    .eq('organization_id', org.id)
    .order('full_name');

  return (
    <div className="max-w-lg">
      <h1 className="mb-6 text-2xl font-bold">جدولة جلسة سرد</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={createSerdSession} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />

        <label className="text-sm font-medium text-gray-700">
          الطالب
          <select name="studentId" required className="mt-1 w-full rounded border px-3 py-2 text-sm">
            <option value="" disabled>
              اختر الطالب
            </option>
            {(students ?? []).map((s) => (
              <option key={s.id} value={s.id}>
                {s.full_name}
              </option>
            ))}
          </select>
        </label>

        <label className="text-sm font-medium text-gray-700">
          نوع السرد
          <select name="sessionType" required className="mt-1 w-full rounded border px-3 py-2 text-sm">
            <option value="partial">جزئي</option>
            <option value="full">كامل</option>
          </select>
        </label>

        <label className="text-sm font-medium text-gray-700">
          الموعد (اختياري)
          <input
            type="datetime-local"
            name="scheduledAt"
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الجدولة..."
        >
          جدولة الجلسة
        </SubmitButton>
      </form>
    </div>
  );
}
