import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { createInvitation } from './actions';

const ROLE_LABELS: Record<string, string> = {
  admin: 'مدير',
  teacher: 'معلم',
  guardian: 'ولي أمر',
  student: 'طالب',
};

interface MemberRow {
  id: string;
  role: string;
  status: string;
  full_name: string | null;
  email: string | null;
  created_at: string;
}

interface InvitationRow {
  id: string;
  email: string;
  role: string;
  token: string;
  expires_at: string;
  accepted_at: string | null;
}

export default async function MembersPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ createdEmail?: string; createdPassword?: string }>;
}) {
  const { org: slug } = await params;
  const { createdEmail, createdPassword } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data: members, error: membersError } = await supabase.rpc('list_org_members', { org_id: org.id });
  const isAdmin = org.myRole === 'admin';

  const { data: invitations } = isAdmin
    ? await supabase.rpc('list_org_invitations', { org_id: org.id })
    : { data: [] as InvitationRow[] };

  const pendingInvitations = ((invitations ?? []) as InvitationRow[]).filter((i) => !i.accepted_at);

  return (
    <div className="flex flex-col gap-8">
      {createdEmail && createdPassword && (
        <div className="rounded-lg border border-green-200 bg-green-50 p-4 text-sm">
          <p className="mb-2 font-semibold text-green-800">تم إنشاء حساب المعلم بنجاح - أعطه هذي البيانات الآن:</p>
          <p dir="ltr" className="font-mono text-green-900">
            {createdEmail} / {createdPassword}
          </p>
          <p className="mt-2 text-xs text-green-700">
            هذا العرض الوحيد لكلمة السر - انسخها الآن، ما رح تظهر مرة ثانية.
          </p>
        </div>
      )}

      <div>
        {membersError && (
          <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600" dir="ltr">
            {membersError.code}: {membersError.message}
          </p>
        )}
        <div className="mb-4 flex items-center justify-between">
          <h1 className="text-2xl font-bold">الأعضاء والأدوار</h1>
          {org.myRole === 'admin' && (
            <a href="/members/new-teacher" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
              + إضافة معلم يدويًا
            </a>
          )}
        </div>
        <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
          <thead className="bg-gray-50 text-right">
            <tr>
              <th className="px-4 py-2">الاسم</th>
              <th className="px-4 py-2">البريد الإلكتروني</th>
              <th className="px-4 py-2">الدور</th>
              <th className="px-4 py-2">الحالة</th>
            </tr>
          </thead>
          <tbody>
            {((members ?? []) as MemberRow[]).map((m) => (
              <tr key={m.id} className="border-t">
                <td className="px-4 py-2">{m.full_name ?? '—'}</td>
                <td className="px-4 py-2">{m.email}</td>
                <td className="px-4 py-2">{ROLE_LABELS[m.role] ?? m.role}</td>
                <td className="px-4 py-2">{m.status === 'active' ? 'نشط' : m.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {isAdmin && (
        <div>
          <h2 className="mb-4 text-lg font-bold">دعوة عضو جديد</h2>
          <form action={createInvitation} className="flex flex-wrap items-end gap-3 rounded-lg border bg-white p-4">
            <input type="hidden" name="orgId" value={org.id} />
            <label className="text-sm">
              البريد الإلكتروني
              <input
                type="email"
                name="email"
                required
                placeholder="teacher@example.com"
                className="mt-1 block rounded border px-3 py-2 text-sm"
              />
            </label>
            <label className="text-sm">
              الدور
              <select name="role" className="mt-1 block rounded border px-3 py-2 text-sm">
                <option value="teacher">معلم</option>
                <option value="admin">مدير</option>
                <option value="guardian">ولي أمر</option>
                <option value="student">طالب</option>
              </select>
            </label>
            <SubmitButton
              className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
              pendingText="جاري الإنشاء..."
            >
              إنشاء دعوة
            </SubmitButton>
          </form>

          {pendingInvitations.length > 0 && (
            <div className="mt-4">
              <h3 className="mb-2 text-sm font-semibold text-gray-600">دعوات لسه ما انضمّت</h3>
              <ul className="flex flex-col gap-2">
                {pendingInvitations.map((inv) => (
                  <li key={inv.id} className="rounded border bg-white p-3 text-sm">
                    <div className="mb-1 flex items-center justify-between">
                      <span>
                        {inv.email} — {ROLE_LABELS[inv.role] ?? inv.role}
                      </span>
                    </div>
                    <p className="break-all text-xs text-gray-400" dir="ltr">
                      {`https://${org.slug}.bustan-alquran.com/join?token=${inv.token}`}
                    </p>
                  </li>
                ))}
              </ul>
              <p className="mt-2 text-xs text-gray-400">
                انسخ الرابط وابعثه للشخص (واتساب/إيميل) - ما في إرسال تلقائي بعد.
              </p>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
