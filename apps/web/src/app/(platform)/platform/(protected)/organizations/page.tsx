import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { setOrgStatus } from '@/lib/platform/actions';

interface Overview {
  orgs: { id: string; name: string; slug: string; status: string; plan_id: string | null; created_at: string; trial_ends_at: string | null; students: number }[];
  plans: { id: string; name: string }[];
}

const STATUSES: [string, string][] = [
  ['trial', 'تجريبي'],
  ['active', 'فعّال'],
  ['suspended', 'موقوف'],
  ['cancelled', 'ملغى'],
];

export default async function PlatformOrganizationsPage({ searchParams }: { searchParams: Promise<{ error?: string; saved?: string }> }) {
  const { error, saved } = await searchParams;
  const supabase = await createClient();
  const { data } = await supabase.rpc('platform_overview');
  const o = data as Overview | null;

  return (
    <div className="max-w-5xl">
      <h1 className="mb-6 text-2xl font-bold">المراكز (Tenants)</h1>
      {saved && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم الحفظ</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      <div className="overflow-x-auto rounded-lg border bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-right">
            <tr>
              <th className="px-4 py-2">المركز</th>
              <th className="px-4 py-2">الطلاب</th>
              <th className="px-4 py-2">الحالة والخطة</th>
            </tr>
          </thead>
          <tbody>
            {(o?.orgs ?? []).map((c) => (
              <tr key={c.id} className="border-t">
                <td className="px-4 py-2">
                  <a href={`https://${c.slug}.${process.env.NEXT_PUBLIC_ROOT_DOMAIN ?? 'bustan-alquran.com'}`} className="text-brand hover:underline">
                    {c.name}
                  </a>
                  <span className="mr-2 text-xs text-gray-400">{c.slug}</span>
                </td>
                <td className="px-4 py-2">{c.students}</td>
                <td className="px-4 py-2">
                  <form action={setOrgStatus} className="flex flex-wrap items-center gap-2">
                    <input type="hidden" name="orgId" value={c.id} />
                    <select name="status" defaultValue={c.status} className="rounded border px-2 py-1">
                      {STATUSES.map(([v, l]) => (
                        <option key={v} value={v}>
                          {l}
                        </option>
                      ))}
                    </select>
                    <select name="planId" defaultValue={c.plan_id ?? ''} className="rounded border px-2 py-1">
                      <option value="">— بلا خطة —</option>
                      {(o?.plans ?? []).map((p) => (
                        <option key={p.id} value={p.id}>
                          {p.name}
                        </option>
                      ))}
                    </select>
                    <SubmitButton className="rounded border px-3 py-1 hover:bg-gray-50" pendingText="...">
                      حفظ
                    </SubmitButton>
                  </form>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <p className="mt-3 text-xs text-gray-500">إيقاف مركز يمنع أعضاءه من الدخول فورًا؛ كل بياناته تبقى محفوظة.</p>
    </div>
  );
}
