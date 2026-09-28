import { notFound, redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { MarketItemForm } from '@/components/market-item-form';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { deleteItem } from '../actions';
import { getI18n } from '@/lib/i18n/server';

export default async function EditMarketItemPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug, id } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  if (org.myRole !== 'admin') redirect('/market' as never);
  const supabase = await createClient();

  const [{ data: item }, { data: cfg }] = await Promise.all([
    supabase.from('market_items').select('id, name, description, image_url, price_currency, stock, is_active').eq('id', id).eq('organization_id', org.id).maybeSingle(),
    supabase.from('market_config').select('currency_symbol').eq('organization_id', org.id).maybeSingle(),
  ]);
  if (!item) notFound();

  return (
    <div>
      <a href="/market" className="text-sm text-brand hover:underline">
        {S.market.back}
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">{S.market.editTitle}</h1>
      <MarketItemForm orgId={org.id} symbol={cfg?.currency_symbol ?? ''} error={error} item={{ ...item, price: Number(item.price_currency) }} />
      <form action={deleteItem} className="mt-4">
        <input type="hidden" name="orgId" value={org.id} />
        <input type="hidden" name="id" value={id} />
        <ConfirmSubmitButton confirmMessage={S.market.deleteConfirm} pendingText={S.common.deleting} className="rounded border border-red-200 px-4 py-2 text-sm text-red-600 hover:bg-red-50">
          {S.common.delete}
        </ConfirmSubmitButton>
      </form>
    </div>
  );
}
