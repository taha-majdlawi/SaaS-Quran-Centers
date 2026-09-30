import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { StudentFormFields } from './student-form-fields';
import { createStudent } from '../actions';
import { PlanCapacityNote, planIsFull } from '@/components/plan-capacity-note';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

function generatePassword() {
  return crypto.randomUUID().replace(/-/g, '').slice(0, 8);
}

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
  const atCapacity = await planIsFull(org.id, 'students');
  const { t: T } = await getI18n();
  const S = T.staff;
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
      <h1 className="mb-6 text-2xl font-bold">{S.students.addTitle}</h1>
      <PlanCapacityNote orgId={org.id} kind="students" isAdmin={org.myRole === 'admin'} />

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={createStudent} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />

        <label className="text-sm font-medium text-gray-700">
          {S.students.fullName}
          <input name="fullName" required className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <StudentFormFields stages={stages ?? []} circles={circles ?? []} suggestedCodes={suggestedCodes} labels={S.studentForm} />

        <label className="text-sm font-medium text-gray-700">
          {S.students.birthDate}
          <input type="date" name="birthDate" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.students.phone}
          <input name="phone" dir="ltr" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.students.whatsapp}
          <input name="whatsapp" dir="ltr" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.students.address}
          <input name="address" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <div className="rounded-lg border border-dashed p-4">
          <p className="mb-2 text-sm font-semibold text-gray-700">{S.students.account}</p>
          <label className="text-sm font-medium text-gray-700">
            {S.students.password}
            <input
              name="password"
              minLength={8}
              defaultValue={generatePassword()}
              dir="ltr"
              className="mt-1 w-full rounded border px-3 py-2 text-sm"
            />
          </label>
          <label className="mt-3 block text-sm font-medium text-gray-700">
            {S.students.email}
            <input type="email" name="email" dir="ltr" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
          </label>
          <p className="mt-2 text-xs text-gray-400">
            {fmt(S.students.signInHint, { code: org.slug })}
          </p>
        </div>

        <SubmitButton
          disabled={atCapacity}
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText={S.students.adding}
        >
          {S.students.submit}
        </SubmitButton>
      </form>
    </div>
  );
}
