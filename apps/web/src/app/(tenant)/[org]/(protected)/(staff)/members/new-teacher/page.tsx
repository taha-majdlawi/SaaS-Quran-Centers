import { getOrgContext } from '@/lib/tenant/get-org-context';
import { SubmitButton } from '@/components/submit-button';
import { createTeacherDirectly } from './actions';

function generatePassword() {
  return crypto.randomUUID().replace(/-/g, '').slice(0, 10);
}

export default async function NewTeacherPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);

  return (
    <div className="max-w-lg">
      <h1 className="mb-1 text-2xl font-bold">إضافة معلم يدويًا</h1>
      <p className="mb-6 text-sm text-gray-500">
        ينشئ حساب دخول جاهزًا فورًا - بلّغ المعلم رمز المركز ورقم هويته (أو بريده) وكلمة السر، بدون رابط دعوة.
      </p>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={createTeacherDirectly} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />

        <label className="text-sm font-medium text-gray-700">
          اسم المعلم
          <input name="fullName" required className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          رقم الهوية (أو البريد الإلكتروني)
          <input name="identifier" required dir="ltr" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
          <span className="mt-1 block text-xs text-gray-400">
            يدخل بهذا الرقم مع رمز المركز ({org.slug}). إن كتبت بريدًا حقيقيًا يدخل به مباشرة.
          </span>
        </label>

        <label className="text-sm font-medium text-gray-700">
          رقم الجوال (اختياري)
          <input name="phone" dir="ltr" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          كلمة السر (مقترحة، تقدر تغيّرها)
          <input
            name="password"
            required
            minLength={8}
            defaultValue={generatePassword()}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
            dir="ltr"
          />
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الإنشاء..."
        >
          إنشاء حساب المعلم
        </SubmitButton>
      </form>
    </div>
  );
}
