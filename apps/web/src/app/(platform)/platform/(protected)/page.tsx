import { createClient } from '@/lib/supabase/server';

interface Overview {
  totals: Record<string, number>;
  orgs: { id: string; name: string; slug: string; status: string; plan: string | null; students: number; teachers: number; recitations_7d: number; last_activity: string | null }[];
  jobs: { name: string; schedule: string; active: boolean; last_status: string | null; last_run: string | null; last_message: string | null }[];
}

const day = (iso: string | null) => (iso ? new Date(iso).toLocaleString('ar', { dateStyle: 'medium', timeStyle: 'short' }) : '—');

const JOB_LABELS: Record<string, string> = {
  'calendar-reminders': 'تذكير الفعاليات',
  'weekly-digest': 'ملخص الأسبوع للأسر',
  'cleanup-old-data': 'التنظيف الليلي',
};

export default async function PlatformOverviewPage() {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('platform_overview');
  const o = data as Overview | null;
  const t = o?.totals ?? {};

  const kpis: [string, number | string][] = [
    ['المراكز', t.orgs ?? 0],
    ['تجريبية', t.trial ?? 0],
    ['فعّالة', t.active ?? 0],
    ['موقوفة', t.suspended ?? 0],
    ['جديدة (30 يوم)', t.new_orgs_30d ?? 0],
    ['الحسابات', t.users ?? 0],
    ['الطلاب النشطون', t.students ?? 0],
    ['تسميعات (7 أيام)', t.recitations_7d ?? 0],
    ['تسميعات (30 يوم)', t.recitations_30d ?? 0],
    ['صور المحادثات', `${t.chat_images ?? 0} · ${t.chat_images_mb ?? 0} MB`],
  ];

  return (
    <div className="max-w-5xl">
      <h1 className="mb-4 text-2xl font-bold">نظرة عامة</h1>
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error.message}</p>}
      {o && (
        <>
          <div className="mb-8 grid grid-cols-2 gap-3 sm:grid-cols-5">
            {kpis.map(([label, value]) => (
              <div key={label} className="rounded-lg border bg-white p-4">
                <p className="text-xs text-gray-500">{label}</p>
                <p className="text-xl font-bold">{value}</p>
              </div>
            ))}
          </div>

          <h2 className="mb-2 font-semibold">المراكز ونشاطها</h2>
          <div className="mb-8 overflow-x-auto rounded-lg border bg-white">
            <table className="w-full text-sm">
              <thead className="bg-gray-50">
                <tr>
                  {['المركز', 'الحالة', 'الخطة', 'الطلاب', 'المعلمون', 'تسميعات 7 أيام', 'آخر نشاط'].map((h) => (
                    <th key={h} className="px-3 py-2 text-right">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {o.orgs.map((c) => (
                  <tr key={c.id} className="border-t">
                    <td className="px-3 py-2">
                      <a href={`/organizations/${c.id}` as never} className="font-semibold text-blue-700 hover:underline">
                        {c.name}
                      </a>{' '}
                      <span className="text-xs text-gray-400">{c.slug}</span>
                    </td>
                    <td className="px-3 py-2">{c.status}</td>
                    <td className="px-3 py-2">{c.plan ?? '—'}</td>
                    <td className="px-3 py-2">{c.students}</td>
                    <td className="px-3 py-2">{c.teachers}</td>
                    <td className="px-3 py-2">{c.recitations_7d}</td>
                    <td className="px-3 py-2 text-xs text-gray-500">{day(c.last_activity)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <h2 className="mb-2 font-semibold">صحة المهام المجدولة</h2>
          <div className="overflow-x-auto rounded-lg border bg-white">
            <table className="w-full text-sm">
              <thead className="bg-gray-50">
                <tr>
                  {['المهمة', 'الجدول', 'آخر تشغيل', 'النتيجة'].map((h) => (
                    <th key={h} className="px-3 py-2 text-right">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {o.jobs.map((j) => (
                  <tr key={j.name} className="border-t">
                    <td className="px-3 py-2">{JOB_LABELS[j.name] ?? j.name}</td>
                    <td className="px-3 py-2 font-mono text-xs" dir="ltr">
                      {j.schedule}
                    </td>
                    <td className="px-3 py-2 text-xs text-gray-500">{day(j.last_run)}</td>
                    <td className="px-3 py-2">
                      {j.last_status === 'succeeded' ? (
                        <span className="text-green-700">نجحت</span>
                      ) : j.last_status ? (
                        <span className="text-red-600">{j.last_status}: {j.last_message}</span>
                      ) : (
                        <span className="text-gray-400">لم تعمل بعد</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}
    </div>
  );
}
