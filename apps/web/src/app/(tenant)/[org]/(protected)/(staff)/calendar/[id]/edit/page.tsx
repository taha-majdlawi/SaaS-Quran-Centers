import { notFound, redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { CalendarEntryForm } from '@/components/calendar-entry-form';
import { CalendarImagesField } from '@/components/calendar-images-field';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import type { CalDetails, CalType } from '@/lib/calendar/format';
import { deleteEntry } from '../../actions';

export default async function EditCalendarEntryPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug, id } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  if (org.myRole !== 'admin') redirect('/calendar' as never);
  const supabase = await createClient();

  const [{ data: entry }, { data: types }, { data: circles }, { data: stages }] = await Promise.all([
    supabase.rpc('calendar_entry_details', { p_org: org.id, p_entry: id }),
    supabase.from('calendar_entry_types').select('*').eq('organization_id', org.id).order('sort_order'),
    supabase.from('circles').select('id, name').eq('organization_id', org.id).order('name'),
    supabase.from('stages').select('id, name').eq('organization_id', org.id).order('name'),
  ]);
  if (!entry) notFound();

  return (
    <div>
      <a href={`/calendar/${id}` as never} className="text-sm text-brand hover:underline">
        ← رجوع
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">تعديل</h1>
      <CalendarEntryForm
        orgId={org.id}
        types={(types ?? []) as CalType[]}
        circles={circles ?? []}
        stages={stages ?? []}
        entry={entry as CalDetails}
        error={error}
      />
      <div className="mt-6 border-t pt-6">
        <CalendarImagesField
          orgId={org.id}
          entryId={id}
          images={(entry as CalDetails).images}
          back={`/calendar/${id}/edit`}
        />
      </div>
      <form action={deleteEntry} className="mt-4">
        <input type="hidden" name="orgId" value={org.id} />
        <input type="hidden" name="id" value={id} />
        <ConfirmSubmitButton
          confirmMessage="سيُحذف هذا العنصر مع كل التسجيلات عليه. متأكد؟"
          pendingText="جاري الحذف..."
          className="rounded border border-red-200 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
        >
          حذف
        </ConfirmSubmitButton>
      </form>
    </div>
  );
}
