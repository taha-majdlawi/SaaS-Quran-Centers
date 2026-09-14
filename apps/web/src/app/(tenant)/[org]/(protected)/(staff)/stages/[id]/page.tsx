import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { updateStage, deleteStage } from '../actions';

export default async function EditStagePage({
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

  const { data: stage } = await supabase
    .from('stages')
    .select('id, name, code, sort_order')
    .eq('organization_id', org.id)
    .eq('id', id)
    .maybeSingle();

  if (!stage) notFound();

  return (
    <div className="max-w-md">
      <h1 className="mb-6 text-2xl font-bold">تعديل مرحلة</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={updateStage} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="id" value={stage.id} />

        <label className="text-sm font-medium text-gray-700">
          اسم المرحلة
          <input
            name="name"
            required
            defaultValue={stage.name}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          كود المرحلة (يستخدم برقم الطالب المقترح)
          <input
            name="code"
            defaultValue={stage.code ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          ترتيب المرحلة
          <input
            type="number"
            name="sortOrder"
            defaultValue={stage.sort_order}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الحفظ..."
        >
          حفظ التعديلات
        </SubmitButton>
      </form>

      <form action={deleteStage} className="mt-3">
        <input type="hidden" name="id" value={stage.id} />
        <ConfirmSubmitButton
          confirmMessage={`متأكد إنك بدك تحذف مرحلة "${stage.name}"؟ لا يمكن التراجع.`}
          pendingText="جاري الحذف..."
          className="rounded border border-red-200 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
        >
          حذف المرحلة
        </ConfirmSubmitButton>
      </form>
    </div>
  );
}
