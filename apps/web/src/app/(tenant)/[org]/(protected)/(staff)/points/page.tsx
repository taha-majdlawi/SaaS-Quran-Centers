import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { saveGrades } from './actions';

interface Grade {
  key: string;
  label: string;
  points: number;
  sort_order: number;
  is_active: boolean;
}

// eqraa hard-codes "excellent 20 / very good 15 / good 10 / acceptable 5".
// Here every center owns its grade names AND points; each recitation freezes
// the points it was worth when logged, so edits never change history.
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
  const isAdmin = org.myRole === 'admin';

  const { data } = await supabase
    .from('recitation_grades')
    .select('key, label, points, sort_order, is_active')
    .eq('organization_id', org.id)
    .order('sort_order');
  const grades = (data ?? []) as Grade[];

  return (
    <div className="max-w-2xl">
      <h1 className="mb-1 text-2xl font-bold">تقديرات التسميع والنقاط</h1>
      <p className="mb-6 text-sm text-gray-500">
        أسماء التقديرات وعدد النقاط لكل تقدير. تُحفظ النقاط على كل تسميع لحظة تسجيله، فتغييرها هنا يسري على التسميعات
        القادمة فقط ولا يعدّل القديمة.
      </p>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {saved && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم حفظ التقديرات</p>}

      <form action={saveGrades} className="rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />
        <fieldset disabled={!isAdmin} className="flex flex-col gap-3">
          <div className="grid grid-cols-[1fr_6rem_5rem] gap-3 text-xs font-semibold text-gray-500">
            <span>اسم التقدير</span>
            <span>النقاط</span>
            <span>مفعّل</span>
          </div>

          {grades.map((g) => (
            <div key={g.key} className="grid grid-cols-[1fr_6rem_5rem] items-center gap-3">
              <input type="hidden" name="key" value={g.key} />
              <input type="hidden" name="sort" value={g.sort_order} />
              <input name="label" defaultValue={g.label} required className="rounded border px-3 py-2 text-sm" />
              <input
                type="number"
                name="points"
                min={0}
                defaultValue={g.points}
                className="rounded border px-3 py-2 text-sm"
              />
              <input type="checkbox" name={`active_${g.key}`} defaultChecked={g.is_active} className="h-4 w-4" />
            </div>
          ))}

          <hr className="my-2" />
          <p className="text-sm font-semibold text-gray-700">إضافة تقدير جديد</p>
          <div className="grid grid-cols-[1fr_1fr_6rem] gap-3">
            <input
              name="newKey"
              placeholder="المفتاح (مثل: outstanding)"
              dir="ltr"
              className="rounded border px-3 py-2 text-sm"
            />
            <input name="newLabel" placeholder="الاسم (مثل: متميز)" className="rounded border px-3 py-2 text-sm" />
            <input type="number" name="newPoints" min={0} placeholder="نقاط" className="rounded border px-3 py-2 text-sm" />
          </div>

          {isAdmin && (
            <SubmitButton
              className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
              pendingText="جاري الحفظ..."
            >
              حفظ التقديرات
            </SubmitButton>
          )}
        </fieldset>
      </form>

      {!isAdmin && <p className="mt-3 text-xs text-gray-400">بس المدير يقدر يعدّل التقديرات والنقاط.</p>}
    </div>
  );
}
