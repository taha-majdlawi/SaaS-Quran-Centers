import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { sendNotification } from './actions';

interface MemberRow {
  user_id: string;
  full_name: string | null;
  email: string | null;
}

interface NotificationRow {
  id: string;
  title: string;
  body: string;
  sent_at: string;
  read_at: string | null;
}

export default async function NotificationsPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const [{ data: notifications }, { data: members }] = await Promise.all([
    supabase
      .from('notification_log')
      .select('id, title, body, sent_at, read_at')
      .eq('organization_id', org.id)
      .order('sent_at', { ascending: false })
      .limit(50),
    supabase.rpc('list_org_members', { org_id: org.id }),
  ]);

  return (
    <div className="flex flex-col gap-8">
      <div>
        <h2 className="mb-4 text-lg font-bold">إرسال إشعار</h2>
        {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
        <form action={sendNotification} className="flex flex-col gap-3 rounded-lg border bg-white p-4">
          <input type="hidden" name="orgId" value={org.id} />
          <label className="text-sm">
            المستلم
            <select name="userId" required className="mt-1 block w-full rounded border px-3 py-2 text-sm">
              <option value="" disabled>
                اختر عضوًا
              </option>
              {((members ?? []) as MemberRow[]).map((m) => (
                <option key={m.user_id} value={m.user_id}>
                  {m.full_name ?? m.email}
                </option>
              ))}
            </select>
          </label>
          <label className="text-sm">
            العنوان
            <input name="title" required className="mt-1 block w-full rounded border px-3 py-2 text-sm" />
          </label>
          <label className="text-sm">
            النص
            <textarea name="body" required rows={3} className="mt-1 block w-full rounded border px-3 py-2 text-sm" />
          </label>
          <SubmitButton
            className="self-start rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
            pendingText="جاري الإرسال..."
          >
            إرسال
          </SubmitButton>
        </form>
      </div>

      <div>
        <h1 className="mb-4 text-2xl font-bold">سجل الإشعارات</h1>
        <ul className="flex flex-col gap-2">
          {((notifications ?? []) as NotificationRow[]).map((n) => (
            <li key={n.id} className="rounded-lg border bg-white p-4 text-sm">
              <div className="mb-1 flex items-center justify-between">
                <span className="font-semibold">{n.title}</span>
                <span className="text-xs text-gray-400">{new Date(n.sent_at).toLocaleString('ar')}</span>
              </div>
              <p className="text-gray-600">{n.body}</p>
              <span className="mt-1 text-xs text-gray-400">{n.read_at ? 'مقروء' : 'غير مقروء'}</span>
            </li>
          ))}
          {!notifications?.length && (
            <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا يوجد إشعارات بعد</p>
          )}
        </ul>
      </div>
    </div>
  );
}
