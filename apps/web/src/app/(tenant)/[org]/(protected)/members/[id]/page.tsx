import { notFound, redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { updateMember, removeMember } from '../actions';

const ROLE_OPTIONS = [
  { value: 'admin', label: 'مدير' },
  { value: 'teacher', label: 'معلم' },
  { value: 'guardian', label: 'ولي أمر' },
  { value: 'student', label: 'طالب' },
];

const STATUS_OPTIONS = [
  { value: 'active', label: 'نشط' },
  { value: 'suspended', label: 'موقوف' },
];

interface MemberRow {
  id: string;
  user_id: string;
  role: string;
  status: string;
  full_name: string | null;
  email: string | null;
}

export default async function EditMemberPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug, id } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);

  if (org.myRole !== 'admin') redirect('/members' as never);

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: members } = await supabase.rpc('list_org_members', { org_id: org.id });
  const member = ((members ?? []) as MemberRow[]).find((m) => m.id === id);

  if (!member) notFound();

  const isSelf = member.user_id === user?.id;

  return (
    <div className="max-w-md">
      <h1 className="mb-1 text-2xl font-bold">تعديل عضو</h1>
      <p className="mb-6 text-sm text-gray-500">{member.full_name ?? member.email}</p>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      {isSelf ? (
        <p className="rounded-lg border bg-yellow-50 p-4 text-sm text-yellow-800">
          لا يمكنك تعديل أو حذف صلاحياتك الخاصة من هنا - اطلب من مدير آخر إن وجد.
        </p>
      ) : (
        <>
          <form action={updateMember} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
            <input type="hidden" name="id" value={member.id} />
            <label className="text-sm font-medium text-gray-700">
              الدور
              <select name="role" defaultValue={member.role} className="mt-1 w-full rounded border px-3 py-2 text-sm">
                {ROLE_OPTIONS.map((r) => (
                  <option key={r.value} value={r.value}>
                    {r.label}
                  </option>
                ))}
              </select>
            </label>
            <label className="text-sm font-medium text-gray-700">
              الحالة
              <select
                name="status"
                defaultValue={member.status}
                className="mt-1 w-full rounded border px-3 py-2 text-sm"
              >
                {STATUS_OPTIONS.map((s) => (
                  <option key={s.value} value={s.value}>
                    {s.label}
                  </option>
                ))}
              </select>
            </label>
            <SubmitButton
              className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
              pendingText="جاري الحفظ..."
            >
              حفظ التعديلات
            </SubmitButton>
          </form>

          <form action={removeMember} className="mt-3">
            <input type="hidden" name="id" value={member.id} />
            <ConfirmSubmitButton
              confirmMessage={`متأكد إنك بدك تحذف "${member.full_name ?? member.email}" من المركز؟ رح يفقد كل صلاحياته هنا فورًا.`}
              pendingText="جاري الحذف..."
              className="rounded border border-red-200 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
            >
              حذف من المركز
            </ConfirmSubmitButton>
          </form>
        </>
      )}
    </div>
  );
}
