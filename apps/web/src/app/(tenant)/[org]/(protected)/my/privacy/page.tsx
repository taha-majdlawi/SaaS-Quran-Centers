import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { requestDeletion } from '@/lib/privacy/actions';

const STATUS: Record<string, string> = { pending: 'قيد المراجعة من إدارة المركز', approved: 'وافقت الإدارة وسيُحذف حسابك قريبًا', rejected: 'رفضت الإدارة الطلب', completed: 'اكتمل حذف بياناتك' };

export default async function MyPrivacyPage({ params, searchParams }: { params: Promise<{ org: string }>; searchParams: Promise<{ ok?: string; error?: string }> }) {
  const { org: slug } = await params;
  const { ok, error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const { data } = await supabase.rpc('my_deletion_request', { p_org: org.id });
  const last = data as { status: string; created_at: string } | null;
  const open = last?.status === 'pending';

  return (
    <div className="mx-auto max-w-lg p-6">
      <a href="/my" className="text-sm text-brand hover:underline">
        ← الرئيسية
      </a>
      <h1 className="mb-2 mt-2 text-2xl font-bold">حسابي وبياناتي</h1>
      <p className="mb-4 text-sm text-gray-600">
        يمكنك طلب حذف حسابك وبياناتك من {org.name}. تراجع الإدارة الطلب، ويصلك إشعار بالنتيجة. يحذف هذا الطلب بياناتك في هذا المركز فقط.
      </p>
      {ok && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">أُرسل طلبك إلى إدارة المركز</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {last && (
        <p className="mb-4 rounded border bg-white px-3 py-2 text-sm">
          آخر طلب: <b>{STATUS[last.status] ?? last.status}</b> <span className="text-xs text-gray-400">({new Date(last.created_at).toLocaleDateString('ar')})</span>
        </p>
      )}
      {!open && (
        <form action={requestDeletion} className="flex flex-col gap-3 rounded-lg border bg-white p-4">
          <input type="hidden" name="orgId" value={org.id} />
          <label className="text-sm">
            السبب (اختياري)
            <textarea name="reason" maxLength={500} rows={3} className="mt-1 w-full rounded border px-3 py-2 text-sm" />
          </label>
          <SubmitButton className="self-start rounded bg-red-600 px-4 py-2 text-sm font-semibold text-white" pendingText="جاري الإرسال...">
            طلب حذف حسابي وبياناتي
          </SubmitButton>
        </form>
      )}
    </div>
  );
}
