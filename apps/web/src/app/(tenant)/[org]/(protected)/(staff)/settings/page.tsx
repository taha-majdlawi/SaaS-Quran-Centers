import { getOrgContext } from '@/lib/tenant/get-org-context';
import { SubmitButton } from '@/components/submit-button';
import { updateOrgSettings } from './actions';

export default async function SettingsPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string; saved?: string }>;
}) {
  const { org: slug } = await params;
  const { error, saved } = await searchParams;
  const org = await getOrgContext(slug);
  const isAdmin = org.myRole === 'admin';

  return (
    <div className="max-w-md">
      <h1 className="mb-1 text-2xl font-bold">إعدادات المركز</h1>
      <p className="mb-6 text-sm text-gray-500">الاسم والألوان اللي تظهر بلوحة مركزك.</p>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {saved && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم حفظ الإعدادات</p>}

      <form action={updateOrgSettings} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />
        <fieldset disabled={!isAdmin} className="flex flex-col gap-3">
          <label className="text-sm font-medium text-gray-700">
            اسم المركز
            <input name="name" required defaultValue={org.name} className="mt-1 w-full rounded border px-3 py-2 text-sm" />
          </label>

          <label className="text-sm font-medium text-gray-700">
            رابط الشعار
            <input
              name="logoUrl"
              type="url"
              dir="ltr"
              placeholder="https://..."
              defaultValue={org.logoUrl ?? ''}
              className="mt-1 w-full rounded border px-3 py-2 text-sm"
            />
          </label>

          <label className="text-sm font-medium text-gray-700">
            اللون الأساسي
            <input
              type="color"
              name="primaryColor"
              defaultValue={org.primaryColor}
              className="mt-1 h-10 w-full rounded border"
            />
          </label>

          <label className="text-sm font-medium text-gray-700">
            اللون الثانوي
            <input
              type="color"
              name="secondaryColor"
              defaultValue={org.secondaryColor}
              className="mt-1 h-10 w-full rounded border"
            />
          </label>

          <label className="text-sm font-medium text-gray-700">
            رابط المركز
            <input
              value={`${org.slug}.bustan-alquran.com`}
              disabled
              dir="ltr"
              className="mt-1 w-full rounded border bg-gray-50 px-3 py-2 text-sm text-gray-500"
            />
          </label>

          <label className="text-sm font-medium text-gray-700">
            المنطقة الزمنية
            <input name="timezone" defaultValue="Asia/Amman" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
          </label>

          {isAdmin && (
            <SubmitButton
              className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
              pendingText="جاري الحفظ..."
            >
              حفظ الإعدادات
            </SubmitButton>
          )}
        </fieldset>
      </form>

      {!isAdmin && <p className="mt-3 text-xs text-gray-400">بس المدير يقدر يعدّل إعدادات المركز.</p>}
    </div>
  );
}
