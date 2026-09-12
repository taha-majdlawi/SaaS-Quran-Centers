import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { updateItem, deleteItem } from '../actions';

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
  const supabase = await createClient();

  const { data: item } = await supabase
    .from('market_items')
    .select('id, name, cost, stock, is_active')
    .eq('organization_id', org.id)
    .eq('id', id)
    .maybeSingle();

  if (!item) notFound();

  return (
    <div className="max-w-md">
      <h1 className="mb-6 text-2xl font-bold">تعديل عنصر</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={updateItem} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="id" value={item.id} />

        <label className="text-sm font-medium text-gray-700">
          اسم العنصر
          <input
            name="name"
            required
            defaultValue={item.name}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          التكلفة (نقاط)
          <input
            type="number"
            name="cost"
            required
            min={0}
            defaultValue={item.cost}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          المخزون (اتركه فاضي لغير محدود)
          <input
            type="number"
            name="stock"
            min={0}
            defaultValue={item.stock ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="flex items-center gap-2 text-sm font-medium text-gray-700">
          <input type="checkbox" name="isActive" defaultChecked={item.is_active} />
          مفعّل بالسوق
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الحفظ..."
        >
          حفظ التعديلات
        </SubmitButton>
      </form>

      <form action={deleteItem} className="mt-3">
        <input type="hidden" name="id" value={item.id} />
        <ConfirmSubmitButton
          confirmMessage={`متأكد إنك بدك تحذف "${item.name}"؟`}
          pendingText="جاري الحذف..."
          className="rounded border border-red-200 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
        >
          حذف العنصر
        </ConfirmSubmitButton>
      </form>
    </div>
  );
}
