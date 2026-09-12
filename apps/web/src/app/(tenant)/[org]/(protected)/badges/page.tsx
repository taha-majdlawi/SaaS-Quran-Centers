import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { awardBadge } from './actions';

export default async function BadgesPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string; awarded?: string }>;
}) {
  const { org: slug } = await params;
  const { error, awarded } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const [{ data: badges }, { data: students }, { data: recentAwards }] = await Promise.all([
    supabase.from('badges').select('id, name, description').eq('organization_id', org.id).order('name'),
    supabase
      .from('students_profile')
      .select('id, full_name')
      .eq('organization_id', org.id)
      .eq('status', 'active')
      .order('full_name'),
    supabase
      .from('student_badges')
      .select('id, awarded_at, badges!inner(name, organization_id), students_profile(full_name)')
      .eq('badges.organization_id', org.id)
      .order('awarded_at', { ascending: false })
      .limit(10),
  ]);

  return (
    <div className="flex flex-col gap-8">
      <div>
        <div className="mb-4 flex items-center justify-between">
          <h1 className="text-2xl font-bold">الشارات</h1>
          <a href="/badges/new" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
            + إضافة شارة
          </a>
        </div>

        {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
        {awarded && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم منح الشارة بنجاح</p>}

        <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
          <thead className="bg-gray-50 text-right">
            <tr>
              <th className="px-4 py-2">الاسم</th>
              <th className="px-4 py-2">الوصف</th>
              <th className="px-4 py-2"></th>
            </tr>
          </thead>
          <tbody>
            {(badges ?? []).map((b) => (
              <tr key={b.id} className="border-t">
                <td className="px-4 py-2">{b.name}</td>
                <td className="px-4 py-2 text-gray-500">{b.description ?? '—'}</td>
                <td className="px-4 py-2 text-left">
                  <a href={`/badges/${b.id}`} className="text-brand hover:underline">
                    تعديل
                  </a>
                </td>
              </tr>
            ))}
            {!badges?.length && (
              <tr>
                <td colSpan={3} className="px-4 py-6 text-center text-gray-400">
                  لا يوجد شارات بعد
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {Boolean(badges?.length) && Boolean(students?.length) && (
        <div>
          <h2 className="mb-4 text-lg font-bold">منح شارة لطالب</h2>
          <form action={awardBadge} className="flex flex-wrap items-end gap-3 rounded-lg border bg-white p-4 text-sm">
            <label>
              الطالب
              <select name="studentId" required className="mt-1 block rounded border px-3 py-2">
                <option value="" disabled>
                  اختر الطالب
                </option>
                {(students ?? []).map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.full_name}
                  </option>
                ))}
              </select>
            </label>
            <label>
              الشارة
              <select name="badgeId" required className="mt-1 block rounded border px-3 py-2">
                <option value="" disabled>
                  اختر الشارة
                </option>
                {(badges ?? []).map((b) => (
                  <option key={b.id} value={b.id}>
                    {b.name}
                  </option>
                ))}
              </select>
            </label>
            <SubmitButton
              className="rounded bg-brand px-4 py-2 font-semibold text-white disabled:opacity-50"
              pendingText="جاري المنح..."
            >
              منح الشارة
            </SubmitButton>
          </form>
        </div>
      )}

      {Boolean(recentAwards?.length) && (
        <div>
          <h2 className="mb-4 text-lg font-bold">آخر الشارات الممنوحة</h2>
          <ul className="flex flex-col gap-1 text-sm text-gray-600">
            {(recentAwards ?? []).map((a) => (
              <li key={a.id}>
                {(a.students_profile as unknown as { full_name: string } | null)?.full_name} —{' '}
                {(a.badges as unknown as { name: string } | null)?.name}
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
