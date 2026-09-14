import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { StudentFormFields } from './student-form-fields';
import { createStudent } from '../actions';

export default async function NewStudentPage({
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

  const [{ data: stages }, { data: circles }] = await Promise.all([
    supabase.from('stages').select('id, name').eq('organization_id', org.id).order('sort_order'),
    supabase.from('circles').select('id, name, stage_id').eq('organization_id', org.id).order('name'),
  ]);

  const suggestedCodes: Record<string, string> = {};
  await Promise.all(
    (stages ?? []).map(async (s) => {
      const { data: code } = await supabase.rpc('next_student_code', { org_id: org.id, target_stage_id: s.id });
      if (code) suggestedCodes[s.id] = code;
    }),
  );

  return (
    <div className="max-w-lg">
      <h1 className="mb-6 text-2xl font-bold">إضافة طالب</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={createStudent} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />

        <label className="text-sm font-medium text-gray-700">
          الاسم الكامل
          <input name="fullName" required className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <StudentFormFields stages={stages ?? []} circles={circles ?? []} suggestedCodes={suggestedCodes} />

        <label className="text-sm font-medium text-gray-700">
          تاريخ الميلاد
          <input type="date" name="birthDate" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الإضافة..."
        >
          إضافة الطالب
        </SubmitButton>
      </form>
    </div>
  );
}
