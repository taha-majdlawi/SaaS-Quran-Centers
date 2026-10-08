import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { CenterFeaturesForm, RecitationAudioForm } from './center-features';
import { SubmitButton } from '@/components/submit-button';
import { LogoField } from '@/components/logo-field';
import { AYAH_RECITERS, reciterLabel } from '@/lib/quran/mushaf';
import { updateOrgSettings, saveWeekdays, saveCenterSettings } from './actions';
import { getI18n } from '@/lib/i18n/server';
import { LOCALES, LOCALE_NAMES } from '@/lib/i18n/config';

const PRAYER_METHODS = ['umm_al_qura', 'muslim_world_league', 'egyptian', 'karachi', 'dubai', 'qatar', 'kuwait', 'moon_sighting_committee', 'singapore', 'turkey', 'tehran', 'north_america'];

/** One tab per group of settings; each tab is its own form and saves only its own fields. */
const TABS = ['identity', 'workdays', 'features', 'modules', 'contact', 'quran', 'more'] as const;
type Tab = (typeof TABS)[number];

const input = 'mt-1 w-full rounded border px-3 py-2 text-sm';
const label = 'text-sm font-medium text-gray-700';
const card = 'rounded-lg border bg-white p-6';
const checkRow = 'flex items-center gap-2 text-sm text-gray-700';

interface Weekday {
  dow: number;
  label: string;
  is_working: boolean;
  is_serd_day: boolean;
}

