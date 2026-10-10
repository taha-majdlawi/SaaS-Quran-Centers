import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { Flash, btn, field } from '@/components/platform-flash';
import { createOrg } from '@/lib/platform/actions';
import { STATUS_LABELS, fmt } from '@/lib/platform/labels';

interface Overview {
  orgs: { id: string; name: string; slug: string; status: string; plan: string | null; students: number; teachers: number; recitations_7d: number; last_activity: string | null; trial_ends_at: string | null }[];
  plans: { id: string; name: string }[];
}

export default async function PlatformOrganizationsPage({ searchParams }: { searchParams: Promise<{ error?: string; ok?: string; q?: string }> }) {
  const { error, ok, q } = await searchParams;
  const supabase = await createClient();
  const [{ data }, { data: st }] = await Promise.all([supabase.rpc('platform_overview'), supabase.rpc('platform_org_storage')]);
  const o = data as Overview | null;
  // used storage per center against its plan (0091)
  const storage = (st ?? {}) as Record<string, { used_bytes: number; limit_mb: number | null; full: boolean }>;
  const query = (q ?? '').trim().toLowerCase();
  const orgs = (o?.orgs ?? []).filter((c) => !query || c.name.toLowerCase().includes(query) || c.slug.includes(query));

  return (
    <div className="max-w-5xl">
      <h1 className="mb-4 text-2xl font-bold">المراكز</h1>
      <Flash ok={ok} error={error} />

      <form className="mb-4 flex gap-2">
        <input name="q" defaultValue={q} placeholder="ابحث باسم المركز أو رابطه" className="w-64 rounded border px-3 py-2 text-sm" />
        <button className="rounded border px-4 py-2 text-sm hover:bg-gray-50">بحث</button>
      </form>

      <div className="mb-8 overflow-x-auto rounded-lg border bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-right">
            <tr>
              {['المركز', 'الحالة', 'الخطة', 'الطلاب', 'المعلمون', 'نشاط 7 أيام', 'التخزين', 'آخر نشاط'].map((h) => (
                <th key={h} className="px-3 py-2">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {orgs.map((c) => (
              <tr key={c.id} className="border-t hover:bg-gray-50">
                <td className="px-3 py-2">
                  <a href={`/organizations/${c.id}` as never} className="font-semibold text-blue-700 hover:underline">
                    {c.name}
                  </a>
                  <span className="mr-2 text-xs text-gray-400">{c.slug}</span>
                </td>
                <td className="px-3 py-2">{STATUS_LABELS[c.status] ?? c.status}</td>
                <td className="px-3 py-2">{c.plan ?? '—'}</td>
                <td className="px-3 py-2">{c.students}</td>
                <td className="px-3 py-2">{c.teachers}</td>
                <td className="px-3 py-2">{c.recitations_7d}</td>
                <td className="px-3 py-2 text-xs" dir="ltr">
                  {(() => {
                    const x = storage[c.id];
                    if (!x) return '—';
                    const mb = Math.round((x.used_bytes / 1048576) * 10) / 10;
                    const near = x.limit_mb != null && x.used_bytes >= x.limit_mb * 1048576 * 0.85;
                    return (
                      <span className={x.full ? 'font-semibold text-red-700' : near ? 'font-semibold text-amber-700' : 'text-gray-600'}>
                        {mb} / {x.limit_mb ?? '∞'} MB
                      </span>
                    );
                  })()}
                </td>
                <td className="px-3 py-2 text-xs text-gray-500">{fmt(c.last_activity)}</td>
              </tr>
            ))}
            {!orgs.length && (
              <tr>
                <td colSpan={8} className="px-3 py-6 text-center text-gray-400">
                  لا مراكز
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <form action={createOrg} className="grid max-w-2xl gap-3 rounded-lg border bg-white p-4 sm:grid-cols-2">
        <h2 className="font-semibold sm:col-span-2">إنشاء مركز جديد</h2>
        <label className="text-sm">
          اسم المركز
          <input name="name" required minLength={2} className={field} />
        </label>
        <label className="text-sm">
          الرابط (إنجليزي صغير)
          <input name="slug" required pattern="[a-z0-9]([a-z0-9\-]{0,38}[a-z0-9])?" dir="ltr" placeholder="alnoor" className={field} />
        </label>
        <label className="text-sm">
          الخطة
          <select name="planId" defaultValue="" className={field}>
            <option value="">بلا خطة</option>
            {(o?.plans ?? []).map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </select>
        </label>
        <label className="text-sm">
          بريد المدير (اختياري)
          <input name="adminEmail" type="email" dir="ltr" className={field} />
        </label>
        <p className="text-xs text-gray-500 sm:col-span-2">إن كان للبريد حساب يصير مديرًا فورًا، وإلا تُنشأ دعوة برابط تُرسله له.</p>
        <div className="sm:col-span-2">
          <SubmitButton className={btn} pendingText="جاري الإنشاء...">
            إنشاء المركز
          </SubmitButton>
        </div>
      </form>
    </div>
  );
}
