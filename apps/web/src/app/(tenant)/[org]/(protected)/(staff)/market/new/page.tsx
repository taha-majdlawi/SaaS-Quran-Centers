import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { MarketItemForm } from '@/components/market-item-form';
import { getI18n } from '@/lib/i18n/server';

export default async function NewMarketItemPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  if (org.myRole !== 'admin') redirect('/market' as never);
  const supabase = await createClient();
  const { data } = await supabase.from('market_config').select('currency_symbol').eq('organization_id', org.id).maybeSingle();

  return (
    <div>
      <a href="/market" className="text-sm text-brand hover:underline">
        {S.market.back}
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">{S.market.newTitle}</h1>
      <MarketItemForm orgId={org.id} symbol={data?.currency_symbol ?? ''} error={error} />
    </div>
  );
}