export default async function SettingsPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string; saved?: string; tab?: string }>;
}) {
  const { org: slug } = await params;
  const q = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const isAdmin = org.myRole === 'admin';
  const tab: Tab = (TABS as readonly string[]).includes(q.tab ?? '') ? (q.tab as Tab) : 'identity';
  const supabase = await createClient();

  const [{ data: weekdayRows }, { data: settingRows }, { data: orgRow }] = await Promise.all([
    supabase.from('center_weekdays').select('dow, label, is_working, is_serd_day').eq('organization_id', org.id).order('dow'),
    supabase.from('organization_settings').select('key, value').eq('organization_id', org.id),
    supabase.from('organizations').select('timezone').eq('id', org.id).single(),
  ]);
  const weekdays = (weekdayRows ?? []) as Weekday[];
  const settings = new Map((settingRows ?? []).map((r) => [r.key as string, (r.value as string | null) ?? '']));
  const flag = (key: string) => (settings.get(key) ?? 'true') !== 'false';

  // what every form carries: the center, and the tab to come back to
  const hidden = (
    <>
      <input type="hidden" name="orgId" value={org.id} />
      <input type="hidden" name="tab" value={tab} />
    </>
  );
  const save = (text: string) =>
    isAdmin && (
      <SubmitButton className="mt-2 self-start rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50" pendingText={S.common.saving}>
        {text}
      </SubmitButton>
    );

  return (
    <div className="flex max-w-2xl flex-col gap-4">
      <div>
        <h1 className="mb-1 text-2xl font-bold">{S.settings.heading}</h1>
        <p className="text-sm text-gray-500">{S.settings.intro}</p>
      </div>

      <nav className="-mx-1 flex gap-1 overflow-x-auto border-b px-1" aria-label={S.settings.heading}>
        {TABS.filter((v) => (v !== 'more' && v !== 'modules') || isAdmin).map((v) => (
          <a
            key={v}
            href={`/settings?tab=${v}` as never}
            aria-current={tab === v ? 'page' : undefined}
            className={`-mb-px whitespace-nowrap border-b-2 px-3 py-2 text-sm ${
              tab === v ? 'border-brand font-semibold text-brand' : 'border-transparent text-gray-600 hover:text-gray-900'
            }`}
          >
            {v === 'modules' ? S.cfeat.tab : S.settings.tabs[v]}
          </a>
        ))}
      </nav>

      {q.error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{q.error}</p>}
      {q.saved && <p className="rounded bg-green-50 px-3 py-2 text-sm text-green-700">{q.saved === 'features' ? S.cfeat.saved : q.saved === 'audio' ? S.cfeat.audioSaved : S.settings.saved}</p>}

      {tab === 'modules' && isAdmin && <CenterFeaturesForm orgId={org.id} />}
      {tab === 'modules' && isAdmin && <RecitationAudioForm orgId={org.id} />}

      {tab === 'identity' && (
        <form action={updateOrgSettings} className={card}>
          {hidden}
          <fieldset disabled={!isAdmin} className="flex flex-col gap-3">
            <h2 className="font-semibold">{S.settings.identity}</h2>
            <label className={label}>
              {S.settings.name}
              <input name="name" required defaultValue={org.name} className={input} />
            </label>
            <LogoField orgId={org.id} initialUrl={org.logoUrl} name={org.name} labels={S.image} />
            <label className={label}>
              {S.settings.primary}
              <input type="color" name="primaryColor" defaultValue={org.primaryColor} className="mt-1 h-10 w-full rounded border" />
            </label>
            <label className={label}>
              {S.settings.secondary}
              <input type="color" name="secondaryColor" defaultValue={org.secondaryColor} className="mt-1 h-10 w-full rounded border" />
            </label>
            <label className={label}>
              {S.settings.link}
              <input value={`${org.slug}.bustan-alquran.com`} disabled dir="ltr" className="mt-1 w-full rounded border bg-gray-50 px-3 py-2 text-sm text-gray-500" />
            </label>
            <label className={label}>
              {S.settings.timezone}
              <input name="timezone" dir="ltr" defaultValue={(orgRow?.timezone as string | null) || 'Asia/Amman'} className={input} />
            </label>
            {save(S.settings.saveIdentity)}
          </fieldset>
        </form>
      )}

      {tab === 'workdays' && (
        <form action={saveWeekdays} className={card}>
          {hidden}
          <fieldset disabled={!isAdmin} className="flex flex-col gap-3">
            <h2 className="font-semibold">{S.settings.workdays}</h2>
            <p className="text-xs text-gray-500">{S.settings.workdaysHint}</p>
            <div className="grid grid-cols-[1fr_5rem_5rem] gap-3 text-xs font-semibold text-gray-500">
              <span>{S.settings.day}</span>
              <span>{S.settings.working}</span>
              <span>{S.settings.serdDay}</span>
            </div>
            {weekdays.map((d) => (
              <div key={d.dow} className="grid grid-cols-[1fr_5rem_5rem] items-center gap-3">
                <input type="hidden" name={`label_${d.dow}`} value={d.label} />
                <span className="text-sm">{T.labels.weekdays[d.dow] ?? d.label}</span>
                <input type="checkbox" name={`working_${d.dow}`} defaultChecked={d.is_working} className="h-4 w-4" />
                <input type="checkbox" name={`serd_${d.dow}`} defaultChecked={d.is_serd_day} className="h-4 w-4" />
              </div>
            ))}
            {save(S.settings.saveWorkdays)}
          </fieldset>
        </form>
      )}

      {tab === 'features' && (
        <form action={saveCenterSettings} className={card}>
          {hidden}
          <input type="hidden" name="flags" value="flag_market_enabled,flag_leaderboard_enabled,flag_teacher_manage_students,flag_fees_enabled" />
          <fieldset disabled={!isAdmin} className="flex flex-col gap-3">
            <h2 className="font-semibold">{S.settings.features}</h2>
            <label className={label}>
              {S.settings.backdate}
              <input type="number" name="backdate_days" min={0} max={365} defaultValue={settings.get('backdate_days') ?? '60'} className={input} />
            </label>
            <label className={checkRow}>
              <input type="checkbox" name="flag_market_enabled" defaultChecked={flag('flag_market_enabled')} /> {S.settings.market}
            </label>
            <label className={checkRow}>
              <input type="checkbox" name="flag_leaderboard_enabled" defaultChecked={flag('flag_leaderboard_enabled')} /> {S.settings.leaderboard}
            </label>
            <label className={checkRow}>
              <input type="checkbox" name="flag_teacher_manage_students" defaultChecked={flag('flag_teacher_manage_students')} /> {S.settings.teacherStudents}
            </label>
            <label className={checkRow}>
              {/* off unless switched on: most centers are free (0081) */}
              <input type="checkbox" name="flag_fees_enabled" defaultChecked={settings.get('flag_fees_enabled') === 'true'} /> {S.settings.fees}
            </label>
            <label className={label}>
              {S.settings.language}
              <select name="default_language" defaultValue={settings.get('default_language') || 'ar'} className={input}>
                {LOCALES.map((l) => (
                  <option key={l} value={l}>
                    {LOCALE_NAMES[l]}
                  </option>
                ))}
              </select>
              <span className="mt-1 block text-xs font-normal text-gray-500">{S.settings.languageHint}</span>
            </label>
            {save(S.settings.saveSettings)}
          </fieldset>
        </form>
      )}

      {tab === 'contact' && (
        <form action={saveCenterSettings} className={card}>
          {hidden}
          <fieldset disabled={!isAdmin} className="flex flex-col gap-3">
            <h2 className="font-semibold">{S.settings.contact}</h2>
            <label className={label}>
              {S.settings.countryCode}
              <input name="phone_country_code" dir="ltr" defaultValue={settings.get('phone_country_code') ?? ''} className={input} />
            </label>
            <label className={label}>
              {S.settings.whatsapp}
              <input name="whatsapp_group_link" dir="ltr" defaultValue={settings.get('whatsapp_group_link') ?? ''} className={input} />
            </label>
            <label className={label}>
              {S.settings.locationLabel}
              <input name="center_location_label" defaultValue={settings.get('center_location_label') ?? ''} className={input} />
            </label>
            <div className="grid grid-cols-2 gap-3">
              <label className={label}>
                {S.settings.lat}
                <input name="prayer_lat" dir="ltr" defaultValue={settings.get('prayer_lat') ?? ''} className={input} />
              </label>
              <label className={label}>
                {S.settings.lng}
                <input name="prayer_lng" dir="ltr" defaultValue={settings.get('prayer_lng') ?? ''} className={input} />
              </label>
            </div>
            <label className={label}>
              {S.settings.method}
              <select name="prayer_calc_method" defaultValue={settings.get('prayer_calc_method') ?? 'umm_al_qura'} className={input}>
                {PRAYER_METHODS.map((value) => (
                  <option key={value} value={value}>
                    {S.settings.prayerMethods[value]}
                  </option>
                ))}
              </select>
            </label>
            <label className={label}>
              {S.settings.madhab}
              <select name="prayer_madhab" defaultValue={settings.get('prayer_madhab') ?? 'shafi'} className={input}>
                <option value="shafi">{S.settings.majority}</option>
                <option value="hanafi">{S.settings.hanafi}</option>
              </select>
            </label>
            {save(S.settings.saveSettings)}
          </fieldset>
        </form>
      )}

      {tab === 'quran' && (
        <form action={saveCenterSettings} className={card}>
          {hidden}
          <input type="hidden" name="has_reciters" value="1" />
          <fieldset disabled={!isAdmin} className="flex flex-col gap-3">
            <h2 className="font-semibold">{S.settings.quranTitle}</h2>
            <div className={label}>
              {S.settings.reciters}
              <div className="mt-1 flex flex-wrap gap-2 font-normal">
                {AYAH_RECITERS.map((r) => (
                  <label key={r.id} className="flex items-center gap-1 rounded border px-2 py-1">
                    <input type="checkbox" name="quran_reciters" value={r.id} defaultChecked={(settings.get('quran_reciters') ?? '').split(',').includes(r.id)} /> {reciterLabel(r)}
                  </label>
                ))}
              </div>
            </div>
            <label className={label}>
              {S.settings.defaultReciter}
              <select name="quran_default_reciter" defaultValue={settings.get('quran_default_reciter') ?? ''} className={input}>
                <option value="">{S.settings.firstInList}</option>
                {AYAH_RECITERS.map((r) => (
                  <option key={r.id} value={r.id}>
                    {reciterLabel(r)}
                  </option>
                ))}
              </select>
            </label>
            {save(S.settings.saveSettings)}
          </fieldset>
        </form>
      )}

      {tab === 'more' && isAdmin && (
        <>
          <section className="rounded-lg border bg-white p-5">
            <h2 className="mb-1 font-semibold">{S.settings.notifTitle}</h2>
            <p className="mb-3 text-sm text-gray-500">{S.settings.notifHint}</p>
            <a href={'/notifications?tab=settings' as never} className="inline-block rounded border px-4 py-2 text-sm text-brand hover:bg-gray-50">
              {S.settings.notifLink}
            </a>
          </section>
          <section className="rounded-lg border bg-white p-5">
            <h2 className="mb-1 font-semibold">{S.settings.backupTitle}</h2>
            <p className="mb-3 text-sm text-gray-500">{S.settings.backupHint}</p>
            <a href={`/api/backup?org=${org.id}` as never} className="inline-block rounded border px-4 py-2 text-sm text-brand hover:bg-gray-50">
              {S.settings.backupBtn}
            </a>
          </section>
        </>
      )}

      {!isAdmin && <p className="text-xs text-gray-400">{S.settings.adminOnly}</p>}
    </div>
  );
}
