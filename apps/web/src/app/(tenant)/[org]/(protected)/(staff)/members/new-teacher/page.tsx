import { getOrgContext } from '@/lib/tenant/get-org-context';
import { SubmitButton } from '@/components/submit-button';
import { createTeacherDirectly } from './actions';
import { PlanCapacityNote } from '@/components/plan-capacity-note';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

function generatePassword() {
  return crypto.randomUUID().replace(/-/g, '').slice(0, 10);
}

export default async function NewTeacherPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;

  return (
    <div className="max-w-lg">
      <h1 className="mb-1 text-2xl font-bold">{S.members.newTeacherTitle}</h1>
      <p className="mb-6 text-sm text-gray-500">
        {S.members.newTeacherIntro}
      </p>

      <PlanCapacityNote orgId={org.id} kind="teachers" isAdmin={org.myRole === 'admin'} />
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={createTeacherDirectly} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />

        <label className="text-sm font-medium text-gray-700">
          {S.members.teacherName}
          <input name="fullName" required className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.members.identifier}
          <input name="identifier" required dir="ltr" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
          <span className="mt-1 block text-xs text-gray-400">
            {fmt(S.members.identifierHint, { code: org.slug })}
          </span>
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.members.phoneOptional}
          <input name="phone" dir="ltr" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.members.passwordSuggested}
          <input
            name="password"
            required
            minLength={8}
            defaultValue={generatePassword()}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
            dir="ltr"
          />
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText={S.common.creating}
        >
          {S.members.createTeacher}
        </SubmitButton>
      </form>
    </div>
  );
}
