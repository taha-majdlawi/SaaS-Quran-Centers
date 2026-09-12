import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { savePointsConfig } from './actions';

interface PointsRules {
  new_memorization?: number;
  recent_review?: number;
  distant_review?: number;
}

export default async function PointsPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string; saved?: string }>;
}) {
  const { org: slug } = await params;
  const { error, saved } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const [{ data: pointsConfig }, { data: currencyConfig }] = await Promise.all([
    supabase.from('points_config').select('rules').eq('organization_id', org.id).maybeSingle(),
    supabase.from('currency_config').select('currency_name, exchange_rate').eq('organization_id', org.id).maybeSingle(),
  ]);

  const rules = (pointsConfig?.rules ?? {}) as PointsRules;
  const isAdmin = org.myRole === 'admin';

  return (
    <div className="max-w-lg">
      <h1 className="mb-1 text-2xl font-bold">النقاط</h1>
      <p className="mb-6 text-sm text-gray-500">عدد النقاط الممنوحة لكل نوع تسميع، واسم عملة النقاط بالمركز.</p>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {saved && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم حفظ الإعدادات</p>}

      <form action={savePointsConfig} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />
        <fieldset disabled={!isAdmin} className="flex flex-col gap-3">
          <label className="text-sm font-medium text-gray-700">
            نقاط الحفظ الجديد
            <input
              type="number"
              name="newMemorization"
              defaultValue={rules.new_memorization ?? 10}
              className="mt-1 w-full rounded border px-3 py-2 text-sm"
            />
          </label>

          <label className="text-sm font-medium text-gray-700">
            نقاط المراجعة القريبة
            <input
              type="number"
              name="recentReview"
              defaultValue={rules.recent_review ?? 5}
              className="mt-1 w-full rounded border px-3 py-2 text-sm"
            />
          </label>

          <label className="text-sm font-medium text-gray-700">
            نقاط المراجعة البعيدة
            <input
              type="number"
              name="distantReview"
              defaultValue={rules.distant_review ?? 3}
              className="mt-1 w-full rounded border px-3 py-2 text-sm"
            />
          </label>

          <hr className="my-2" />

          <label className="text-sm font-medium text-gray-700">
            اسم عملة النقاط
            <input
              name="currencyName"
              defaultValue={currencyConfig?.currency_name ?? 'نقاط'}
              className="mt-1 w-full rounded border px-3 py-2 text-sm"
            />
          </label>

          {isAdmin && (
            <SubmitButton
              className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
              pendingText="جاري الحفظ..."
            >
              حفظ الإعدادات
            </SubmitButton>
          )}
        </fieldset>
      </form>

      {!isAdmin && <p className="mt-3 text-xs text-gray-400">بس المدير يقدر يعدّل إعدادات النقاط.</p>}
    </div>
  );
}
