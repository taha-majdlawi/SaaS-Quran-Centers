import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { StudentFormFields } from './student-form-fields';
import { createStudent } from '../actions';

function generatePassword() {
  return crypto.randomUUID().replace(/-/g, '').slice(0, 8);
}

export default async function NewStudentPage({
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

  const [{ data: stages }, { data: circles }] = await Promise.all([
    supabase.from('stages').select('id, name').eq('organization_id', org.id).order('sort_order'),
    supabase.from('circles').select('id, name, stage_id').eq('organization_id', org.id).order('name'),
  ]);

  const suggestedCodes: Record<string, string> = {};
  await Promise.all(
    (stages ?? []).map(async (s) => {
      const { data: code } = await supabase.rpc('next_student_code', { org_id: org.id, target_stage_id: s.id });
      if (code) suggestedCodes[s.id] = code;
    }),
  );

  return (
    <div className="max-w-lg">
      <h1 className="mb-6 text-2xl font-bold">إضافة طالب</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={createStudent} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />

        <label className="text-sm font-medium text-gray-700">
          الاسم الكامل
          <input name="fullName" required className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <StudentFormFields stages={stages ?? []} circles={circles ?? []} suggestedCodes={suggestedCodes} />

        <label className="text-sm font-medium text-gray-700">
          تاريخ الميلاد
          <input type="date" name="birthDate" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          رقم الجوال
          <input name="phone" dir="ltr" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          رقم الواتساب
          <input name="whatsapp" dir="ltr" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          العنوان
          <input name="address" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <div className="rounded-lg border border-dashed p-4">
          <p className="mb-2 text-sm font-semibold text-gray-700">حساب دخول الطالب</p>
          <label className="text-sm font-medium text-gray-700">
            كلمة السر (مقترحة، اتركها فارغة لإنشاء الملف بدون حساب)
            <input
              name="password"
              minLength={6}
              defaultValue={generatePassword()}
              dir="ltr"
              className="mt-1 w-full rounded border px-3 py-2 text-sm"
            />
          </label>
          <label className="mt-3 block text-sm font-medium text-gray-700">
            بريد إلكتروني حقيقي (اختياري)
            <input type="email" name="email" dir="ltr" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
          </label>
          <p className="mt-2 text-xs text-gray-400">
            يدخل الطالب برمز المركز ({org.slug}) ورقمه وكلمة السر، أو ببريده إن أضفته.
          </p>
        </div>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الإضافة..."
        >
          إضافة الطالب
        </SubmitButton>
      </form>
    </div>
  );
}
