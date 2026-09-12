import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { recordPurchase, adjustPoints } from './actions';

export default async function MarketPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string; purchased?: string; adjusted?: string }>;
}) {
  const { org: slug } = await params;
  const { error, purchased, adjusted } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const [{ data: items }, { data: students }, { data: wallets }] = await Promise.all([
    supabase
      .from('market_items')
      .select('id, name, cost, stock, is_active')
      .eq('organization_id', org.id)
      .order('name'),
    supabase
      .from('students_profile')
      .select('id, full_name')
      .eq('organization_id', org.id)
      .eq('status', 'active')
      .order('full_name'),
    supabase.from('student_wallets').select('student_id, balance').eq('organization_id', org.id),
  ]);

  const balanceByStudent = new Map((wallets ?? []).map((w) => [w.student_id, w.balance]));

  return (
    <div className="flex flex-col gap-8">
      <div>
        <div className="mb-4 flex items-center justify-between">
          <h1 className="text-2xl font-bold">سوق النقاط</h1>
          <a href="/market/new" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
            + إضافة عنصر
          </a>
        </div>

        {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
        {purchased && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم تسجيل الشراء</p>}
        {adjusted && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم تعديل الرصيد</p>}

        <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
          <thead className="bg-gray-50 text-right">
            <tr>
              <th className="px-4 py-2">العنصر</th>
              <th className="px-4 py-2">التكلفة</th>
              <th className="px-4 py-2">المخزون</th>
              <th className="px-4 py-2">الحالة</th>
              <th className="px-4 py-2"></th>
            </tr>
          </thead>
          <tbody>
            {(items ?? []).map((i) => (
              <tr key={i.id} className="border-t">
                <td className="px-4 py-2">{i.name}</td>
                <td className="px-4 py-2">{i.cost}</td>
                <td className="px-4 py-2">{i.stock ?? 'غير محدود'}</td>
                <td className="px-4 py-2">{i.is_active ? 'مفعّل' : 'متوقف'}</td>
                <td className="px-4 py-2 text-left">
                  <a href={`/market/${i.id}`} className="text-brand hover:underline">
                    تعديل
                  </a>
                </td>
              </tr>
            ))}
            {!items?.length && (
              <tr>
                <td colSpan={5} className="px-4 py-6 text-center text-gray-400">
                  لا يوجد عناصر بعد
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {Boolean(items?.length) && Boolean(students?.length) && (
        <div>
          <h2 className="mb-4 text-lg font-bold">تسجيل عملية شراء</h2>
          <form
            action={recordPurchase}
            className="flex flex-wrap items-end gap-3 rounded-lg border bg-white p-4 text-sm"
          >
            <input type="hidden" name="orgId" value={org.id} />
            <label>
              الطالب
              <select name="studentId" required className="mt-1 block rounded border px-3 py-2">
                <option value="" disabled>
                  اختر الطالب
                </option>
                {(students ?? []).map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.full_name} ({balanceByStudent.get(s.id) ?? 0} نقطة)
                  </option>
                ))}
              </select>
            </label>
            <label>
              العنصر
              <select name="itemId" required className="mt-1 block rounded border px-3 py-2">
                <option value="" disabled>
                  اختر العنصر
                </option>
                {(items ?? [])
                  .filter((i) => i.is_active)
                  .map((i) => (
                    <option key={i.id} value={i.id}>
                      {i.name} ({i.cost} نقطة)
                    </option>
                  ))}
              </select>
            </label>
            <SubmitButton
              className="rounded bg-brand px-4 py-2 font-semibold text-white disabled:opacity-50"
              pendingText="جاري التسجيل..."
            >
              تسجيل الشراء
            </SubmitButton>
          </form>
        </div>
      )}

      {Boolean(students?.length) && (
        <div>
          <h2 className="mb-4 text-lg font-bold">تعديل رصيد يدويًا</h2>
          <form action={adjustPoints} className="flex flex-wrap items-end gap-3 rounded-lg border bg-white p-4 text-sm">
            <input type="hidden" name="orgId" value={org.id} />
            <label>
              الطالب
              <select name="studentId" required className="mt-1 block rounded border px-3 py-2">
                <option value="" disabled>
                  اختر الطالب
                </option>
                {(students ?? []).map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.full_name} ({balanceByStudent.get(s.id) ?? 0} نقطة)
                  </option>
                ))}
              </select>
            </label>
            <label>
              الكمية (بالسالب للخصم)
              <input
                type="number"
                name="amount"
                required
                defaultValue={10}
                className="mt-1 block rounded border px-3 py-2"
              />
            </label>
            <SubmitButton
              className="rounded border border-gray-300 px-4 py-2 font-semibold text-gray-700 hover:bg-gray-50 disabled:opacity-50"
              pendingText="جاري التعديل..."
            >
              تعديل الرصيد
            </SubmitButton>
          </form>
        </div>
      )}
    </div>
  );
}
