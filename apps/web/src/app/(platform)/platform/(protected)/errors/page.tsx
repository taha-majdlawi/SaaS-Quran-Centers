import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { resolveError, sendTestError } from '@/lib/platform/error-actions';

interface Group {
  fingerprint: string;
  source: 'web' | 'mobile' | 'server';
  message: string;
  screen: string | null;
  first_seen: string;
  last_seen: string;
  count: number;
  users: number;
  centers: number;
  last_24h: number;
  last_version: string | null;
  resolved_at: string | null;
}

interface Event {
  id: string;
  at: string;
  message: string;
  stack: string | null;
  screen: string | null;
  url: string | null;
  user: string | null;
  center: string | null;
  role: string | null;
  app_version: string | null;
  os: string | null;
  device: string | null;
  locale: string | null;
  breadcrumbs: string[];
  extra: Record<string, unknown>;
}

const SOURCE: Record<string, { label: string; cls: string }> = {
  web: { label: 'الموقع', cls: 'bg-blue-50 text-blue-700' },
  mobile: { label: 'التطبيق', cls: 'bg-green-50 text-green-700' },
  server: { label: 'الخادم', cls: 'bg-purple-50 text-purple-700' },
};

const when = (iso: string) => new Date(iso).toLocaleString('ar', { dateStyle: 'short', timeStyle: 'short' });

