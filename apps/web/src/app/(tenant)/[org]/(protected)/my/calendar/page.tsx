import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { CalendarMonth } from '@/components/calendar-month';
import { fmtRange, fmtTime, monthBounds, STATE_LABELS, type CalRange } from '@/lib/calendar/format';

// The student / guardian calendar: the same range read the staff calendar uses,
// filtered on the server to what is addressed to them.
export default async function MyCalendarPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ month?: string }>;
}) {
  const { org: slug } = await params;
  const { month } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const b = monthBounds(month);

  const { data } = await supabase.rpc('calendar_range', { p_org: org.id, p_from: b.from, p_to: b.to, p_circle: null });
  const range = data as CalRange | null;

  return (
    <div className="mx-auto max-w-4xl p-6">
      <a href="/my" className="text-sm text-brand hover:underline">
        ← ملفي
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">التقويم والفعاليات</h1>
      {range && (
        <>
          <CalendarMonth ym={month} range={range} base="/my/calendar" entryHref={(id) => `/my/calendar/${id}`} />
          <h2 className="mb-2 mt-8 font-semibold">عناصر هذا الشهر</h2>
          <div className="flex flex-col gap-2">
            {range.entries.map((e) => (
              <a key={e.id} href={`/my/calendar/${e.id}` as never} className="flex flex-wrap items-center justify-between gap-2 rounded-lg border bg-white p-3 text-sm hover:bg-gray-50">
                <span className="flex items-center gap-2">
                  <span className="h-3 w-3 rounded-full" style={{ backgroundColor: e.type_color }} />
                  <b>{e.title}</b>
                  <span className="text-xs text-gray-500">{e.type_name}</span>
                </span>
                <span className="text-xs text-gray-600">
                  {fmtRange(e)}
                  {e.starts_at && ` · ${fmtTime(e.starts_at)}`}
                  {e.supports_registration && ` · ${e.my_registered ? 'أنت مسجّل ✓' : STATE_LABELS[e.registration_state]}`}
                </span>
              </a>
            ))}
            {!range.entries.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا يوجد شيء في هذا الشهر</p>}
          </div>
        </>
      )}
    </div>
  );
}
