import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { Flash, btn } from '@/components/platform-flash';
import { saveFeatures } from '@/lib/platform/actions';
import { FEATURES } from '@/lib/platform/labels';

export default async function FeatureFlagsPage({ searchParams }: { searchParams: Promise<{ ok?: string; error?: string }> }) {
  const { ok, error } = await searchParams;
  const supabase = await createClient();
  const { data } = await supabase.from('feature_flags').select('key, enabled').is('organization_id', null);
  const current = new Map((data ?? []).map((f) => [f.key as string, f.enabled as boolean]));

  return (
    <div className="max-w-3xl">
      <h1 className="mb-1 text-2xl font-bold">مفاتيح الميزات (لكل المنصة)</h1>
      <p className="mb-4 text-sm text-gray-500">
        الترتيب: استثناء المركز ← إعداد المنصة هنا ← خطة المركز ← مفعّلة. التعطيل يخفي الميزة في الويب والجوال ويمنعها في قاعدة البيانات. لاستثناء مركز بعينه افتح صفحته.
      </p>
      <Flash ok={ok} error={error} />
      <form action={saveFeatures} className="rounded-lg border bg-white p-4">
        <div className="grid gap-2 sm:grid-cols-2">
          {FEATURES.map(([key, label]) => {
            const v = current.get(key);
            return (
              <label key={key} className="flex items-center justify-between gap-2 rounded border px-3 py-2 text-sm">
                {label}
                <select name={`f_${key}`} defaultValue={v === true ? 'on' : v === false ? 'off' : ''} className="rounded border px-1 py-0.5 text-xs">
                  <option value="">افتراضي (مفعّلة)</option>
                  <option value="on">مفعّلة للجميع</option>
                  <option value="off">معطّلة للجميع</option>
                </select>
              </label>
            );
          })}
        </div>
        <div className="mt-3">
          <SubmitButton className={btn} pendingText="جاري الحفظ...">
            حفظ
          </SubmitButton>
        </div>
      </form>
    </div>
  );
}
