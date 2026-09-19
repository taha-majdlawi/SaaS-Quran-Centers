import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { MarketItemForm } from '@/components/market-item-form';

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
  if (org.myRole !== 'admin') redirect('/market' as never);
  const supabase = await createClient();
  const { data } = await supabase.from('market_config').select('currency_symbol').eq('organization_id', org.id).maybeSingle();

  return (
    <div>
      <a href="/market" className="text-sm text-brand hover:underline">
        ← السوق
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">عنصر جديد</h1>
      <MarketItemForm orgId={org.id} symbol={data?.currency_symbol ?? ''} error={error} />
    </div>
  );
}
