import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { PURCHASE_LABELS, PURCHASE_STYLES, fmtDate, money, type MarketItem, type Purchase, type Wallet } from '@/lib/engagement/format';
import { buy, cancelPurchase } from './actions';

interface Market {
  enabled: boolean;
  symbol: string;
  wallet: Wallet;
  items: MarketItem[];
  purchases: Purchase[];
}

const OK: Record<string, string> = { bought: 'تم الطلب ✓ سيُسلَّم من المركز', cancelled: 'أُلغي الطلب وعاد الرصيد' };

export default async function MyMarketPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ ok?: string; error?: string; s?: string }>;
}) {
  const { org: slug } = await params;
  const { ok, error, s } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data: students } = await supabase.from('students_profile').select('id, full_name').eq('organization_id', org.id).order('full_name');
  const list = (students ?? []) as { id: string; full_name: string }[];
  const current = list.find((x) => x.id === s) ?? list[0];
  const { data } = current ? await supabase.rpc('get_student_market', { p_org: org.id, p_student: current.id }) : { data: null };
  const m = data as Market | null;
  const back = `/my/market?s=${current?.id ?? ''}`;

  return (
    <div className="mx-auto max-w-3xl p-6">
      <a href="/my" className="text-sm text-brand hover:underline">
        ← ملفي
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">سوق النقاط</h1>
      {list.length > 1 && (
        <div className="mb-4 flex flex-wrap gap-2 text-sm">
          {list.map((x) => (
            <a key={x.id} href={`/my/market?s=${x.id}` as never} className={`rounded-full border px-3 py-1 ${x.id === current?.id ? 'bg-brand text-white' : 'bg-white'}`}>
              {x.full_name}
            </a>
          ))}
        </div>
      )}
      {ok && OK[ok] && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{OK[ok]}</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      {!m ? (
        <p className="text-sm text-gray-500">لا يوجد ملف طالب مرتبط.</p>
      ) : !m.enabled ? (
        <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-500">السوق غير مفعّل في مركزك حاليًا.</p>
      ) : (
        <>
          <div className="mb-6 rounded-lg bg-brand p-5 text-white">
            <p className="text-sm opacity-85">رصيد {current?.full_name}</p>
            <p className="text-3xl font-bold">{money(m.wallet.balance, m.symbol)}</p>
            <p className="mt-1 text-xs opacity-80">
              من {m.wallet.earned_points} نقطة · المصروف {money(m.wallet.spent, m.symbol)}
              {m.wallet.pending_points > 0 && ` · ${m.wallet.pending_points} نقطة تنتظر اكتمال وحدة تحويل`}
            </p>
          </div>

          <h2 className="mb-2 font-semibold">المتاح للشراء</h2>
          <div className="mb-8 grid gap-3 sm:grid-cols-2">
            {m.items.map((i) => {
              const afford = m.wallet.balance >= i.price;
              const out = i.stock != null && i.stock <= 0;
              return (
                <div key={i.id} className="rounded-lg border bg-white p-4 text-sm">
                  {i.image_url && (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={i.image_url} alt="" className="mb-2 h-36 w-full rounded object-cover" />
                  )}
                  <div className="flex items-center justify-between">
                    <b>{i.name}</b>
                    <span className="font-semibold text-brand">{money(i.price, m.symbol)}</span>
                  </div>
                  {i.description && <p className="mt-1 text-xs text-gray-500">{i.description}</p>}
                  {i.stock != null && <p className="mt-1 text-xs text-gray-500">المتبقي: {i.stock}</p>}
                  <form action={buy} className="mt-3">
                    <input type="hidden" name="orgId" value={org.id} />
                    <input type="hidden" name="studentId" value={current!.id} />
                    <input type="hidden" name="itemId" value={i.id} />
                    <input type="hidden" name="back" value={back} />
                    <SubmitButton className={`rounded px-4 py-1.5 font-semibold ${afford && !out ? 'bg-brand text-white' : 'bg-gray-200 text-gray-500'}`} pendingText="...">
                      {out ? 'نفد' : afford ? 'شراء' : 'الرصيد لا يكفي'}
                    </SubmitButton>
                  </form>
                </div>
              );
            })}
            {!m.items.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا توجد عناصر حاليًا</p>}
          </div>

          <h2 className="mb-2 font-semibold">طلباتي</h2>
          <div className="flex flex-col gap-2">
            {m.purchases.map((p) => (
              <div key={p.id} className="flex flex-wrap items-center justify-between gap-2 rounded-lg border bg-white p-3 text-sm">
                <span>
                  <b>{p.item_name}</b> <span className="text-xs text-gray-500">{money(p.spent, m.symbol)} · {fmtDate(p.created_at)}</span>
                </span>
                <span className="flex items-center gap-2">
                  <span className={`rounded px-2 py-0.5 text-xs ${PURCHASE_STYLES[p.status]}`}>{PURCHASE_LABELS[p.status]}</span>
                  {p.status === 'pending' && (
                    <form action={cancelPurchase}>
                      <input type="hidden" name="id" value={p.id} />
                      <input type="hidden" name="back" value={back} />
                      <ConfirmSubmitButton confirmMessage="إلغاء الطلب؟" pendingText="..." className="rounded border border-red-200 px-2 py-1 text-xs text-red-600">
                        إلغاء
                      </ConfirmSubmitButton>
                    </form>
                  )}
                </span>
              </div>
            ))}
            {!m.purchases.length && <p className="text-sm text-gray-400">لا توجد طلبات بعد</p>}
          </div>
        </>
      )}
    </div>
  );
}
