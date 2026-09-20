import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { Flash, btn, field } from '@/components/platform-flash';
import { deletePlan, savePlan } from '@/lib/platform/actions';
import { FEATURES } from '@/lib/platform/labels';

interface Plan {
  id: string;
  code: string;
  name: string;
  price_cents: number;
  currency: string;
  limits: { max_students?: number | null; max_teachers?: number | null };
  features: Record<string, boolean>;
  is_active: boolean;
}

function PlanForm({ plan }: { plan?: Plan }) {
  return (
    <form action={savePlan} className="grid gap-3 rounded-lg border bg-white p-4 sm:grid-cols-4">
      {plan && <input type="hidden" name="id" value={plan.id} />}
      <label className="text-sm">
        الرمز
        <input name="code" required defaultValue={plan?.code} dir="ltr" pattern="[a-z0-9_\-]{2,30}" className={field} />
      </label>
      <label className="text-sm">
        الاسم
        <input name="name" required defaultValue={plan?.name} className={field} />
      </label>
      <label className="text-sm">
        السعر الشهري
        <input name="price" type="number" step="0.01" min="0" defaultValue={plan ? plan.price_cents / 100 : 0} className={field} />
      </label>
      <label className="text-sm">
        العملة
        <input name="currency" defaultValue={plan?.currency ?? 'USD'} dir="ltr" className={field} />
      </label>
      <label className="text-sm">
        أقصى طلاب (فارغ = بلا حد)
        <input name="maxStudents" type="number" min="0" defaultValue={plan?.limits?.max_students ?? ''} className={field} />
      </label>
      <label className="text-sm">
        أقصى معلمين (فارغ = بلا حد)
        <input name="maxTeachers" type="number" min="0" defaultValue={plan?.limits?.max_teachers ?? ''} className={field} />
      </label>
      <label className="flex items-center gap-2 self-end text-sm">
        <input type="checkbox" name="active" defaultChecked={plan?.is_active ?? true} /> فعّالة
      </label>
      <div className="sm:col-span-4">
        <p className="mb-1 text-xs text-gray-500">ميزات الخطة (عند اختيار «مغلقة» تُعطَّل لمراكز هذه الخطة ما لم يُستثنَ المركز):</p>
        <div className="flex flex-wrap gap-2">
          {FEATURES.map(([k, l]) => (
            <label key={k} className="flex items-center gap-1 rounded border px-2 py-1 text-xs">
              {l}
              <select name={`pf_${k}`} defaultValue={plan?.features?.[k] === false ? 'off' : plan?.features?.[k] === true ? 'on' : ''} className="rounded border text-xs">
                <option value="">—</option>
                <option value="on">مفتوحة</option>
                <option value="off">مغلقة</option>
              </select>
            </label>
          ))}
        </div>
      </div>
      <div className="sm:col-span-4">
        <SubmitButton className={btn} pendingText="جاري الحفظ...">
          {plan ? 'حفظ الخطة' : 'إضافة خطة'}
        </SubmitButton>
      </div>
    </form>
  );
}

export default async function PlansPage({ searchParams }: { searchParams: Promise<{ ok?: string; error?: string }> }) {
  const { ok, error } = await searchParams;
  const supabase = await createClient();
  const { data } = await supabase.from('plans').select('id, code, name, price_cents, currency, limits, features, is_active').order('price_cents');
  const plans = (data ?? []) as Plan[];

  return (
    <div className="max-w-5xl">
      <h1 className="mb-1 text-2xl font-bold">الخطط والحدود</h1>
      <p className="mb-4 text-sm text-gray-500">حد الطلاب والمعلمين يُطبَّق فعليًا: لا يُقبل طالب جديد بعد بلوغ الحد.</p>
      <Flash ok={ok} error={error} />
      <div className="flex flex-col gap-4">
        {plans.map((p) => (
          <div key={p.id}>
            <PlanForm plan={p} />
            <form action={deletePlan} className="mt-1 text-left">
              <input type="hidden" name="id" value={p.id} />
              <ConfirmSubmitButton confirmMessage={`حذف خطة ${p.name}؟`} pendingText="..." className="text-xs text-red-600 hover:underline">
                حذف هذه الخطة
              </ConfirmSubmitButton>
            </form>
          </div>
        ))}
        <h2 className="mt-4 font-semibold">خطة جديدة</h2>
        <PlanForm />
      </div>
    </div>
  );
}
