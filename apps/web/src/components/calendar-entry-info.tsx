import { AUDIENCE_LABELS, STATE_LABELS, fmtRange, fmtTime, type CalEntry, type CalImage } from '@/lib/calendar/format';

/** The read-only facts about one calendar entry (shared by staff and portal). */
export function CalendarEntryInfo({ entry }: { entry: CalEntry & { images?: CalImage[] } }) {
  const rows: [string, string | null][] = [
    ['التاريخ', `${fmtRange(entry)}${entry.starts_at ? ` · ${fmtTime(entry.starts_at)}` : ''}`],
    ['المكان', entry.location],
    ['الجمهور', [AUDIENCE_LABELS[entry.audience], entry.circle_name && `حلقة ${entry.circle_name}`, entry.stage_name && `مرحلة ${entry.stage_name}`].filter(Boolean).join(' · ')],
    ['الدوام', entry.is_working_day ? 'يوم دوام' : 'ليس يوم دوام (لا يُحتسب في نسبة الحضور)'],
  ];
  return (
    <div className="rounded-lg border bg-white p-5">
      <div className="mb-3 flex flex-wrap items-center gap-2">
        <h1 className="text-xl font-bold">{entry.title}</h1>
        <span className="rounded px-2 py-0.5 text-xs text-white" style={{ backgroundColor: entry.type_color }}>
          {entry.type_name}
        </span>
      </div>
      {entry.description && <p className="mb-3 whitespace-pre-line text-sm text-gray-700">{entry.description}</p>}
      {entry.images && entry.images.length > 0 && (
        <div className="mb-3 flex gap-2 overflow-x-auto">
          {entry.images.map((img) => (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              key={img.id}
              src={img.image_url}
              alt={img.caption ?? ''}
              title={img.caption ?? ''}
              className="h-40 w-56 flex-shrink-0 rounded-lg border object-cover"
            />
          ))}
        </div>
      )}
      <dl className="grid gap-2 text-sm sm:grid-cols-2">
        {rows.map(([label, value]) =>
          value ? (
            <div key={label}>
              <dt className="text-xs text-gray-500">{label}</dt>
              <dd className="font-medium">{value}</dd>
            </div>
          ) : null,
        )}
      </dl>
      {entry.supports_registration && (
        <div className="mt-4 flex flex-wrap items-center gap-3 rounded bg-gray-50 px-3 py-2 text-sm">
          <span className="font-semibold">{STATE_LABELS[entry.registration_state]}</span>
          <span>
            المسجّلون: {entry.taken}
            {entry.capacity ? ` / ${entry.capacity}` : ''}
          </span>
          {entry.waiting > 0 && <span>قائمة الانتظار: {entry.waiting}</span>}
          {entry.registration_deadline && <span>آخر موعد: {entry.registration_deadline}</span>}
          {entry.requires_guardian_consent && <span className="text-amber-700">تحتاج موافقة ولي الأمر</span>}
        </div>
      )}
    </div>
  );
}
