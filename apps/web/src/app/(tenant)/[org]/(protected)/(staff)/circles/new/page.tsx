import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { createCircle } from '../actions';
import { getI18n } from '@/lib/i18n/server';

interface MemberRow {
  user_id: string;
  role: string;
  full_name: string | null;
  email: string | null;
}

export default async function NewCirclePage({
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
  if (org.myRole !== 'admin') redirect('/circles' as never);
  const supabase = await createClient();

  const [{ data: stages }, { data: members }] = await Promise.all([
    supabase.from('stages').select('id, name').eq('organization_id', org.id).order('sort_order'),
    supabase.rpc('list_org_members', { org_id: org.id }),
  ]);

  const teachers = ((members ?? []) as MemberRow[]).filter((m) => m.role === 'teacher');

  return (
    <div className="max-w-lg">
      <h1 className="mb-6 text-2xl font-bold">{S.circles.addTitle}</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={createCircle} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />

        <label className="text-sm font-medium text-gray-700">
          {S.circles.name}
          <input name="name" required className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.circles.colStage}
          <select name="stageId" className="mt-1 w-full rounded border px-3 py-2 text-sm">
            <option value="">{S.circles.noStage}</option>
            {(stages ?? []).map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.circles.colTeacher}
          <select name="teacherId" className="mt-1 w-full rounded border px-3 py-2 text-sm">
            <option value="">{S.circles.noTeacher}</option>
            {teachers.map((t) => (
              <option key={t.user_id} value={t.user_id}>
                {t.full_name ?? t.email}
              </option>
            ))}
          </select>
          {!teachers.length && (
            <p className="mt-1 text-xs text-gray-400">
              {S.circles.noTeachersYet}{' '}
              <a href="/members" className="text-brand hover:underline">
                {S.circles.inviteTeacher}
              </a>
            </p>
          )}
        </label>

        <label className="text-sm font-medium text-gray-700">
          {S.circles.capacity}
          <input type="number" name="capacity" min={1} className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText={S.common.adding}
        >
          {S.circles.submit}
        </SubmitButton>
      </form>
    </div>
  );
}
