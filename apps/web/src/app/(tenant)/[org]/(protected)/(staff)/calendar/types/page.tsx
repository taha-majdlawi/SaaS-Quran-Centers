import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import type { CalType } from '@/lib/calendar/format';
import { deleteType, saveType } from '../actions';
import { getI18n } from '@/lib/i18n/server';

const field = 'mt-1 rounded border px-2 py-1.5 text-sm';

async function TypeFields({ t }: { t?: CalType }) {
  const S = (await getI18n()).t.staff;
  return (
    <>
      <label className="text-xs text-gray-600">
        {S.cal.tName}
        <input name="name" required defaultValue={t?.name} className={`block w-40 ${field}`} />
      </label>
      <label className="text-xs text-gray-600">
        {S.cal.tColor}
        <input type="color" name="color" defaultValue={t?.color ?? '#64748b'} className="mt-1 block h-9 w-12 rounded border" />
      </label>
      <label className="flex items-center gap-1 pb-1.5 text-xs text-gray-600">
        <input type="checkbox" name="defaultIsWorking" defaultChecked={t?.default_is_working ?? true} /> {S.cal.workDay}
      </label>
      <label className="flex items-center gap-1 pb-1.5 text-xs text-gray-600">
        <input type="checkbox" name="supportsRegistration" defaultChecked={t?.supports_registration ?? false} /> {S.cal.tRegistration}
      </label>
      <label className="flex items-center gap-1 pb-1.5 text-xs text-gray-600">
        <input type="checkbox" name="requiresConsent" defaultChecked={t?.requires_guardian_consent ?? false} /> {S.cal.tConsent}
      </label>
      <label className="flex items-center gap-1 pb-1.5 text-xs text-gray-600">
        <input type="checkbox" name="isActive" defaultChecked={t?.is_active ?? true} /> {S.cal.tActive}
      </label>
    </>
  );
}

export default async function CalendarTypesPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ ok?: string; error?: string }>;
}) {
  const { org: slug } = await params;
  const { ok, error } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  if (org.myRole !== 'admin') redirect('/calendar' as never);
  const supabase = await createClient();
  const { data } = await supabase.from('calendar_entry_types').select('*').eq('organization_id', org.id).order('sort_order');
  const types = (data ?? []) as CalType[];

  return (
    <div className="max-w-4xl">
      <a href="/calendar" className="text-sm text-brand hover:underline">
        {S.cal.back}
      </a>
      <h1 className="mb-1 mt-2 text-2xl font-bold">{S.cal.typesTitle}</h1>
      <p className="mb-6 text-sm text-gray-500">
        {S.cal.typesIntro}
      </p>
      {ok && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{S.cal.savedOk}</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <div className="flex flex-col gap-3">
        {types.map((t, i) => (
          <div key={t.id} className="flex flex-wrap items-end gap-2 rounded-lg border bg-white p-3">
            <form action={saveType} className="flex flex-wrap items-end gap-2">
              <input type="hidden" name="orgId" value={org.id} />
              <input type="hidden" name="id" value={t.id} />
              <input type="hidden" name="sortOrder" value={i + 1} />
              <TypeFields t={t} />
              <SubmitButton className="rounded border px-3 py-1.5 text-sm text-brand" pendingText="...">
                {S.common.save}
              </SubmitButton>
            </form>
            <form action={deleteType}>
              <input type="hidden" name="orgId" value={org.id} />
              <input type="hidden" name="id" value={t.id} />
              <ConfirmSubmitButton confirmMessage={S.cal.deleteTypeConfirm} pendingText="..." className="rounded border border-red-200 px-3 py-1.5 text-sm text-red-600">
                {S.common.delete}
              </ConfirmSubmitButton>
            </form>
          </div>
        ))}
      </div>

      <form action={saveType} className="mt-6 flex flex-wrap items-end gap-2 rounded-lg border bg-white p-3">
        <input type="hidden" name="orgId" value={org.id} />
        <input type="hidden" name="sortOrder" value={types.length + 1} />
        <span className="w-full text-sm font-semibold">{S.cal.newType}</span>
        <TypeFields />
        <SubmitButton className="rounded bg-brand px-3 py-1.5 text-sm font-semibold text-white" pendingText="...">
          {S.common.add}
        </SubmitButton>
      </form>
    </div>
  );
}
