'use client';

import { useEffect, useState } from 'react';
import { CalculationMethod, Coordinates, Madhab, PrayerTimes, type CalculationParameters } from 'adhan';

// Same keys as organization_settings.prayer_calc_method and the mobile
// _calcMethods map (home_extras.dart), translated to adhan-js's factory names.
const CALC_METHODS: Record<string, () => CalculationParameters> = {
  muslim_world_league: CalculationMethod.MuslimWorldLeague,
  egyptian: CalculationMethod.Egyptian,
  karachi: CalculationMethod.Karachi,
  umm_al_qura: CalculationMethod.UmmAlQura,
  dubai: CalculationMethod.Dubai,
  moon_sighting_committee: CalculationMethod.MoonsightingCommittee,
  north_america: CalculationMethod.NorthAmerica,
  kuwait: CalculationMethod.Kuwait,
  qatar: CalculationMethod.Qatar,
  singapore: CalculationMethod.Singapore,
  turkey: CalculationMethod.Turkey,
  tehran: CalculationMethod.Tehran,
};

interface Entry {
  label: string;
  time: Date;
}

/**
 * Coordinates are the center's configured location (prayer_lat/prayer_lng),
 * never browser geolocation - same as mobile/eqraa. Computed in the browser
 * so "today" and the highlighted next prayer follow the viewer's own clock,
 * like the phone does.
 */
function computeToday(settings: Record<string, string>, names: string[]): { entries: Entry[]; next: number } | null {
  try {
    const lat = parseFloat(settings.prayer_lat ?? '');
    const lng = parseFloat(settings.prayer_lng ?? '');
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
    const params = (CALC_METHODS[settings.prayer_calc_method ?? ''] ?? CalculationMethod.Egyptian)();
    params.madhab = settings.prayer_madhab === 'hanafi' ? Madhab.Hanafi : Madhab.Shafi;
    const pt = new PrayerTimes(new Coordinates(lat, lng), new Date(), params);
    const entries: Entry[] = [
      { label: names[0], time: pt.fajr },
      { label: names[1], time: pt.dhuhr },
      { label: names[2], time: pt.asr },
      { label: names[3], time: pt.maghrib },
      { label: names[4], time: pt.isha },
    ];
    const now = Date.now();
    const next = entries.findIndex((e) => e.time.getTime() > now);
    return { entries, next: next === -1 ? 0 : next };
  } catch {
    return null;
  }
}

const hhmm = (d: Date) => `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;

/** `names`: Fajr..Isha in the viewer's language (t.portal.prayers). */
export function PrayerTimesCard({ settings, names }: { settings: Record<string, string>; names: string[] }) {
  const [today, setToday] = useState<ReturnType<typeof computeToday>>(null);
  useEffect(() => setToday(computeToday(settings, names)), [settings, names]);
  if (!today) return null;
  return (
    <div className="grid grid-cols-5 gap-1 rounded-lg border bg-white p-2 text-center">
      {today.entries.map((e, i) => (
        <div key={e.label} className={`rounded-md px-1 py-2 ${i === today.next ? 'bg-brand text-white' : ''}`}>
          <p className="text-xs font-bold">{e.label}</p>
          <p className={`mt-1 text-sm ${i === today.next ? 'text-brand-accent' : 'text-gray-500'}`} dir="ltr">
            {hhmm(e.time)}
          </p>
        </div>
      ))}
    </div>
  );
}