// Crashes from the website, the app and the server (0076), one row per bug.
export default async function PlatformErrorsPage({ searchParams }: { searchParams: Promise<{ status?: string; fp?: string; tested?: string; test_error?: string }> }) {
  const { status = 'open', fp, tested, test_error } = await searchParams;
  const supabase = await createClient();
  const [{ data, error }, { data: detail }] = await Promise.all([
    supabase.rpc('platform_error_groups', { p_status: status, p_days: 30 }),
    fp ? supabase.rpc('platform_error_detail', { p_fingerprint: fp }) : Promise.resolve({ data: null }),
  ]);
  const groups = (data ?? []) as Group[];
  const d = detail as { group: Group | null; events: Event[] } | null;

  return (
    <div className="max-w-6xl">
      <h1 className="mb-1 text-2xl font-bold">الأخطاء</h1>
      <p className="mb-4 text-sm text-gray-500">
        كل خطأ يحدث عند أي مستخدم في الموقع أو التطبيق أو الخادم، مجمّعًا حسب نوعه. يصلك إشعار على هاتفك عند ظهور خطأ جديد، أو عند عودة خطأ علّمته «مُصلَح».
      </p>
      <form action={sendTestError} className="mb-3 flex flex-wrap items-center gap-2 text-sm">
        <SubmitButton className="rounded border bg-white px-3 py-1.5 hover:bg-gray-50" pendingText="جارٍ الإرسال...">
          إرسال خطأ تجريبي
        </SubmitButton>
        <span className="text-xs text-gray-500">للتأكد أن المراقبة تعمل: يظهر في القائمة ويصلك إشعاره على هاتفك.</span>
        {tested && <span className="text-xs font-semibold text-green-700">أُرسل — تجده أعلى القائمة.</span>}
        {test_error && <span className="text-xs font-semibold text-red-700">لم يُرسل: {test_error}</span>}
      </form>
      <div className="mb-4 flex gap-2 text-sm">
        {[
          ['open', 'مفتوحة'],
          ['resolved', 'مُصلَحة'],
          ['all', 'الكل'],
        ].map(([k, label]) => (
          <a key={k} href={`/errors?status=${k}` as never} className={`rounded-full px-3 py-1 ${status === k ? 'bg-brand text-white' : 'bg-white border'}`}>
            {label}
          </a>
        ))}
      </div>
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error.message}</p>}

      <div className="grid gap-4 lg:grid-cols-5">
        <ul className="flex flex-col gap-2 lg:col-span-2">
          {groups.map((g) => (
            <li key={g.fingerprint}>
              <a
                href={`/errors?status=${status}&fp=${g.fingerprint}` as never}
                className={`block rounded-lg border bg-white p-3 text-sm hover:border-gray-400 ${fp === g.fingerprint ? 'border-gray-900 ring-1 ring-gray-900' : ''}`}
              >
                <div className="mb-1 flex flex-wrap items-center gap-2">
                  <span className={`rounded px-1.5 py-0.5 text-xs font-semibold ${SOURCE[g.source]?.cls}`}>{SOURCE[g.source]?.label}</span>
                  {g.resolved_at && <span className="rounded bg-gray-100 px-1.5 py-0.5 text-xs">مُصلَح</span>}
                  {g.last_24h > 0 && <span className="rounded bg-red-50 px-1.5 py-0.5 text-xs text-red-700">{g.last_24h} آخر 24 ساعة</span>}
                </div>
                <p className="line-clamp-2 font-mono text-xs" dir="ltr">{g.message}</p>
                <p className="mt-1 text-xs text-gray-500">
                  {g.count} مرة · {g.users} مستخدم · {g.centers} مركز · آخرها {when(g.last_seen)}
                  {g.screen ? ` · ${g.screen}` : ''}
                </p>
              </a>
            </li>
          ))}
          {!groups.length && <li className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا أخطاء 🎉</li>}
        </ul>

        <div className="lg:col-span-3">
          {d?.group ? (
            <section className="rounded-lg border bg-white p-4 text-sm">
              <div className="mb-3 flex flex-wrap items-start justify-between gap-2">
                <div>
                  <p className="font-mono text-sm font-semibold" dir="ltr">{d.group.message}</p>
                  <p className="mt-1 text-xs text-gray-500">
                    أول ظهور {when(d.group.first_seen)} · آخر ظهور {when(d.group.last_seen)} · {d.group.count} مرة · {d.group.users} مستخدم
                    {d.group.last_version ? ` · الإصدار ${d.group.last_version}` : ''}
                  </p>
                </div>
                <form action={resolveError}>
                  <input type="hidden" name="fingerprint" value={d.group.fingerprint} />
                  <input type="hidden" name="resolved" value={d.group.resolved_at ? '0' : '1'} />
                  <SubmitButton className="rounded bg-brand px-3 py-1.5 text-xs font-semibold text-white" pendingText="...">
                    {d.group.resolved_at ? 'إعادة فتح' : 'تعليم كمُصلَح'}
                  </SubmitButton>
                </form>
              </div>
              <h2 className="mb-2 font-semibold">آخر المرات ({d.events.length})</h2>
              <div className="flex flex-col gap-3">
                {d.events.map((e, i) => (
                  <details key={e.id} open={i === 0} className="rounded border p-3">
                    <summary className="cursor-pointer text-xs">
                      <b>{when(e.at)}</b> · {e.user ?? 'زائر'}
                      {e.center ? ` · ${e.center}` : ''}
                      {e.role ? ` (${e.role})` : ''} · {e.screen ?? '—'}
                    </summary>
                    <dl className="mt-2 grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 text-xs">
                      <dt className="text-gray-500">الجهاز</dt>
                      <dd dir="ltr" className="text-start">{[e.device, e.os].filter(Boolean).join(' · ') || '—'}</dd>
                      <dt className="text-gray-500">الإصدار</dt>
                      <dd dir="ltr" className="text-start">{e.app_version ?? '—'}</dd>
                      <dt className="text-gray-500">الرابط</dt>
                      <dd dir="ltr" className="break-all text-start">{e.url ?? '—'}</dd>
                      <dt className="text-gray-500">اللغة</dt>
                      <dd>{e.locale ?? '—'}</dd>
                    </dl>
                    {e.breadcrumbs.length > 0 && (
                      <>
                        <p className="mt-2 text-xs font-semibold">الخطوات قبل الخطأ</p>
                        <ol className="mt-1 list-decimal ps-5 font-mono text-[11px] text-gray-600" dir="ltr">
                          {e.breadcrumbs.map((b, j) => (
                            <li key={j}>{String(b).replace(/^"|"$/g, '')}</li>
                          ))}
                        </ol>
                      </>
                    )}
                    {e.stack && (
                      <pre className="mt-2 max-h-64 overflow-auto rounded bg-gray-50 p-2 text-[11px]" dir="ltr">
                        {e.stack}
                      </pre>
                    )}
                    {Object.keys(e.extra ?? {}).length > 0 && (
                      <pre className="mt-2 overflow-auto rounded bg-gray-50 p-2 text-[11px]" dir="ltr">
                        {JSON.stringify(e.extra, null, 2)}
                      </pre>
                    )}
                  </details>
                ))}
              </div>
            </section>
          ) : (
            <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">اختر خطأ لعرض تفاصيله.</p>
          )}
        </div>
      </div>
    </div>
  );
}
