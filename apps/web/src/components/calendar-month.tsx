import { monthBounds, type CalRange } from '@/lib/calendar/format';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

/**
 * A month grid (Sunday first, like the center's week pattern). Shaded days are
 * non-working (weekly pattern or a dated holiday/closure); a dot marks a serd
 * day; each cell lists up to two entries in their type colour.
 */
export async function CalendarMonth({
  ym,
  range,
  base,
  entryHref,
}: {
  ym?: string;
  range: CalRange;
  /** Page the prev/next links point at, e.g. '/calendar'. */
  base: string;
  entryHref: (id: string) => string;
}) {
  const b = monthBounds(ym);
  const { t, locale } = await getI18n();
  const C = t.calendar;
  const first = new Date(b.year, b.month, 1);
  const daysInMonth = new Date(b.year, b.month + 1, 0).getDate();
  const lead = first.getDay(); // 0 = Sunday
  const cells: (number | null)[] = [...Array(lead).fill(null), ...Array.from({ length: daysInMonth }, (_, i) => i + 1)];
  while (cells.length % 7) cells.push(null);

  const weekday = new Map(range.weekdays.map((w) => [w.dow, w]));
  const dayIso = (d: number) => `${b.year}-${String(b.month + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
  const entriesOn = (iso: string) => range.entries.filter((e) => e.start_date <= iso && e.end_date >= iso);
  const serdOn = (iso: string) => range.serd.filter((s) => s.session_date === iso);
  const today = b.iso(new Date());

  return (
    <div>
      <div className="mb-3 flex items-center justify-between">
        <a href={`${base}?month=${b.prev}` as never} className="rounded border px-3 py-1 text-sm">
          {C.prev}
        </a>
        <h2 className="text-lg font-bold">
          {t.labels.months[b.month]} {b.year}
        </h2>
        <a href={`${base}?month=${b.next}` as never} className="rounded border px-3 py-1 text-sm">
          {C.next}
        </a>
      </div>

      <div className="grid grid-cols-7 gap-px overflow-hidden rounded-lg border bg-gray-200 text-xs">
        {Array.from({ length: 7 }, (_, dow) => (
          <div key={dow} className="bg-gray-50 px-1 py-2 text-center font-semibold">
            {/* the center's own day names in Arabic; fixed ones otherwise */}
            {locale === 'ar' ? (weekday.get(dow)?.label ?? dow) : t.labels.weekdays[dow]}
            {weekday.get(dow)?.is_serd_day && <span className="ms-1 text-purple-600">●</span>}
          </div>
        ))}
        {cells.map((d, i) => {
          if (d === null) return <div key={i} className="min-h-20 bg-gray-50" />;
          const iso = dayIso(d);
          const dow = new Date(b.year, b.month, d).getDay();
          const entries = entriesOn(iso);
          const closed = !weekday.get(dow)?.is_working || entries.some((e) => !e.is_working_day);
          const serd = serdOn(iso);
          return (
            <div key={i} className={`min-h-20 p-1 ${closed ? 'bg-gray-100' : 'bg-white'} ${iso === today ? 'ring-2 ring-inset ring-brand' : ''}`}>
              <div className="mb-1 flex items-center justify-between">
                <span className={`font-semibold ${closed ? 'text-gray-400' : ''}`}>{d}</span>
                {weekday.get(dow)?.is_serd_day && !closed && <span className="text-[10px] text-purple-600">{C.serd}</span>}
              </div>
              <div className="flex flex-col gap-0.5">
                {entries.slice(0, 2).map((e) => (
                  <a
                    key={e.id}
                    href={entryHref(e.id) as never}
                    className="truncate rounded px-1 py-0.5 text-[11px] text-white"
                    style={{ backgroundColor: e.type_color }}
                    title={e.title}
                  >
                    {e.title}
                  </a>
                ))}
                {entries.length > 2 && <span className="text-[10px] text-gray-500">+{entries.length - 2}</span>}
                {serd.length > 0 && <span className="text-[10px] text-purple-700">{fmt(C.serdCount, { n: serd.length })}</span>}
              </div>
            </div>
          );
        })}
      </div>
      <p className="mt-2 text-xs text-gray-500">{fmt(C.legend, { working: range.working_days, total: range.total_days })}</p>
    </div>
  );
}
