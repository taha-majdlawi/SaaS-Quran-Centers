import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { LogoField } from '@/components/logo-field';
import { RECITERS } from '@/lib/quran/reader';
import { updateOrgSettings, saveWeekdays, saveCenterSettings } from './actions';
import { getI18n } from '@/lib/i18n/server';

const DAYS = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

const PRAYER_METHODS: [string, string][] = [
  ['umm_al_qura', 'أم القرى'],
  ['muslim_world_league', 'رابطة العالم الإسلامي'],
  ['egyptian', 'الهيئة المصرية'],
  ['karachi', 'كراتشي'],
  ['dubai', 'دبي'],
  ['qatar', 'قطر'],
  ['kuwait', 'الكويت'],
  ['moon_sighting_committee', 'لجنة رؤية الهلال'],
  ['singapore', 'سنغافورة'],
  ['turkey', 'تركيا'],
  ['tehran', 'طهران'],
  ['north_america', 'أمريكا الشمالية'],
];

const input = 'mt-1 w-full rounded border px-3 py-2 text-sm';
const label = 'text-sm font-medium text-gray-700';

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
  searchParams: Promise<{ error?: string; saved?: string }>;
}) {
  const { org: slug } = await params;
  const { error, saved } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const isAdmin = org.myRole === 'admin';
  const supabase = await createClient();

  const [{ data: weekdayRows }, { data: settingRows }] = await Promise.all([
    supabase.from('center_weekdays').select('dow, label, is_working, is_serd_day').eq('organization_id', org.id).order('dow'),
    supabase.from('organization_settings').select('key, value').eq('organization_id', org.id),
  ]);
  const weekdays = (weekdayRows ?? []) as Weekday[];
  const settings = new Map((settingRows ?? []).map((r) => [r.key as string, (r.value as string | null) ?? '']));
  const flag = (key: string) => (settings.get(key) ?? 'true') !== 'false';

  return (
    <div className="flex max-w-2xl flex-col gap-8">
      <div>
        <h1 className="mb-1 text-2xl font-bold">إعدادات المركز</h1>
        <p className="mb-6 text-sm text-gray-500">كل ما يخص مركزك: الهوية، أيام الدوام، ومفاتيح الميزات.</p>

        {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
        {saved && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم حفظ الإعدادات</p>}

        <form action={updateOrgSettings} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
          <input type="hidden" name="orgId" value={org.id} />
          <fieldset disabled={!isAdmin} className="flex flex-col gap-3">
            <h2 className="font-semibold">الهوية</h2>
            <label className={label}>
              اسم المركز
              <input name="name" required defaultValue={org.name} className={input} />
            </label>
            <LogoField orgId={org.id} initialUrl={org.logoUrl} name={org.name} labels={S.image} />
            <label className={label}>
              اللون الأساسي
              <input type="color" name="primaryColor" defaultValue={org.primaryColor} className="mt-1 h-10 w-full rounded border" />
            </label>
            <label className={label}>
              اللون الثانوي
              <input type="color" name="secondaryColor" defaultValue={org.secondaryColor} className="mt-1 h-10 w-full rounded border" />
            </label>
            <label className={label}>
              رابط المركز
              <input value={`${org.slug}.bustan-alquran.com`} disabled dir="ltr" className="mt-1 w-full rounded border bg-gray-50 px-3 py-2 text-sm text-gray-500" />
            </label>
            <label className={label}>
              المنطقة الزمنية
              <input name="timezone" defaultValue="Asia/Amman" className={input} />
            </label>
            {isAdmin && (
              <SubmitButton className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50" pendingText="جاري الحفظ...">
                حفظ الهوية
              </SubmitButton>
            )}
          </fieldset>
        </form>
      </div>

      <form action={saveWeekdays} className="rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />
        <fieldset disabled={!isAdmin} className="flex flex-col gap-3">
          <h2 className="font-semibold">أيام الدوام</h2>
          <p className="text-xs text-gray-500">
            نسبة حضور الطالب تُحسب على أيام الدوام فقط. يوم السرد يجب أن يكون يوم دوام.
          </p>
          <div className="grid grid-cols-[1fr_5rem_5rem] gap-3 text-xs font-semibold text-gray-500">
            <span>اليوم</span>
            <span>دوام</span>
            <span>يوم سرد</span>
          </div>
          {weekdays.map((d) => (
            <div key={d.dow} className="grid grid-cols-[1fr_5rem_5rem] items-center gap-3">
              <input type="hidden" name={`label_${d.dow}`} value={d.label} />
              <span className="text-sm">{d.label}</span>
              <input type="checkbox" name={`working_${d.dow}`} defaultChecked={d.is_working} className="h-4 w-4" />
              <input type="checkbox" name={`serd_${d.dow}`} defaultChecked={d.is_serd_day} className="h-4 w-4" />
            </div>
          ))}
          {isAdmin && (
            <SubmitButton className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50" pendingText="جاري الحفظ...">
              حفظ أيام الدوام
            </SubmitButton>
          )}
        </fieldset>
      </form>

      <form action={saveCenterSettings} className="rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />
        <fieldset disabled={!isAdmin} className="flex flex-col gap-3">
          <h2 className="font-semibold">التسميع والميزات</h2>
          <label className={label}>
            أقصى رجوع بتاريخ التسميع (أيام)
            <input type="number" name="backdate_days" min={0} max={365} defaultValue={settings.get('backdate_days') ?? '60'} className={input} />
          </label>
          <label className="flex items-center gap-2 text-sm text-gray-700">
            <input type="checkbox" name="flag_market_enabled" defaultChecked={flag('flag_market_enabled')} /> تفعيل سوق النقاط
          </label>
          <label className="flex items-center gap-2 text-sm text-gray-700">
            <input type="checkbox" name="flag_leaderboard_enabled" defaultChecked={flag('flag_leaderboard_enabled')} /> تفعيل لوحة الشرف
          </label>
          <label className="flex items-center gap-2 text-sm text-gray-700">
            <input type="checkbox" name="flag_teacher_manage_students" defaultChecked={flag('flag_teacher_manage_students')} /> السماح للمعلم بإضافة طلاب لحلقته
          </label>

          <h2 className="mt-3 font-semibold">التواصل والمواقيت</h2>
          <label className={label}>
            رمز الدولة للهاتف (بدون +)
            <input name="phone_country_code" dir="ltr" defaultValue={settings.get('phone_country_code') ?? ''} className={input} />
          </label>
          <label className={label}>
            رابط مجموعة الواتساب
            <input name="whatsapp_group_link" dir="ltr" defaultValue={settings.get('whatsapp_group_link') ?? ''} className={input} />
          </label>
          <label className={label}>
            اسم الموقع (يظهر مع مواقيت الصلاة)
            <input name="center_location_label" defaultValue={settings.get('center_location_label') ?? ''} className={input} />
          </label>
          <div className="grid grid-cols-2 gap-3">
            <label className={label}>
              خط العرض
              <input name="prayer_lat" dir="ltr" defaultValue={settings.get('prayer_lat') ?? ''} className={input} />
            </label>
            <label className={label}>
              خط الطول
              <input name="prayer_lng" dir="ltr" defaultValue={settings.get('prayer_lng') ?? ''} className={input} />
            </label>
          </div>
          <label className={label}>
            طريقة حساب المواقيت
            <select name="prayer_calc_method" defaultValue={settings.get('prayer_calc_method') ?? 'umm_al_qura'} className={input}>
              {PRAYER_METHODS.map(([value, text]) => (
                <option key={value} value={value}>
                  {text}
                </option>
              ))}
            </select>
          </label>
          <label className={label}>
            المذهب (لصلاة العصر)
            <select name="prayer_madhab" defaultValue={settings.get('prayer_madhab') ?? 'shafi'} className={input}>
              <option value="shafi">الجمهور (شافعي/مالكي/حنبلي)</option>
              <option value="hanafi">حنفي</option>
            </select>
          </label>
          <div className={label}>
            القرّاء المتاحون في المصحف (بلا اختيار = الكل)
            <div className="mt-1 flex flex-wrap gap-2 font-normal">
              {RECITERS.map((r) => (
                <label key={r.id} className="flex items-center gap-1 rounded border px-2 py-1">
                  <input type="checkbox" name="quran_reciters" value={r.id} defaultChecked={(settings.get('quran_reciters') ?? '').split(',').includes(r.id)} /> {r.name}
                </label>
              ))}
            </div>
          </div>
          <label className={label}>
            القارئ الافتراضي
            <select name="quran_default_reciter" defaultValue={settings.get('quran_default_reciter') ?? ''} className={input}>
              <option value="">الأول في القائمة</option>
              {RECITERS.map((r) => (
                <option key={r.id} value={r.id}>
                  {r.name}
                </option>
              ))}
            </select>
          </label>
          {isAdmin && (
            <SubmitButton className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50" pendingText="جاري الحفظ...">
              حفظ الإعدادات
            </SubmitButton>
          )}
        </fieldset>
      </form>

      {isAdmin && (
        <section className="rounded-lg border bg-white p-5">
          <h2 className="mb-1 font-semibold">الإشعارات والتذكيرات</h2>
          <p className="mb-3 text-sm text-gray-500">
            الملخص الأسبوعي للأسر وتذكير المعلم بالحضور وساعات الصمت وقوالب الرسائل كلها في قسم الإشعارات.
          </p>
          <a href={'/notifications?tab=settings' as never} className="inline-block rounded border px-4 py-2 text-sm text-brand hover:bg-gray-50">
            إعدادات الإشعارات
          </a>
        </section>
      )}

      {isAdmin && (
        <section className="rounded-lg border bg-white p-5">
          <h2 className="mb-1 font-semibold">نسخة احتياطية من بيانات المركز</h2>
          <p className="mb-3 text-sm text-gray-500">
            ملف واحد (JSON) فيه الطلاب والحلقات والتسميع والحضور والسرد والتقويم والسوق وغيرها. لا يتضمن كلمات السر ولا بيانات الدخول. احتفظ به في مكان آمن.
          </p>
          <a href={`/api/backup?org=${org.id}` as never} className="inline-block rounded border px-4 py-2 text-sm text-brand hover:bg-gray-50">
            تنزيل النسخة الاحتياطية
          </a>
        </section>
      )}

      {!isAdmin && <p className="text-xs text-gray-400">بس المدير يقدر يعدّل إعدادات المركز.</p>}
    </div>
  );
}
