import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { JUZ_NAMES } from '@/lib/serd/format';

interface Report {
  from: string;
  to: string;
  total: number;
  approved: number;
  pending: number;
  rejected: number;
  average_score: number | null;
  students: number;
  points: number;
  by_juz: { juz: number; count: number }[];
  by_error_type: { name: string; total: number; sessions: number }[];
  by_examiner: { name: string; count: number }[];
}

const field = 'rounded border px-3 py-2 text-sm';

export default async function SerdReportPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ from?: string; to?: string }>;
}) {
  const { org: slug } = await params;
  const { from, to } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data, error } = await supabase.rpc('admin_serd_report', {
    p_org: org.id,
    p_from: from || null,
    p_to: to || null,
  });
  const r = data as Report | null;

  const kpis = r
    ? [
        ['إجمالي الجلسات', r.total],
        ['معتمد', r.approved],
        ['بانتظار', r.pending],
        ['مرفوض', r.rejected],
        ['متوسط الدرجة', r.average_score == null ? '—' : `${r.average_score}%`],
        ['طلاب معتمدون', r.students],
        ['نقاط ممنوحة', r.points],
      ]
    : [];

  return (
    <div className="max-w-4xl">
      <a href="/serd" className="text-sm text-brand hover:underline">
        ← السرد
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">تقرير السرد</h1>

      <form className="mb-6 flex flex-wrap items-end gap-3">
        <label className="text-sm text-gray-700">
          من
          <input type="date" name="from" defaultValue={from ?? r?.from} className={`mt-1 block ${field}`} />
        </label>
        <label className="text-sm text-gray-700">
          إلى
          <input type="date" name="to" defaultValue={to ?? r?.to} className={`mt-1 block ${field}`} />
        </label>
        <button className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">عرض</button>
      </form>

      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error.message}</p>}

      {r && (
        <>
          <div className="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-4">
            {kpis.map(([label, value]) => (
              <div key={String(label)} className="rounded-lg border bg-white p-4">
                <p className="text-xs text-gray-500">{label}</p>
                <p className="text-2xl font-bold text-brand">{value}</p>
              </div>
            ))}
          </div>

          <div className="grid gap-4 sm:grid-cols-3">
            <section className="rounded-lg border bg-white p-4">
              <h2 className="mb-2 text-sm font-semibold">الأجزاء المعتمدة</h2>
              {r.by_juz.length ? (
                <ul className="flex flex-col gap-1 text-sm">
                  {r.by_juz.map((j) => (
                    <li key={j.juz} className="flex justify-between">
                      <span>
                        جزء {j.juz} — {JUZ_NAMES[j.juz - 1]}
                      </span>
                      <b>{j.count}</b>
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="text-sm text-gray-400">—</p>
              )}
            </section>
            <section className="rounded-lg border bg-white p-4">
              <h2 className="mb-2 text-sm font-semibold">أكثر الأخطاء (معتمد)</h2>
              {r.by_error_type.length ? (
                <ul className="flex flex-col gap-1 text-sm">
                  {r.by_error_type.map((e) => (
                    <li key={e.name} className="flex justify-between">
                      <span>{e.name}</span>
                      <b>{e.total}</b>
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="text-sm text-gray-400">—</p>
              )}
            </section>
            <section className="rounded-lg border bg-white p-4">
              <h2 className="mb-2 text-sm font-semibold">المستمعون</h2>
              {r.by_examiner.length ? (
                <ul className="flex flex-col gap-1 text-sm">
                  {r.by_examiner.map((e) => (
                    <li key={e.name} className="flex justify-between">
                      <span>{e.name}</span>
                      <b>{e.count}</b>
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="text-sm text-gray-400">—</p>
              )}
            </section>
          </div>
        </>
      )}
    </div>
  );
}
