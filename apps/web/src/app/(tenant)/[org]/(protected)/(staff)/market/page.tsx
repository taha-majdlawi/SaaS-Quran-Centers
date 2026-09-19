import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { PURCHASE_LABELS, PURCHASE_STYLES, fmtDate, money, type MarketItem, type Purchase, type Wallet } from '@/lib/engagement/format';
import { saveConfig, setPurchase } from './actions';

const field = 'mt-1 rounded border px-3 py-2 text-sm';

interface Overview {
  enabled: boolean;
  config: { points_per_unit: number; unit_value: number; currency_symbol: string };
  items: MarketItem[];
  purchases: Purchase[];
}

interface WalletRow extends Wallet {
  student_id: string;
  student_name: string;
  student_code: string;
}

const OK: Record<string, string> = {
  item: 'تم حفظ العنصر ✓',
  deleted: 'تم حذف العنصر',
  config: 'تم حفظ سعر التحويل ✓',
  purchase: 'تم تحديث الطلب ✓',
};

export default async function MarketPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ tab?: string; ok?: string; error?: string }>;
}) {
  const { org: slug } = await params;
  const { tab, ok, error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  if (org.myRole !== 'admin') {
    return <p className="rounded-lg border bg-white p-6 text-sm text-gray-500">إدارة السوق للمدير فقط.</p>;
  }

  const [{ data }, { data: wallets }] = await Promise.all([
    supabase.rpc('admin_market_overview', { p_org: org.id }),
    tab === 'wallets' ? supabase.rpc('admin_market_wallets', { p_org: org.id }) : Promise.resolve({ data: [] }),
  ]);
  const o = data as Overview | null;
  if (!o) return <p className="text-sm text-red-600">{error ?? 'تعذّر التحميل'}</p>;
  const sym = o.config.currency_symbol;
  const pending = o.purchases.filter((p) => p.status === 'pending').length;

  return (
    <div className="max-w-4xl">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-bold">سوق النقاط</h1>
        <a href="/market/new" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
          + عنصر جديد
        </a>
      </div>
      {ok && OK[ok] && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{OK[ok]}</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {!o.enabled && (
        <p className="mb-4 rounded bg-amber-50 px-3 py-2 text-sm text-amber-800">
          السوق معطّل حاليًا (يُفعَّل من إعدادات المركز → المزايا). الطلاب لا يستطيعون الشراء.
        </p>
      )}

      <div className="mb-4 flex gap-2 text-sm">
        {[
          ['', `العناصر والطلبات${pending ? ` (${pending})` : ''}`],
          ['wallets', 'أرصدة الطلاب'],
        ].map(([v, l]) => (
          <a key={v} href={`/market${v ? `?tab=${v}` : ''}` as never} className={`rounded-full border px-3 py-1 ${(tab ?? '') === v ? 'bg-brand text-white' : 'bg-white'}`}>
            {l}
          </a>
        ))}
      </div>

      {tab === 'wallets' ? (
        <div className="overflow-hidden rounded-lg border bg-white">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-right">
              <tr>
                <th className="px-4 py-2">الطالب</th>
                <th className="px-4 py-2">النقاط</th>
                <th className="px-4 py-2">الرصيد</th>
                <th className="px-4 py-2">المصروف</th>
              </tr>
            </thead>
            <tbody>
              {((wallets ?? []) as WalletRow[]).map((w) => (
                <tr key={w.student_id} className="border-t">
                  <td className="px-4 py-2">
                    {w.student_name} <span className="text-xs text-gray-500">{w.student_code}</span>
                  </td>
                  <td className="px-4 py-2">{w.earned_points}</td>
                  <td className="px-4 py-2 font-semibold text-brand">{money(w.balance, sym)}</td>
                  <td className="px-4 py-2">{money(w.spent, sym)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <>
          <form action={saveConfig} className="mb-6 flex flex-wrap items-end gap-3 rounded-lg border bg-white p-4">
            <input type="hidden" name="orgId" value={org.id} />
            <label className="text-xs text-gray-600">
              كل (نقطة)
              <input type="number" name="pointsPerUnit" min={1} defaultValue={o.config.points_per_unit} className={`block w-28 ${field}`} />
            </label>
            <label className="text-xs text-gray-600">
              = (قيمة)
              <input type="number" name="unitValue" min={0.01} step="0.01" defaultValue={o.config.unit_value} className={`block w-28 ${field}`} />
            </label>
            <label className="text-xs text-gray-600">
              رمز العملة
              <input name="symbol" maxLength={8} defaultValue={sym} className={`block w-20 ${field}`} />
            </label>
            <SubmitButton className="rounded border px-4 py-2 text-sm text-brand" pendingText="...">
              حفظ سعر التحويل
            </SubmitButton>
            <p className="w-full text-xs text-gray-500">
              تغيير السعر يسري على النقاط التي تُحوَّل بعده فقط؛ ما تحوّل سابقًا يبقى بقيمته وقت تحويله.
            </p>
          </form>

          <h2 className="mb-2 font-semibold">العناصر</h2>
          <div className="mb-8 grid gap-3 sm:grid-cols-2">
            {o.items.map((i) => (
              <a key={i.id} href={`/market/${i.id}` as never} className={`rounded-lg border bg-white p-4 text-sm hover:bg-gray-50 ${i.is_active ? '' : 'opacity-60'}`}>
                <div className="flex items-center justify-between">
                  <b>{i.name}</b>
                  <span className="text-brand">{money(i.price, sym)}</span>
                </div>
                {i.description && <p className="mt-1 text-xs text-gray-500">{i.description}</p>}
                <p className="mt-1 text-xs text-gray-500">
                  {i.stock == null ? 'مخزون غير محدود' : `المخزون: ${i.stock}`}
                  {!i.is_active && ' · غير فعّال'}
                </p>
              </a>
            ))}
            {!o.items.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا توجد عناصر بعد</p>}
          </div>

          <h2 className="mb-2 font-semibold">طلبات الشراء</h2>
          <div className="flex flex-col gap-2">
            {o.purchases.map((p) => (
              <div key={p.id} className="flex flex-wrap items-center justify-between gap-2 rounded-lg border bg-white p-3 text-sm">
                <div>
                  <b>{p.item_name}</b> — {p.student_name} <span className="text-xs text-gray-500">({p.student_code})</span>
                  <p className="text-xs text-gray-500">
                    {money(p.spent, sym)} · {fmtDate(p.created_at)}
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <span className={`rounded px-2 py-0.5 text-xs ${PURCHASE_STYLES[p.status]}`}>{PURCHASE_LABELS[p.status]}</span>
                  {p.status === 'pending' && (
                    <>
                      <form action={setPurchase}>
                        <input type="hidden" name="id" value={p.id} />
                        <input type="hidden" name="status" value="fulfilled" />
                        <SubmitButton className="rounded bg-brand px-3 py-1 text-xs font-semibold text-white" pendingText="...">
                          تم التسليم
                        </SubmitButton>
                      </form>
                      <form action={setPurchase}>
                        <input type="hidden" name="id" value={p.id} />
                        <input type="hidden" name="status" value="cancelled" />
                        <ConfirmSubmitButton confirmMessage="إلغاء الطلب؟ يُعاد الرصيد والمخزون." pendingText="..." className="rounded border border-red-200 px-3 py-1 text-xs text-red-600">
                          إلغاء
                        </ConfirmSubmitButton>
                      </form>
                    </>
                  )}
                  {p.status === 'fulfilled' && (
                    <form action={setPurchase}>
                      <input type="hidden" name="id" value={p.id} />
                      <input type="hidden" name="status" value="cancelled" />
                      <ConfirmSubmitButton confirmMessage="إلغاء طلب تم تسليمه؟ يُعاد الرصيد والمخزون." pendingText="..." className="rounded border border-red-200 px-3 py-1 text-xs text-red-600">
                        إلغاء
                      </ConfirmSubmitButton>
                    </form>
                  )}
                </div>
              </div>
            ))}
            {!o.purchases.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا توجد طلبات</p>}
          </div>
        </>
      )}
    </div>
  );
}
