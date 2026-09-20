import { createClient } from '@/lib/supabase/server';
import { fmt } from '@/lib/platform/labels';

interface Row {
  at: string;
  source: 'platform' | 'center';
  action: string;
  target: string | null;
  detail: Record<string, unknown> | null;
  actor: string | null;
}

export default async function PlatformAuditPage() {
  const supabase = await createClient();
  const { data } = await supabase.rpc('platform_audit', { p_limit: 150 });
  const rows = (data ?? []) as Row[];
  return (
    <div className="max-w-5xl">
      <h1 className="mb-1 text-2xl font-bold">سجل العمليات</h1>
      <p className="mb-4 text-sm text-gray-500">عمليات مالك المنصة، وآخر عمليات كل المراكز.</p>
      <div className="overflow-x-auto rounded-lg border bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-right">
            <tr>
              {['الوقت', 'المصدر', 'العملية', 'الهدف', 'المنفّذ'].map((h) => (
                <th key={h} className="px-3 py-2">
                  {h}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((r, i) => (
              <tr key={i} className="border-t">
                <td className="px-3 py-1.5 text-xs text-gray-500">{fmt(r.at)}</td>
                <td className="px-3 py-1.5">
                  <span className={`rounded px-2 py-0.5 text-xs ${r.source === 'platform' ? 'bg-purple-50 text-purple-700' : 'bg-gray-100 text-gray-600'}`}>{r.source === 'platform' ? 'المنصة' : 'مركز'}</span>
                </td>
                <td className="px-3 py-1.5">{r.action}</td>
                <td className="px-3 py-1.5 text-xs text-gray-500" dir="ltr">
                  {r.target ?? ''}
                </td>
                <td className="px-3 py-1.5 text-xs">{r.actor ?? '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
