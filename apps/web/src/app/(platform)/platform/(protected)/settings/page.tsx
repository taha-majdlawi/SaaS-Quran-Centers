import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { Flash, btn, field } from '@/components/platform-flash';
import { savePlatformSettings } from '@/lib/platform/actions';

export default async function PlatformSettingsPage({ searchParams }: { searchParams: Promise<{ ok?: string; error?: string }> }) {
  const { ok, error } = await searchParams;
  const supabase = await createClient();
  const [{ data }, { data: plans }] = await Promise.all([supabase.rpc('platform_get_settings'), supabase.from('plans').select('id, name').eq('is_active', true).order('price_cents')]);
  const s = (data ?? { signup_enabled: true, default_plan_id: null, trial_days: 14 }) as { signup_enabled: boolean; default_plan_id: string | null; trial_days: number };

  return (
    <div className="max-w-xl">
      <h1 className="mb-4 text-2xl font-bold">إعدادات المنصة</h1>
      <Flash ok={ok} error={error} />
      <form action={savePlatformSettings} className="flex flex-col gap-4 rounded-lg border bg-white p-4">
        <label className="flex items-center gap-2 text-sm">
          <input type="checkbox" name="signup" defaultChecked={s.signup_enabled} /> السماح للزوّار بإنشاء مراكز بأنفسهم (التسجيل الذاتي)
        </label>
        <label className="text-sm">
          الخطة الافتراضية للمراكز الجديدة
          <select name="defaultPlan" defaultValue={s.default_plan_id ?? ''} className={field}>
            <option value="">بلا خطة (بلا حدود)</option>
            {(plans ?? []).map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </select>
        </label>
        <label className="text-sm">
          مدة التجربة (أيام، 0 = بلا تجربة)
          <input name="trialDays" type="number" min="0" max="365" defaultValue={s.trial_days} className={field} />
        </label>
        <div>
          <SubmitButton className={btn} pendingText="جاري الحفظ...">
            حفظ
          </SubmitButton>
        </div>
      </form>
    </div>
  );
}
