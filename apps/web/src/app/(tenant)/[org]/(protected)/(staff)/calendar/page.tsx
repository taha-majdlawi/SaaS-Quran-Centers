import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { CalendarMonth } from '@/components/calendar-month';
import { fmtRange, fmtTime, monthBounds, type CalRange } from '@/lib/calendar/format';

export default async function CalendarPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ month?: string; ok?: string; error?: string }>;
}) {
  const { org: slug } = await params;
  const { month, ok, error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const isAdmin = org.myRole === 'admin';
  const b = monthBounds(month);

  const { data, error: rpcError } = await supabase.rpc('calendar_range', { p_org: org.id, p_from: b.from, p_to: b.to, p_circle: null });
  const range = data as CalRange | null;

  return (
    <div className="max-w-5xl">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-bold">التقويم</h1>
        {isAdmin && (
          <div className="flex gap-2 text-sm">
            <a href="/calendar/new" className="rounded bg-brand px-4 py-2 font-semibold text-white">
              + إضافة
            </a>
            <a href="/calendar/types" className="rounded border px-4 py-2 text-brand">
              أنواع العناصر
            </a>
            <a href="/settings" className="rounded border px-4 py-2 text-brand">
              أيام الدوام والسرد
            </a>
          </div>
        )}
      </div>

      {ok === 'deleted' && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم الحذف</p>}
      {(error || rpcError) && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error ?? rpcError?.message}</p>}

      {range && (
        <>
          <CalendarMonth ym={month} range={range} base="/calendar" entryHref={(id) => `/calendar/${id}`} />

          <h2 className="mb-2 mt-8 font-semibold">عناصر هذا الشهر</h2>
          <div className="flex flex-col gap-2">
            {range.entries.map((e) => (
              <a key={e.id} href={`/calendar/${e.id}` as never} className="flex flex-wrap items-center justify-between gap-2 rounded-lg border bg-white p-3 text-sm hover:bg-gray-50">
                <span className="flex items-center gap-2">
                  <span className="h-3 w-3 rounded-full" style={{ backgroundColor: e.type_color }} />
                  <b>{e.title}</b>
                  <span className="text-xs text-gray-500">{e.type_name}</span>
                </span>
                <span className="text-xs text-gray-600">
                  {fmtRange(e)}
                  {e.starts_at && ` · ${fmtTime(e.starts_at)}`}
                  {e.supports_registration && ` · ${e.taken}${e.capacity ? `/${e.capacity}` : ''} مسجّل`}
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
