import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { CalendarEntryForm } from '@/components/calendar-entry-form';
import type { CalType } from '@/lib/calendar/format';
import { getI18n } from '@/lib/i18n/server';

export default async function NewCalendarEntryPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string; date?: string }>;
}) {
  const { org: slug } = await params;
  const { error, date } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  if (org.myRole !== 'admin') redirect('/calendar' as never);
  const supabase = await createClient();

  const [{ data: types }, { data: circles }, { data: stages }] = await Promise.all([
    supabase.from('calendar_entry_types').select('*').eq('organization_id', org.id).order('sort_order'),
    supabase.from('circles').select('id, name').eq('organization_id', org.id).order('name'),
    supabase.from('stages').select('id, name').eq('organization_id', org.id).order('name'),
  ]);

  return (
    <div>
      <a href="/calendar" className="text-sm text-brand hover:underline">
        {S.cal.back}
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">{S.cal.newTitle}</h1>
      <CalendarEntryForm
        orgId={org.id}
        types={(types ?? []) as CalType[]}
        circles={circles ?? []}
        stages={stages ?? []}
        defaultDate={date}
        error={error}
      />
    </div>
  );
}
