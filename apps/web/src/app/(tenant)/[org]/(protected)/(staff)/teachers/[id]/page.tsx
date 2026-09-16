import { notFound, redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { MODULE_DEFS } from '@/lib/permissions/modules';
import { updateTeacherAccount } from '../actions';

const ROLE_OPTIONS = [
  { value: 'teacher', label: 'معلم' },
  { value: 'admin', label: 'مدير' },
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
  permissions: string[] | null;
}

// Full account edit (name/email/password/role/status) - members/[id] only
// covers role/status; this one also needs the Admin API (see actions.ts)
// since changing someone else's email/password can't go through RLS.
export default async function EditTeacherPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug, id } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);

  if (org.myRole !== 'admin') redirect('/teachers' as never);

  const supabase = await createClient();
  const { data: members } = await supabase.rpc('list_org_members', { org_id: org.id });
  const member = ((members ?? []) as MemberRow[]).find((m) => m.id === id);

  if (!member) notFound();

  return (
    <div className="max-w-md">
      <h1 className="mb-6 text-2xl font-bold">تعديل بيانات المعلم</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={updateTeacherAccount} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="memberId" value={member.id} />
        <input type="hidden" name="orgId" value={org.id} />

        <label className="text-sm font-medium text-gray-700">
          الاسم الكامل
          <input
            name="fullName"
            required
            defaultValue={member.full_name ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          البريد الإلكتروني
          <input
            type="email"
            name="email"
            required
            defaultValue={member.email ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
            dir="ltr"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          كلمة سر جديدة (اتركها فاضية إذا ما بدك تغيّرها)
          <input
            name="password"
            minLength={6}
            placeholder="••••••"
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
            dir="ltr"
          />
        </label>

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
          <select name="status" defaultValue={member.status} className="mt-1 w-full rounded border px-3 py-2 text-sm">
            {STATUS_OPTIONS.map((s) => (
              <option key={s.value} value={s.value}>
                {s.label}
              </option>
            ))}
          </select>
        </label>

        <fieldset className="rounded border p-3">
          <legend className="px-1 text-sm font-medium text-gray-700">
            الوحدات التي يمكنه الوصول لها من لوحة التحكم
          </legend>
          <p className="mb-2 text-xs text-gray-400">
            هذا يتحكم بما يظهر له في القائمة الجانبية وما يمكنه فعلاً قراءته أو تعديله - إن غيّرت دوره
            إلى مدير فلن يكون لهذا أي أثر لأن المدير يرى كل شيء دائمًا.
          </p>
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
            {MODULE_DEFS.map((m) => (
              <label key={m.key} className="flex items-center gap-2 text-sm text-gray-700">
                <input
                  type="checkbox"
                  name={`perm_${m.key}`}
                  defaultChecked={(member.permissions ?? []).includes(m.key)}
                />
                {m.label}
              </label>
            ))}
          </div>
        </fieldset>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الحفظ..."
        >
          حفظ التعديلات
        </SubmitButton>
      </form>
    </div>
  );
}
