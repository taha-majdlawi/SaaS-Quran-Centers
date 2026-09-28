import { SubmitButton } from '@/components/submit-button';
import { MarketImageField } from '@/components/market-image-field';
import { saveItem } from '@/app/(tenant)/[org]/(protected)/(staff)/market/actions';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

export async function MarketItemForm({
  orgId,
  item,
  symbol,
  error,
}: {
  orgId: string;
  item?: { id: string; name: string; description: string | null; image_url: string | null; price: number; stock: number | null; is_active?: boolean };
  symbol: string;
  error?: string;
}) {
  const { t: T } = await getI18n();
  const S = T.staff;
  return (
    <form action={saveItem} className="flex max-w-lg flex-col gap-3 rounded-lg border bg-white p-6">
      <input type="hidden" name="orgId" value={orgId} />
      {item && <input type="hidden" name="id" value={item.id} />}
      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      <label className="text-sm font-medium text-gray-700">
        {S.market.name}
        <input name="name" required defaultValue={item?.name} className={field} />
      </label>
      <label className="text-sm font-medium text-gray-700">
        {S.market.description}
        <textarea name="description" rows={2} defaultValue={item?.description ?? ''} className={field} />
      </label>
      <MarketImageField orgId={orgId} initialUrl={item?.image_url ?? null} labels={S.image} />
      <div className="grid grid-cols-2 gap-3">
        <label className="text-sm font-medium text-gray-700">
          {fmt(S.market.price, { symbol })}
          <input type="number" name="price" required min={0} step="0.01" defaultValue={item?.price ?? ''} className={field} />
        </label>
        <label className="text-sm font-medium text-gray-700">
          {S.market.stock}
          <input type="number" name="stock" min={0} defaultValue={item?.stock ?? ''} placeholder={S.market.noLimit} className={field} />
        </label>
      </div>
      <label className="flex items-center gap-2 text-sm">
        <input type="checkbox" name="isActive" defaultChecked={item?.is_active ?? true} /> {S.market.activeShown}
      </label>
      <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText={S.common.saving}>
        {item ? S.common.save : S.common.add}
      </SubmitButton>
    </form>
  );
}
