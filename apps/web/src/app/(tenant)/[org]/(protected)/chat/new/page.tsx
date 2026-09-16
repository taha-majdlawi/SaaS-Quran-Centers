import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { createThread } from '../actions';

interface MemberRow {
  user_id: string;
  full_name: string | null;
  email: string | null;
}

export default async function NewChatPage({
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

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: members } = await supabase.rpc('list_org_members', { org_id: org.id });
  const allOthers = ((members ?? []) as MemberRow[]).filter((m) => m.user_id !== user!.id);

  // Admins can message anyone (chat_participants_insert's RLS bypass for
  // is_org_admin); everyone else only sees their admin-curated chat_contacts
  // - mirrors apps/mobile's ChatRepository.fetchMembers vs fetchMyContacts
  // split, so picking a name here never hits createThread's RLS rejection.
  let others = allOthers;
  if (org.myRole !== 'admin') {
    const { data: contacts } = await supabase
      .from('chat_contacts')
      .select('contact_user_id')
      .eq('organization_id', org.id)
      .eq('user_id', user!.id);
    const contactIds = new Set((contacts ?? []).map((c) => c.contact_user_id as string));
    others = allOthers.filter((m) => contactIds.has(m.user_id));
  }

  return (
    <div className="max-w-md p-6">
      <a href="/chat" className="mb-4 inline-block text-sm text-brand hover:underline">
        ← رجوع للمحادثات
      </a>
      <h1 className="mb-6 text-2xl font-bold">محادثة جديدة</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      {others.length ? (
        <form action={createThread} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
          <input type="hidden" name="orgId" value={org.id} />
          <label className="text-sm font-medium text-gray-700">
            مع
            <select name="userId" required className="mt-1 w-full rounded border px-3 py-2 text-sm">
              <option value="" disabled>
                اختر عضوًا
              </option>
              {others.map((m) => (
                <option key={m.user_id} value={m.user_id}>
                  {m.full_name ?? m.email}
                </option>
              ))}
            </select>
          </label>
          <SubmitButton
            className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
            pendingText="جاري الإنشاء..."
          >
            بدء المحادثة
          </SubmitButton>
        </form>
      ) : (
        <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">
          ما في أحد يمكنك مراسلته حاليًا - اطلب من إدارة المركز إضافة جهات اتصال لك.
        </p>
      )}
    </div>
  );
}
